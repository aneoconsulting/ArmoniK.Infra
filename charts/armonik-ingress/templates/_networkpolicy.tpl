{{- define "armonik.netpol.port" -}}
{{- $ports := .ports | default list -}}
{{- $name := .name -}}
{{- range $port := $ports -}}
  {{- if eq $port.name $name -}}
{{ $port.containerPort }}
  {{- end -}}
{{- end -}}
{{- end -}}


{{/*
  Ingress backend NetworkPolicy configuration.
*/}}
{{- define "armonik.netpol.ingressBackend" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: ingress

policyTypes:
  - Ingress
  - Egress

ingress:
  {{- include "armonik.netpol.rule.ingressHealthCheck" . | nindent 2 }}

  extraRules:
    {{- toYaml (.Values.networkPolicy.ingress.extraRules | default list) | nindent 4 }}

egress:
  {{- include "armonik.netpol.rule.ingressEgress" . | nindent 2 }}

  extraRules:
    {{- toYaml (.Values.networkPolicy.egress.extraRules | default list) | nindent 4 }}
{{- end -}}


{{/*
  Ingress GUI NetworkPolicy configuration.
*/}}
{{- define "armonik.netpol.ingressGui" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: ingress
    app.kubernetes.io/component: gui

policyTypes:
  - Ingress

ingress:
  rules:
    {{- include "armonik.netpol.rule.guiIngress" . | nindent 4 }}

  extraRules: []
{{- end -}}


{{/*
  Ingress health-check rules.

  Optional health-check sources come from:
    .Values.networkPolicy.healthCheck.from
    .Values.networkPolicy.healthCheck.ports

  The application ports 8080 and 9080 are currently kept as
  the ingress container health endpoints.
*/}}
{{- define "armonik.netpol.rule.ingressHealthCheck" -}}

{{- $healthCheckEnabled := .Values.networkPolicy.healthCheck.enabled | default false -}}

{{- $healthCheckPort := include "armonik.netpol.port" (dict
      "ports" .Values.ports
      "name" "health-check-port"
    ) | trim -}}

{{- $metricsPort := include "armonik.netpol.port" (dict
      "ports" .Values.ports
      "name" "metrics-port"
    ) | trim -}}

rules:

  {{- if $healthCheckEnabled }}
  - from:
      {{- toYaml .Values.networkPolicy.healthCheck.from | nindent 6 }}
    ports:
      {{- toYaml .Values.networkPolicy.healthCheck.ports | nindent 6 }}
  {{- end }}

  - from: []
    ports:
      - protocol: TCP
        port: {{ $healthCheckPort }}
      - protocol: TCP
        port: {{ $metricsPort }}

{{- end -}}


{{/*
  Ingress egress rules.

  Ingress -> DNS
  Ingress -> GUI
  Ingress -> Control-plane
  Ingress -> Grafana
  Ingress -> Seq
*/}}
{{- define "armonik.netpol.rule.ingressEgress" -}}

{{- $controlPort := include "armonik.netpol.port" (dict
      "ports" .Values.ports
      "name" "control-port"
    ) | trim | int -}}

{{- list
      (include "armonik.netpol.dnsRule" dict | fromYaml)
      | toYaml
      | nindent 2
}}

  - to:
      - podSelector:
          matchLabels:
            app.kubernetes.io/name: ingress
            app.kubernetes.io/component: gui
    ports:
      - protocol: TCP
        port: {{ $controlPort }}

  - to:
      - namespaceSelector: {}
        podSelector:
          matchLabels:
            app.kubernetes.io/name: control-plane
    ports:
      - protocol: TCP
        port: {{ $controlPort }}

  - to:
      - namespaceSelector: {}
        podSelector:
          matchLabels:
            app.kubernetes.io/name: grafana
    ports:
      - protocol: TCP
        port: 3000

  - to:
      - namespaceSelector: {}
        podSelector:
          matchLabels:
            app: seq
    ports:
      - protocol: TCP
        port: "ui"
{{- end -}}


{{/*
  GUI ingress rules.
*/}}
{{- define "armonik.netpol.rule.guiIngress" -}}

{{- $guiPort := include "armonik.netpol.port" (dict
      "ports" .Values.ports
      "name" "gui-port"
    ) | trim -}}

- from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: ingress
          app.kubernetes.io/component: ingress
  ports:
    - protocol: TCP
      port: {{ $guiPort }}

{{- end -}}
