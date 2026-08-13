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
  Submitter ingress rules.
  # TO FIX : namespaceSelector with secret namespaces
*/}}
{{- define "armonik.netpol.rule.submitterIngress" -}}

{{- $controlPort := include "armonik.netpol.port" (dict
      "ports" .Values.ports
      "name" "control-port"
    ) | trim | int -}}

{{- $metricsPort := include "armonik.netpol.port" (dict
      "ports" .Values.ports
      "name" "metrics-port"
    ) | trim | int -}}

rules:
  - from:
      - namespaceSelector: {} 
        podSelector:
          matchLabels:
            app.kubernetes.io/name: compute-plane
    ports:
      - protocol: TCP
        port: {{ $controlPort }}

  - from:
      - namespaceSelector: {}
        podSelector:
          matchLabels:
            app.kubernetes.io/name: ingress
    ports:
      - protocol: TCP
        port: {{ $controlPort }}

  - from:
      - namespaceSelector: {}
    ports:
      - protocol: TCP
        port: {{ $metricsPort }}
{{- end -}}


{{/*
  Submitter egress rules.
*/}}
{{- define "armonik.netpol.rule.submitterEgress" -}}
rules:
  {{- list
        (include "armonik.netpol.dnsRule" dict | fromYaml)
      | toYaml
      | nindent 2
  }}
{{- end -}}


{{/*
  Metrics-exporter ingress rules.
*/}}
{{- define "armonik.netpol.rule.metricsExporterIngress" -}}

{{- $metricsPort := include "armonik.netpol.port" (dict
      "ports" .Values.metricsExporter.ports
      "name" "metrics-port"
    ) | trim | int -}}

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
  {{- list
        (include "armonik.netpol.dnsRule" dict | fromYaml)
      | toYaml
      | nindent 2
  }}
{{- end -}}

{{- define "armonik.netpol.submitter" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: control-plane
policyTypes:
  - Ingress
  - Egress
ingress:
  {{- include "armonik.netpol.rule.submitterIngress" . | nindent 2 }}
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

