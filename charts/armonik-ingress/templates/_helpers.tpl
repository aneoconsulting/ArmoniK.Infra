{{/*
Calculate port based on protocol and TLS status
*/}}
{{- define "armonik.ingress.httpPort" -}}
{{- if and .Values.tls.enabled (not .Values.gateway.enabled) -}}8443{{- else -}}8080{{- end -}}
{{- end -}}

{{- define "armonik.ingress.grpcPort" -}}
{{- if and .Values.tls.enabled (not .Values.gateway.enabled) -}}9443{{- else -}}9080{{- end -}}
{{- end -}}

{{- define "armonik.ingress.mtlsCnPattern" -}}
  {{- $mtls := .mtls | default dict -}}
  {{- if $mtls.enabled -}}
    {{- if $mtls.trustedCommonNames -}}
      {{- $patterns := list -}}
      {{- range $mtls.trustedCommonNames -}}
        {{- $patterns = append $patterns (. | replace "." "\\.") -}}
      {{- end -}}
      {{- join "|" $patterns -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "armonik.ingress.serviceType" -}}
{{- if .Values.gateway.enabled -}}
ClusterIP
{{- else -}}
{{ .Values.service.type }}
{{- end -}}
{{- end -}}
