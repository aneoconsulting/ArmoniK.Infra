{{- define "control-plane.labels" -}}
app: {{ .Values.namespace | default "armonik" }}
service: {{ .Values.name | default "control-plane" }}
{{- end }}

{{- define "control-plane.selectorLabels" -}}
app: {{ .Values.namespace | default "armonik" }}
service: {{ .Values.name | default "control-plane" }}
{{- end }}

{{- define "control-plane.name" -}}
{{ .Values.name | default "control-plane" }}
{{- end }}
