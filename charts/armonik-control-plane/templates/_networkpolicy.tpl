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


{{/*
  Egress to the Prometheus the pod-deletion-cost controller queries: podDeletionCost.prometheusUrl,
  else global.armonik.monitoring.prometheusUrl (the pdc layer's default), else the Prometheus
  operator's namespace on 9090. The port is the URL's (80 or 443 when it names none),
  kube-prometheus-stack serving Prometheus on its Service port. No rule for an out-of-cluster URL,
  which extraEgressRules covers.
*/}}
{{- define "armonik.netpol.podDeletionCost.prometheusEgress" -}}
  {{- $ops := include "armonik.operators" . | fromYaml -}}
  {{- $raw := coalesce .Values.podDeletionCost.prometheusUrl (list .Values "global" "armonik" "monitoring" "prometheusUrl" | include "armonik.utils.index") -}}
  {{- $url := tpl ($raw | default "") . -}}
  {{- $ns := "" -}}
  {{- $port := 9090 -}}
  {{- if $url -}}
    {{- $ns = include "armonik.netpol.namespaceFromServiceUrl" $url -}}
    {{- $schemePort := hasPrefix "https://" $url | ternary "443" "80" -}}
    {{- $port = regexReplaceAll "^([a-z]+://)?[^/:]+(:([0-9]+))?.*$" $url "${3}" | default $schemePort | int -}}
  {{- else if $ops.prometheusOperator.available -}}
    {{- $ns = $ops.prometheusOperator.namespace -}}
  {{- end -}}
  {{- $podSelector := list .Values "networkPolicy" "podDeletionCost" "prometheusPodSelector" | include "armonik.utils.index" | fromYaml -}}
  {{- if $ns }}
to:
  - namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: {{ $ns | quote }}
    podSelector:
      {{- list $podSelector "prometheus" | include "armonik.netpol.podSelector.default" | nindent 6 }}
ports:
  - protocol: TCP
    port: {{ $port }}
  {{- end -}}
{{- end -}}


{{/*
  Pod-deletion-cost controller NetworkPolicy spec: egress to Prometheus, which ranks the busy
  compute-plane pods, to the Kubernetes API, through which it annotates them, and to DNS, plus the
  extraEgressRules. The submitter policy selects this pod too and only grants DNS.
*/}}
{{- define "armonik.netpol.podDeletionCost" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/component: pod-deletion-cost
    {{- include "armonik.selectorLabels" $ | nindent 4 }}
egress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (dict
            "armonik.netpol.podDeletionCost.prometheusEgress" .
            "armonik.netpol.kubeApiRule" dict
            "armonik.netpol.dnsRule" dict
          | include "armonik.netpol.mergeRules")
        "extra" .Values.networkPolicy.podDeletionCost.extraEgressRules
    ) | nindent 2 }}
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
