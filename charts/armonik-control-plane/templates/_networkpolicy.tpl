{{- define "armonik.netpol.port" -}}
{{- $ports := .ports | default list -}}
{{- $name := .name -}}
{{- range $port := $ports -}}
  {{- if eq $port.name $name -}}
    {{- $port.containerPort -}}
  {{- end -}}
{{- end -}}
{{- end -}}



{{/*
  Submitter egress rules.
*/}}
{{- define "armonik.netpol.rule.submitterEgress" -}}
rules:
  - {{- include "armonik.netpol.dnsRule" dict | nindent 4 }}
{{- end -}}


{{/*
  Metrics-exporter ingress rules.
*/}}
{{- define "armonik.netpol.rule.metricsExporterIngress" -}}

{{- $metricsPort := include "armonik.netpol.port" (dict
      "ports" .Values.metricsExporter.ports
      "name" "metrics-port"
    ) | int -}}

rules:
  - from:
      - namespaceSelector: {}
    ports:
      - protocol: TCP
        port: {{ $metricsPort }}

{{- end -}}


{{/*
  Metrics-exporter egress rules.
*/}}
{{- define "armonik.netpol.rule.metricsExporterEgress" -}}
rules:
  - {{- include "armonik.netpol.dnsRule" dict | nindent 4 }}
{{- end -}}

{{- define "armonik.netpol.submitter" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: control-plane
policyTypes:
  - Ingress
  - Egress
ingress:
  extraRules:
    {{- toYaml (.Values.networkPolicy.submitter.extraIngressRules | default list) | nindent 4 }}
egress:
  {{- include "armonik.netpol.rule.submitterEgress" . | nindent 2 }}
  extraRules:
    {{- toYaml (.Values.networkPolicy.submitter.extraEgressRules | default list) | nindent 4 }}
{{- end -}}


{{- define "armonik.netpol.metricsExporter" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/component: metrics-exporter
policyTypes:
  - Ingress
  - Egress
ingress:
  {{- include "armonik.netpol.rule.metricsExporterIngress" . | nindent 2 }}
  extraRules:
    {{- toYaml (.Values.networkPolicy.metricsExporter.extraIngressRules | default list) | nindent 4 }}
egress:
  {{- include "armonik.netpol.rule.metricsExporterEgress" . | nindent 2 }}
  extraRules:
    {{- toYaml (.Values.networkPolicy.metricsExporter.extraEgressRules | default list) | nindent 4 }}
{{- end -}}
