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

{{/*
identityHeaders as YAML: per key, the header name. Fails on a malformed or repeated name, and on
Authorization, which carries the tokens of ArmoniK Core's Token method. Takes .Values.
*/}}
{{- define "armonik.ingress.identityHeaders" -}}
  {{- $headers := .identityHeaders | default dict -}}
  {{- $out := dict -}}
  {{- $seen := dict -}}
  {{- range $key := list "certificate" "user" "groups" -}}
    {{- $name := index $headers $key | default "" | toString -}}
    {{- if not (regexMatch "^[A-Za-z0-9]+(-[A-Za-z0-9]+)*$" $name) -}}
      {{- printf "identityHeaders.%s must be a header name of letters, digits and dashes, got %q" $key $name | fail -}}
    {{- end -}}
    {{- $lower := lower $name -}}
    {{- if eq $lower "authorization" -}}
      {{- printf "identityHeaders.%s cannot be Authorization, which carries the tokens of ArmoniK Core's Token method" $key | fail -}}
    {{- end -}}
    {{- if hasKey $seen $lower -}}
      {{- printf "identityHeaders.%s repeats identityHeaders.%s (%q): header names are case-insensitive" $key (index $seen $lower) $name | fail -}}
    {{- end -}}
    {{- $_ := set $seen $lower $key -}}
    {{- $_ := set $out $key (dict "name" $name) -}}
  {{- end -}}
  {{- $out | toYaml -}}
{{- end -}}

{{/* ingress Service type: ClusterIP behind an HTTPRoute, else service.type. */}}
{{- define "armonik.ingress.serviceType" -}}
  {{- if .Values.httpRoute.enabled -}}
    ClusterIP
  {{- else -}}
    {{ .Values.service.type }}
  {{- end -}}
{{- end -}}
