{{/*
nginx container port for .protocol (http or grpc): 8443/9443 when nginx terminates TLS (tls.enabled
without a gateway), else 8080/9080.
*/}}
{{- define "armonik.ingress.containerPort" -}}
{{- if eq .protocol "http" }}
  {{- if and .root.Values.tls.enabled (not .root.Values.gateway.enabled) -}}
8443
  {{- else -}}
8080
  {{- end -}}
{{- else if eq .protocol "grpc" }}
  {{- if and .root.Values.tls.enabled (not .root.Values.gateway.enabled) -}}
9443
  {{- else -}}
9080
  {{- end -}}
{{- end -}}
{{- end -}}

{{/* ingress Service port for .protocol; the container port when the Service is headless. */}}
{{- define "armonik.httpRoute.port" -}}
{{- $protocol := .protocol -}}
{{- $root := .root -}}

{{- range $root.Values.ports }}
  {{- if eq .protocol $protocol }}
    {{- if eq $root.Values.service.type "HeadLess" }}
      {{- include "armonik.ingress.containerPort" (dict
        "protocol" .protocol
        "root" $root
      ) -}}
    {{- else }}
      {{- .servicePort -}}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Regex alternation of mtls.trustedCommonNames, dots escaped; empty unless mTLS is on. Takes .Values. */}}
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

{{/* ingress Service type: ClusterIP behind an HTTPRoute, else service.type. */}}
{{- define "armonik.ingress.serviceType" -}}
  {{- if .Values.httpRoute.enabled -}}
    ClusterIP
  {{- else -}}
    {{ .Values.service.type }}
  {{- end -}}
{{- end -}}
