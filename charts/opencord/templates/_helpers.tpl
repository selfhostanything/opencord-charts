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
Create the service account name.
*/}}
{{- define "opencord.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "opencord.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
