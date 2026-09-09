{{/*
  Ingress from Prometheus (the submitter's own /metrics), derived from
  global.armonik.monitoring.prometheusUrl (see armonik.netpol.rule.prometheusIngress in
  armonik-common). Ingress from nginx (grpc/http) needs .Subcharts visibility this chart doesn't
  have, so it stays umbrella-only (armonik.netpol.controlPlaneSubmitter).
*/}}
{{- define "armonik.netpol.submitter.prometheusIngress" -}}
{{- $port := include "armonik.netpol.port" (dict "ports" .Values.ports "name" "metrics-port") | int -}}
{{- list . $port .Values.networkPolicy.submitter.prometheusPodSelector | include "armonik.netpol.rule.prometheusIngress" -}}
{{- end -}}


{{- define "armonik.netpol.submitter" -}}
podSelector:
  matchLabels:
    {{- include "armonik.selectorLabels" $ | nindent 4 }}
ingress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (list (list "armonik.netpol.submitter.prometheusIngress" .) | include "armonik.netpol.mergeRules")
        "extra" .Values.networkPolicy.submitter.extraIngressRules
    ) | nindent 2 }}
egress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (list (include "armonik.netpol.dnsRule" dict | fromYaml) | toYaml)
        "extra" .Values.networkPolicy.submitter.extraEgressRules
    ) | nindent 2 }}
{{- end -}}


{{/*
  Ingress from Prometheus, derived from global.armonik.monitoring.prometheusUrl (see
  armonik.netpol.rule.prometheusIngress in armonik-common) - resolves the same whether installed
  standalone or through the umbrella. KEDA's own ingress needs .Subcharts visibility this chart
  doesn't have, so it stays umbrella-only (armonik.netpol.controlPlaneMetricsExporter).
*/}}
{{- define "armonik.netpol.metricsExporter.prometheusIngress" -}}
{{- $port := include "armonik.netpol.port" (dict "ports" .Values.metricsExporter.ports "name" "metrics-port") | int -}}
{{- list . $port .Values.networkPolicy.metricsExporter.prometheusPodSelector | include "armonik.netpol.rule.prometheusIngress" -}}
{{- end -}}


{{- define "armonik.netpol.metricsExporter" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/component: metrics-exporter
ingress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (list (list "armonik.netpol.metricsExporter.prometheusIngress" .) | include "armonik.netpol.mergeRules")
        "extra" .Values.networkPolicy.metricsExporter.extraIngressRules
    ) | nindent 2 }}
egress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (list (include "armonik.netpol.dnsRule" dict | fromYaml) | toYaml)
        "extra" .Values.networkPolicy.metricsExporter.extraEgressRules
    ) | nindent 2 }}
{{- end -}}
