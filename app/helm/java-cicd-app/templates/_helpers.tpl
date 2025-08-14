{{/*
Expand the name of the chart.
Usage: {{ include "java-app.name" . }}
*/}}
{{- define "java-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
Usage: {{ include "java-app.fullname" . }}
*/}}
{{- define "java-app.fullname" -}}
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
Common labels for all resources.
Usage: {{ include "java-app.labels" . | nindent 4 }}
*/}}
{{- define "java-app.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "java-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used in matchLabels.
Usage: {{ include "java-app.selectorLabels" . | nindent 4 }}
*/}}
{{- define "java-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "java-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Return the proper Docker image reference.
Usage: {{ include "java-app.image" . }}
*/}}
{{- define "java-app.image" -}}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) -}}
{{- end }}
