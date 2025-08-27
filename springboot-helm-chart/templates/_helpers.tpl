{{/* Define chart name */}}
{{- define "springboot-app.name" -}}
{{ .Chart.Name }}
{{- end -}}

{{/* Define full name for resources */}}
{{- define "springboot-app.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end -}}
