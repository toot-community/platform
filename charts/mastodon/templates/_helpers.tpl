{{/*
Expand the name of the chart.
*/}}
{{- define "mastodon.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mastodon.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mastodon.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mastodon.labels" -}}
helm.sh/chart: {{ include "mastodon.chart" . }}
{{ include "mastodon.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mastodon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mastodon.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mastodon.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mastodon.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Common environment variables for Mastodon containers
*/}}
{{- define "mastodon.commonEnv" -}}
- name: DB_USER
  valueFrom:
    secretKeyRef:
      key: {{ .Values.configuration.database.credentials.usernameKey }}
      name: {{ .Values.configuration.database.credentials.secretName }}
- name: DB_PASS
  valueFrom:
    secretKeyRef:
      key: {{ .Values.configuration.database.credentials.passwordKey }}
      name: {{ .Values.configuration.database.credentials.secretName }}
{{- if .Values.configuration.search.enabled }}
- name: ES_PASS
  valueFrom:
    secretKeyRef:
      key: {{ .Values.configuration.search.password.secretKeyRef.key }}
      name: {{ .Values.configuration.search.password.secretKeyRef.name }}
{{- end }}
{{- end }}

{{/*
Common envFrom configuration for Mastodon containers
*/}}
{{- define "mastodon.commonEnvFrom" -}}
- configMapRef:
    name: {{ include "mastodon.fullname" . }}-env
- secretRef:
    name: {{ include "mastodon.fullname" . }}-secrets-env
{{- end }}

{{/*
Common container configuration for Mastodon
*/}}
{{- define "mastodon.containerBase" -}}
image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
imagePullPolicy: {{ .Values.image.pullPolicy }}
envFrom:
  {{- include "mastodon.commonEnvFrom" . | nindent 2 }}
{{- end }}

{{/*
Common pod spec configuration
*/}}
{{- define "mastodon.podSpec" -}}
restartPolicy: {{ .restartPolicy | default "Never" }}
serviceAccountName: {{ include "mastodon.serviceAccountName" . }}
{{- with .Values.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
CronJob template helper
*/}}
{{- define "mastodon.cronJobTemplate" -}}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ include "mastodon.fullname" .root }}-{{ .name }}
  labels:
    {{- include "mastodon.labels" .root | nindent 4 }}
spec:
  concurrencyPolicy: {{ .concurrencyPolicy | default "Forbid" }}
  schedule: {{ .schedule | quote }}
  jobTemplate:
    spec:
      template:
        metadata:
          name: {{ include "mastodon.fullname" .root }}-{{ .name }}
          {{- with .root.Values.jobs.annotations }}
          annotations:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          labels:
            {{- include "mastodon.labels" .root | nindent 12 }}
        spec:
          {{- include "mastodon.podSpec" .root | nindent 10 }}
          containers:
            - name: {{ .name }}
              {{- include "mastodon.containerBase" .root | nindent 14 }}
              env:
                {{- include "mastodon.commonEnv" .root | nindent 16 }}
              command:
                {{- toYaml .command | nindent 16 }}
              {{- if .resources }}
              resources:
                {{- toYaml .resources | nindent 16 }}
              {{- end }}
{{- end }}

{{/*
DB Migration job template
*/}}
{{- define "mastodon.dbMigrationJobTemplate" -}}
template:
    metadata:
      name: {{ include "mastodon.fullname" . }}-db-migrate
      {{- with .Values.jobs.annotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- include "mastodon.podSpec" . | nindent 6 }}
      terminationGracePeriodSeconds: 30
      containers:
        - name: {{ include "mastodon.fullname" . }}-db-migrate
          {{- include "mastodon.containerBase" . | nindent 10 }}
          command:
            - bundle
            - exec
            - rake
            - db:migrate
          env:
            {{- include "mastodon.commonEnv" . | nindent 12 }}
            - name: DB_PORT
              value: {{ .Values.configuration.database.dbMigrations.port | quote }}
            - name: DB_NAME
              value: {{ .Values.configuration.database.dbMigrations.name }}
            - name: DB_HOST
              value: {{ .Values.configuration.database.dbMigrations.host }}
            {{- if eq .skipPostMigrations true }}
            - name: SKIP_POST_DEPLOYMENT_MIGRATIONS
              value: "true"
            {{- end }}
{{- end }}

