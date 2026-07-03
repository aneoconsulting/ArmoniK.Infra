{{/*
Calculate port based on protocol and TLS status
*/}}
{{- define "armonik.ingress.port" -}}
  {{- $tlsObj := .tls | default dict -}}
  {{- $isTlsEnabled := $tlsObj.enabled | default false -}}
  {{- if eq .protocol "http" -}}
    {{- if $isTlsEnabled -}}8443{{- else -}}8080{{- end -}}
  {{- else if eq .protocol "grpc" -}}
    {{- if $isTlsEnabled -}}9443{{- else -}}9080{{- end -}}
  {{- end -}}
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
