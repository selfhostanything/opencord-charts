{{/*
Expand the name of the chart.
*/}}
{{- define "opencord.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "opencord.fullname" -}}
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
Create chart name and version label.
*/}}
{{- define "opencord.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "opencord.labels" -}}
helm.sh/chart: {{ include "opencord.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Release selector labels.
*/}}
{{- define "opencord.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opencord.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component-specific resource name.
*/}}
{{- define "opencord.componentName" -}}
{{- printf "%s-%s" (include "opencord.fullname" .root) .component | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Component labels.
*/}}
{{- define "opencord.componentLabels" -}}
{{ include "opencord.labels" .root }}
{{ include "opencord.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Component selector labels.
*/}}
{{- define "opencord.componentSelectorLabels" -}}
{{ include "opencord.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Build an image reference from registry, repository, and tag.
*/}}
{{- define "opencord.image" -}}
{{- $registry := trimSuffix "/" .root.Values.image.registry -}}
{{- $tag := default .root.Chart.AppVersion .root.Values.image.tag -}}
{{- printf "%s/%s:%s" $registry .repository $tag -}}
{{- end }}

{{/*
Resolve the Kubernetes Secret that provides DATABASE_URL.
*/}}
{{- define "opencord.databaseSecretName" -}}
{{- if .Values.database.external.enabled -}}
{{- .Values.database.external.urlSecretName -}}
{{- else -}}
{{- printf "%s-database" (include "opencord.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{/*
Resolve the Kubernetes Secret that provides VALKEY_URL.
*/}}
{{- define "opencord.valkeySecretName" -}}
{{- if .Values.valkey.external.enabled -}}
{{- .Values.valkey.external.urlSecretName -}}
{{- else -}}
{{- printf "%s-valkey" (include "opencord.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{/*
Common config map env source.
*/}}
{{- define "opencord.configEnvFrom" -}}
envFrom:
  - configMapRef:
      name: {{ include "opencord.fullname" . }}-config
{{- end }}

{{/*
DATABASE_URL env entry.
*/}}
{{- define "opencord.databaseEnv" -}}
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "opencord.databaseSecretName" . | quote }}
      key: DATABASE_URL
{{- end }}

{{/*
VALKEY_URL env entry.
*/}}
{{- define "opencord.valkeyEnv" -}}
- name: VALKEY_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "opencord.valkeySecretName" . | quote }}
      key: VALKEY_URL
{{- end }}

{{/*
Object storage secret env entries.
*/}}
{{- define "opencord.objectStorageEnv" -}}
{{- if .Values.objectStorage.existingSecret }}
- name: S3_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.objectStorage.existingSecret | quote }}
      key: {{ .Values.objectStorage.accessKeyIdKey | quote }}
- name: S3_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.objectStorage.existingSecret | quote }}
      key: {{ .Values.objectStorage.secretAccessKeyKey | quote }}
{{- end }}
{{- end }}

{{/*
Application secret env entries.
*/}}
{{- define "opencord.appSecretEnv" -}}
{{- if .Values.appSecrets.existingSecret }}
- name: SESSION_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.appSecrets.existingSecret | quote }}
      key: {{ .Values.appSecrets.sessionSecretKey | quote }}
      optional: true
- name: SMTP_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.appSecrets.existingSecret | quote }}
      key: {{ .Values.appSecrets.smtpUrlKey | quote }}
      optional: true
{{- end }}
{{- end }}

{{/*
LiveKit secret env entries.
*/}}
{{- define "opencord.livekitEnv" -}}
{{- if and .Values.livekit.enabled .Values.livekit.existingSecret }}
- name: LIVEKIT_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.livekit.existingSecret | quote }}
      key: {{ .Values.livekit.apiKeyKey | quote }}
- name: LIVEKIT_API_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.livekit.existingSecret | quote }}
      key: {{ .Values.livekit.apiSecretKey | quote }}
{{- end }}
{{- end }}

{{/*
TURN secret env entries.
*/}}
{{- define "opencord.turnEnv" -}}
{{- if and .Values.turn.enabled .Values.turn.existingSecret }}
- name: TURN_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.turn.existingSecret | quote }}
      key: {{ .Values.turn.usernameKey | quote }}
      optional: true
- name: TURN_CREDENTIAL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.turn.existingSecret | quote }}
      key: {{ .Values.turn.credentialKey | quote }}
      optional: true
- name: TURN_SHARED_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.turn.existingSecret | quote }}
      key: {{ .Values.turn.sharedSecretKey | quote }}
      optional: true
{{- end }}
{{- end }}

{{/*
Create the service account name.
*/}}
{{- define "opencord.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "opencord.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
