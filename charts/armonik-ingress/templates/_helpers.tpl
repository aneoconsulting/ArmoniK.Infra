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

{{/* Regex alternation of mtls.trustedCommonNames, each quoted as a literal; empty unless mTLS is on. Takes .Values. */}}
{{- define "armonik.ingress.mtlsCnPattern" -}}
  {{- $mtls := .mtls | default dict -}}
  {{- if $mtls.enabled -}}
    {{- if $mtls.trustedCommonNames -}}
      {{- $patterns := list -}}
      {{- range $mtls.trustedCommonNames -}}
        {{- $patterns = append $patterns (regexQuoteMeta .) -}}
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

{{/* "true" in nginx mode, empty in gateway mode; fails on any other mode. */}}
{{- define "armonik.ingress.nginx" -}}
  {{- $mode := .Values.mode | default "nginx" -}}
  {{- if not (has $mode (list "nginx" "gateway")) -}}
    {{- printf "mode must be nginx or gateway, got %q" $mode | fail -}}
  {{- end -}}
  {{- eq $mode "nginx" | ternary "true" "" -}}
{{- end -}}

{{/* Name of the Gateway this chart renders. */}}
{{- define "armonik.ingress.gateway.name" -}}
  {{- .Values.gateway.name | default (include "armonik.fullname" .) -}}
{{- end -}}

{{/*
gateway mode: parentRefs of every route, the chart's Gateway or httpRoute.parentRefs. No sectionName
on the chart's Gateway: a route attaches to all its listeners. Also called by the umbrella with this
chart's scope (.Subcharts.ingress).
*/}}
{{- define "armonik.ingress.parentRefs" -}}
{{- if .Values.gateway.enabled }}
- name: {{ include "armonik.ingress.gateway.name" . | quote }}
  namespace: {{ include "armonik.namespace" . | quote }}
{{- else }}
  {{- $refs := list .Values "httpRoute" "parentRefs" | include "armonik.utils.index" | fromYamlArray -}}
  {{- if not $refs -}}
    {{- fail "mode=gateway requires gateway.enabled=true or httpRoute.parentRefs naming an existing Gateway" -}}
  {{- end -}}
  {{- range $refs }}
- name: {{ required "httpRoute.parentRefs[].name is required" .name | quote }}
  namespace: {{ .namespace | default (include "armonik.namespace" $) | quote }}
    {{- with .sectionName }}
  sectionName: {{ . | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
gateway mode: networkPolicy.gatewayPeers as a "from" list. Fails when empty: the backends would
admit nothing.
*/}}
{{- define "armonik.ingress.gatewayPeers" -}}
  {{- $peers := list .Values "networkPolicy" "gatewayPeers" | include "armonik.utils.index" | fromYamlArray -}}
  {{- if not $peers -}}
    {{- fail "mode=gateway with NetworkPolicies requires ingress networkPolicy.gatewayPeers: the Gateway's data plane, as NetworkPolicy peers (see values.yaml)" -}}
  {{- end -}}
  {{- toYaml $peers -}}
{{- end -}}
