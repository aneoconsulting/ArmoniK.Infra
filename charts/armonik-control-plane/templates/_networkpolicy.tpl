{{/*
  Prometheus ingress on the submitter metrics port. The source namespace resolves in
  armonik.netpol.rule.prometheusIngress (armonik-common). Ingress from nginx needs .Subcharts, so it
  is umbrella-only (armonik.netpol.controlPlaneSubmitter).
*/}}
{{- define "armonik.netpol.submitter.prometheusIngress" -}}
  {{- $port := include "armonik.netpol.port" (dict "ports" .Values.ports "name" "metrics-port") | int -}}
  {{- list . $port .Values.networkPolicy.submitter.prometheusPodSelector | include "armonik.netpol.rule.prometheusIngress" -}}
{{- end -}}


{{/*
  Submitter NetworkPolicy spec: Prometheus ingress, DNS egress, plus the extra*Rules. Its selector
  matches every pod of the release, the metrics-exporter and init Job included.
*/}}
{{- define "armonik.netpol.submitter" -}}
podSelector:
  matchLabels:
    {{- include "armonik.selectorLabels" $ | nindent 4 }}
ingress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (dict "armonik.netpol.submitter.prometheusIngress" . | include "armonik.netpol.mergeRules")
        "extra" .Values.networkPolicy.submitter.extraIngressRules
    ) | nindent 2 }}
egress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (list (include "armonik.netpol.dnsRule" dict | fromYaml) | toYaml)
        "extra" .Values.networkPolicy.submitter.extraEgressRules
    ) | nindent 2 }}
{{- end -}}


{{/*
  Prometheus ingress on the metrics-exporter port, resolved as above. Ingress from KEDA needs
  .Subcharts, so it is umbrella-only (armonik.netpol.controlPlaneMetricsExporter).
*/}}
{{- define "armonik.netpol.metricsExporter.prometheusIngress" -}}
  {{- $port := include "armonik.netpol.port" (dict "ports" .Values.metricsExporter.ports "name" "metrics-port") | int -}}
  {{- list . $port .Values.networkPolicy.metricsExporter.prometheusPodSelector | include "armonik.netpol.rule.prometheusIngress" -}}
{{- end -}}


{{/* Metrics-exporter NetworkPolicy spec: Prometheus ingress, DNS egress, plus the extra*Rules. */}}
{{- define "armonik.netpol.metricsExporter" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/component: metrics-exporter
ingress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (dict "armonik.netpol.metricsExporter.prometheusIngress" . | include "armonik.netpol.mergeRules")
        "extra" .Values.networkPolicy.metricsExporter.extraIngressRules
    ) | nindent 2 }}
egress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (list (include "armonik.netpol.dnsRule" dict | fromYaml) | toYaml)
        "extra" .Values.networkPolicy.metricsExporter.extraEgressRules
    ) | nindent 2 }}
{{- end -}}
