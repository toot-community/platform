#!/usr/bin/env bash
set -euo pipefail

# Upgrades Talos nodes sequentially while waiting for node and Longhorn health.
# Usage:
#   TARGET_VERSION=<talosVersion> ./upgrade-talos.sh [--yes] [--even-if-newer] node1 node2
#   ./upgrade-talos.sh [--yes] [--even-if-newer] <talosVersion> node1 node2
# Environment:
#   TARGET_VERSION (optional if passed as first arg)
#   NODES                 space/comma separated list if not passed as args
#   FACTORY_BASE          base URL for talos factory (default: https://factory.talos.dev)
#   UPGRADE_TIMEOUT       timeout for talosctl upgrade (default: 30m)
#   NODE_READY_TIMEOUT_SECONDS  timeout waiting for node ready/version (default: 3600)
#   LONGHORN_TIMEOUT_SECONDS    timeout waiting for Longhorn volumes (default: 3600)
#   CHECK_INTERVAL_SECONDS      poll interval (default: 10)

UPGRADE_TIMEOUT="${UPGRADE_TIMEOUT:-30m}"
NODE_READY_TIMEOUT_SECONDS="${NODE_READY_TIMEOUT_SECONDS:-3600}"
LONGHORN_TIMEOUT_SECONDS="${LONGHORN_TIMEOUT_SECONDS:-3600}"
CHECK_INTERVAL_SECONDS="${CHECK_INTERVAL_SECONDS:-10}"
FACTORY_BASE="${FACTORY_BASE:-https://factory.talos.dev}"

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date +%H:%M:%S)" "${level}" "$*"
}

fatal() {
  log "ERROR" "$@"
  exit 1
}

usage() {
  cat <<'USAGE'
Upgrade Talos nodes sequentially.

Examples:
  TARGET_VERSION=v1.6.4 ./upgrade-talos.sh node1 node2
  ./upgrade-talos.sh v1.6.4 node1 node2
  ./upgrade-talos.sh --yes v1.6.4

Environment:
  TARGET_VERSION                  target Talos version (fallback to first argument)
  NODES                           space/comma separated node names (fallback to args)
  FACTORY_BASE                    base URL for talos factory (default: https://factory.talos.dev)
  UPGRADE_TIMEOUT                 timeout passed to talosctl upgrade (default: 30m)
  NODE_READY_TIMEOUT_SECONDS      timeout waiting for kube Ready + version (default: 3600)
  LONGHORN_TIMEOUT_SECONDS        timeout waiting for Longhorn health (default: 3600)
  CHECK_INTERVAL_SECONDS          polling interval (default: 10)

Flags:
  --yes                perform the upgrade (default is dry-run)
  --even-if-newer      do not skip nodes already on same/newer version
  -h, --help           show this help
USAGE
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fatal "Missing required command: $1"
}

# Resolve arguments and inputs
DRY_RUN=true
EVEN_IF_NEWER=false

POSITIONAL=()
while (($# > 0)); do
  case "$1" in
    --yes)
      DRY_RUN=false
      shift
      ;;
    --even-if-newer)
      EVEN_IF_NEWER=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      fatal "Unknown flag: $1"
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]}" "$@"

TARGET_VERSION="${TARGET_VERSION:-}"
if [[ -z "${TARGET_VERSION}" ]]; then
  if (($# == 0)); then
    usage
    fatal "TARGET_VERSION is required (env or first argument)"
  fi
  TARGET_VERSION="$1"
  shift
fi

if (($# > 0)); then
  NODE_NAMES=("$@")
elif [[ -n "${NODES:-}" ]]; then
  IFS=', ' read -r -a NODE_NAMES <<<"${NODES//,/ }"
else
  NODE_NAMES=()
fi

TARGET_VERSION_NUM="${TARGET_VERSION#v}"

discover_nodes() {
  mapfile -t NODE_NAMES < <(kubectl get nodes -o json | jq -r '.items[].metadata.name' 2>/dev/null)
  if ((${#NODE_NAMES[@]} == 0)); then
    fatal "No nodes found via kubectl; provide node names or set NODES"
  fi
  log "INFO" "Discovered nodes from Kubernetes: ${NODE_NAMES[*]}"
}

require_cmd kubectl
require_cmd talosctl
require_cmd jq
require_cmd yq

factory_host="${FACTORY_BASE#*://}"
factory_host="${factory_host%/}"
if [[ -z "${factory_host}" ]]; then
  factory_host="factory.talos.dev"
fi

wait_for_condition() {
  local description="$1"
  local timeout_secs="$2"
  local interval_secs="$3"
  shift 3

  if (($# == 0)); then
    fatal "wait_for_condition: missing command for '${description}'"
  fi

  local cmd=("$@")
  local start end output
  start=$(date +%s)
  while true; do
    if output=$("${cmd[@]}" 2>&1); then
      [[ -n "${output}" ]] && log "INFO" "${output}"
      return 0
    fi
    end=$(date +%s)
    if (( end - start >= timeout_secs )); then
      log "ERROR" "Timed out waiting for ${description} after ${timeout_secs}s"
      [[ -n "${output:-}" ]] && log "ERROR" "${output}"
      return 1
    fi
    [[ -n "${output:-}" ]] && log "WARN" "${output}"
    log "INFO" "Waiting for ${description} (sleep ${interval_secs}s)"
    sleep "${interval_secs}"
  done
}

extract_node_ip() {
  jq -r '
    (.status.addresses // []) as $addrs
    | if ($addrs | type) == "array" then
        (
          $addrs
          | map(select(type=="object") | select(.type=="InternalIP") | .address)
          | first
        )
        // (
          $addrs
          | map(select(type=="object") | select(.type=="ExternalIP") | .address)
          | first
        )
      elif ($addrs | type) == "object" then
        $addrs.InternalIP // $addrs.ExternalIP
      else
        ""
      end
      // ""
  ' <<<"$1"
}

extract_schematic_id() {
  jq -r '
    .metadata.annotations["extensions.talos.dev/schematic"]
    // .metadata.labels["extensions.talos.dev/schematic"]
    // ""
  ' <<<"$1"
}

talos_api_ready() {
  local node_ip="$1"
  talosctl -n "${node_ip}" version >/dev/null
}

extract_version_number() {
  local raw="$1"
  local ver
  ver=$(grep -oE 'v?[0-9]+(\.[0-9]+){1,3}' <<<"${raw}" | head -n1 || true)
  echo "${ver#v}"
}

version_ge() {
  local a="$1" b="$2"
  [[ -z "${a}" || -z "${b}" ]] && return 1
  local max
  max=$(printf '%s\n%s\n' "${a}" "${b}" | sort -V | tail -n1)
  [[ "${max}" == "${a}" ]]
}

resolve_installer_image() {
  local node_ip="$1"
  local schematic_id="$2"

  local mc_image base_image
  mc_image=""
  # The machineconfig spec is a double-encoded JSON string - use fromjson to decode it properly
  # The config may contain multiple YAML documents; use yq ea to select the one with machine.install.image
  mc_image=$(talosctl -n "${node_ip}" get machineconfig -o json 2>/dev/null \
    | jq -r '.spec | fromjson' 2>/dev/null \
    | yq ea 'select(.machine.install.image) | .machine.install.image' 2>/dev/null \
    || true)

  if [[ -n "${mc_image}" ]]; then
    base_image="${mc_image%%:*}"
    log "INFO" "Installer image base from machineconfig: ${base_image}" >&2
    echo "${base_image}:${TARGET_VERSION}"
    return 0
  fi

  log "ERROR" "Unable to determine installer image from machineconfig for ${node_ip}" >&2
  log "ERROR" "Cannot proceed without a valid installer image. Ensure the node's machineconfig contains machine.install.image" >&2
  return 1
}

node_ready_and_version() {
  local node_name="$1"
  local target_version="$2"
  local node_json
  if ! node_json=$(kubectl get node "${node_name}" -o json 2>/dev/null); then
    return 1
  fi
  local ready os_image
  ready=$(jq -r '[.status.conditions[]? | select(.type=="Ready").status][0] // ""' <<<"${node_json}")
  os_image=$(jq -r '.status.nodeInfo.osImage // ""' <<<"${node_json}")
  if [[ "${ready}" == "True" && "${os_image}" == *"${target_version}"* ]]; then
    return 0
  fi
  return 1
}

longhorn_volumes_healthy() {
  local vols_json
  if ! vols_json=$(kubectl -n longhorn-system get volumes.longhorn.io -o json 2>/dev/null); then
    echo "Unable to query Longhorn volumes" >&2
    return 1
  fi
  local unhealthy
  unhealthy=$(jq -r '.items[]? |
    {name: .metadata.name, robustness: (.status.robustness // ""), state: (.status.state // "")} |
    select((.robustness|ascii_downcase) != "healthy") |
    "\(.name): robustness=\(.robustness), state=\(.state)"' <<<"${vols_json}")
  if [[ -n "${unhealthy}" ]]; then
    echo "Longhorn volumes not healthy:"
    echo "${unhealthy}"
    return 1
  fi
  return 0
}

upgrade_node() {
  local node_name="$1"

  log "INFO" "Starting upgrade for ${node_name}"

  local node_json
  if ! node_json=$(kubectl get node "${node_name}" -o json 2>/dev/null); then
    fatal "Unable to fetch node ${node_name} from Kubernetes"
  fi

  local node_ip schematic_id
  node_ip=$(extract_node_ip "${node_json}") || fatal "Failed to extract IP for ${node_name}"
  if [[ -z "${node_ip}" ]]; then
    fatal "No IP found for node ${node_name}"
  fi

  schematic_id=$(extract_schematic_id "${node_json}") || fatal "Failed to extract schematic id for ${node_name}"
  if [[ -z "${schematic_id}" ]]; then
    fatal "No schematic id found for node ${node_name}"
  fi

  local factory_url installer_image
  factory_url="${FACTORY_BASE%/}/schematics/${schematic_id}"
  if ! installer_image=$(resolve_installer_image "${node_ip}" "${schematic_id}"); then
    fatal "Failed to resolve installer image for ${node_name}"
  fi

  local current_version
  current_version=$(extract_version_number "$(jq -r '.status.nodeInfo.osImage // ""' <<<"${node_json}")")
  if [[ -n "${current_version}" && "${EVEN_IF_NEWER}" != "true" ]] && version_ge "${current_version}" "${TARGET_VERSION_NUM}"; then
    log "INFO" "Skipping ${node_name}: current version ${current_version} >= target ${TARGET_VERSION_NUM} (use --even-if-newer to force)"
    return 0
  fi

  log "INFO" "Node ${node_name} IP: ${node_ip}"
  log "INFO" "Schematic ID: ${schematic_id}"
  log "INFO" "Factory URL: ${factory_url}"
  log "INFO" "Installer image: ${installer_image}"

  log "INFO" "Running talosctl upgrade on ${node_name}"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "INFO" "[dry-run] talosctl -n ${node_ip} upgrade --image ${installer_image} --wait --timeout ${UPGRADE_TIMEOUT}"
  else
    talosctl -n "${node_ip}" upgrade --image "${installer_image}" --wait --timeout "${UPGRADE_TIMEOUT}"
  fi

  log "INFO" "Waiting for Talos API on ${node_name}"
  wait_for_condition "Talos API for ${node_name}" "${NODE_READY_TIMEOUT_SECONDS}" "${CHECK_INTERVAL_SECONDS}" talos_api_ready "${node_ip}"

  log "INFO" "Waiting for Kubernetes Ready and version ${TARGET_VERSION} on ${node_name}"
  wait_for_condition "Kubernetes Ready + version on ${node_name}" "${NODE_READY_TIMEOUT_SECONDS}" "${CHECK_INTERVAL_SECONDS}" node_ready_and_version "${node_name}" "${TARGET_VERSION}"

  log "INFO" "Waiting for Longhorn volumes to be healthy before proceeding"
  wait_for_condition "Longhorn volumes healthy" "${LONGHORN_TIMEOUT_SECONDS}" "${CHECK_INTERVAL_SECONDS}" longhorn_volumes_healthy

  log "INFO" "Completed upgrade for ${node_name}"
}

if ((${#NODE_NAMES[@]} == 0)); then
  discover_nodes
fi

log "INFO" "Target version: ${TARGET_VERSION}"
log "INFO" "Mode: $([[ "${DRY_RUN}" == "true" ]] && echo "dry-run" || echo "apply")"
log "INFO" "Nodes: ${NODE_NAMES[*]}"

for node in "${NODE_NAMES[@]}"; do
  upgrade_node "${node}"
done

log "INFO" "All nodes upgraded successfully"
