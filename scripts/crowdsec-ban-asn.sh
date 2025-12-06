#!/usr/bin/env bash
set -euo pipefail

# Adds all IP ranges from given ASNs as CrowdSec decisions.
# Usage:
#   ./crowdsec-ban-asn.sh AS12345 AS67890
#   REASON="suspicious datacenter" DURATION="720h" ./crowdsec-ban-asn.sh AS12345
#
# Environment:
#   REASON      decision reason (default: "manual ASN ban")
#   DURATION    decision duration (default: "720h" = 30 days)
#   NAMESPACE   CrowdSec namespace (default: "crowdsec")
#   TYPE        decision type (default: "ban")
#   DRY_RUN     set to "true" to only print ranges without adding

REASON="${REASON:-manual ASN ban}"
DURATION="${DURATION:-720h}"
NAMESPACE="${NAMESPACE:-crowdsec}"
TYPE="${TYPE:-ban}"
DRY_RUN="${DRY_RUN:-false}"

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date +%H:%M:%S)" "${level}" "$*" >&2
}

fatal() {
  log "ERROR" "$@"
  exit 1
}

usage() {
  cat <<'USAGE'
Add IP ranges from ASNs as CrowdSec decisions.

Usage:
  ./crowdsec-ban-asn.sh [options] AS12345 [AS67890 ...]

Options:
  -r, --reason REASON     Decision reason (default: "manual ASN ban")
  -d, --duration DURATION Decision duration (default: "720h")
  -t, --type TYPE         Decision type: ban, captcha, throttle (default: "ban")
  -n, --namespace NS      CrowdSec namespace (default: "crowdsec")
  --dry-run               Print ranges without adding to CrowdSec
  -h, --help              Show this help

Environment variables:
  REASON, DURATION, NAMESPACE, TYPE, DRY_RUN
USAGE
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fatal "Missing required command: $1"
}

# Parse arguments
ASNS=()
while (($# > 0)); do
  case "$1" in
    -r|--reason)
      REASON="$2"
      shift 2
      ;;
    -d|--duration)
      DURATION="$2"
      shift 2
      ;;
    -t|--type)
      TYPE="$2"
      shift 2
      ;;
    -n|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      fatal "Unknown option: $1"
      ;;
    *)
      ASNS+=("$1")
      shift
      ;;
  esac
done

if ((${#ASNS[@]} == 0)); then
  usage
  fatal "At least one ASN is required"
fi

require_cmd whois
require_cmd kubectl

# Fetch IP ranges for all ASNs
fetch_ranges() {
  for asn in "${ASNS[@]}"; do
    # Normalize: ensure AS prefix
    local normalized="${asn^^}"
    [[ "${normalized}" =~ ^AS ]] || normalized="AS${normalized}"

    log "INFO" "Fetching ranges for ${normalized}"
    whois -h whois.radb.net -- "-i origin ${normalized}" 2>/dev/null \
      | grep -E '^route6?:' \
      | awk '{print $2}' \
      || log "WARN" "No ranges found for ${normalized}"
  done
}

# Get ranges
RANGES=$(fetch_ranges | sort -u)
RANGE_COUNT=$(echo "${RANGES}" | grep -c . || echo 0)

if ((RANGE_COUNT == 0)); then
  fatal "No IP ranges found for specified ASNs"
fi

log "INFO" "Found ${RANGE_COUNT} unique ranges for ASNs: ${ASNS[*]}"

if [[ "${DRY_RUN}" == "true" ]]; then
  log "INFO" "[dry-run] Would add the following ranges:"
  echo "${RANGES}"
  exit 0
fi

# Find a LAPI pod
LAPI_POD=$(kubectl -n "${NAMESPACE}" get pods -l k8s-app=crowdsec,type=lapi \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null) \
  || fatal "Failed to find CrowdSec LAPI pod in namespace ${NAMESPACE}"

if [[ -z "${LAPI_POD}" ]]; then
  fatal "No CrowdSec LAPI pod found in namespace ${NAMESPACE}"
fi

log "INFO" "Using LAPI pod: ${LAPI_POD}"
log "INFO" "Importing ${RANGE_COUNT} decisions (type=${TYPE}, duration=${DURATION}, scope=range)"

# Stream ranges to cscli decisions import
echo "${RANGES}" | kubectl -n "${NAMESPACE}" exec -i "${LAPI_POD}" -- \
  cscli decisions import -i - --format values --scope range \
    --type "${TYPE}" --duration "${DURATION}" --reason "${REASON}"

log "INFO" "Successfully imported ${RANGE_COUNT} decisions"
