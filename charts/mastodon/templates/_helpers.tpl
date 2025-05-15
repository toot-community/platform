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
Create the name of the service account to use
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
      restartPolicy: Never
      containers:
        - name: {{ include "mastodon.fullname" . }}-db-migrate
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          command:
            - bundle
            - exec
            - rake
            - db:migrate
          env:
            - name: DB_PORT
              value: {{ .Values.configuration.database.dbMigrations.port | quote }}
            - name: DB_NAME
              value: {{ .Values.configuration.database.dbMigrations.name }}
            - name: DB_HOST
              value: {{ .Values.configuration.database.dbMigrations.host }}
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
            {{- if eq .skipPostMigrations true }}
            - name: SKIP_POST_DEPLOYMENT_MIGRATIONS
              value: "true"
            {{- end }}
          envFrom:
            - configMapRef:
                name: {{ include "mastodon.fullname" . }}-env
            - secretRef:
                name: {{ include "mastodon.fullname" . }}-secrets-env
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      serviceAccountName: {{ include "mastodon.serviceAccountName" . }}
      terminationGracePeriodSeconds: 30
{{- end }}

