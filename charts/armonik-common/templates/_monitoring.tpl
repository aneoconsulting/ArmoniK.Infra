{{/*
Paired per value: `<value>.default` derives the default, `<value>` resolves whatever the value holds,
tpl-rendering it since that default is a template string. Only values.yaml calls a `.default`, which must
therefore never read its own value, or tpl recurses.

  values.yaml   prometheusUrl: '{{ include "armonik.monitoring.prometheusUrl.default" . }}'
  template      {{- $url := include "armonik.monitoring.prometheusUrl" $ -}}
*/}}

{{/*
Resolves metricsExporterUrl. Its default reads chart-level conf.source, so this needs one of OUR charts.
*/}}
{{- define "armonik.monitoring.metricsExporterUrl" -}}
  {{- $raw := list .Values "global" "armonik" "monitoring" "metricsExporterUrl" | include "armonik.utils.index" -}}
  {{- $url := tpl $raw . -}}
  {{- if empty $url -}}
    {{- fail "global.armonik.monitoring.metricsExporterUrl resolved empty: set it, or check that this render context carries .Values.global (a fabricated one, like the partition merge, must pass the full .Values)." -}}
  {{- end -}}
  {{- $url -}}
{{- end -}}

{{/*
Control-plane metrics-exporter /metrics, KEDA's default scaling source:
http://<conf.source>-control-plane-metrics-exporter.<release-ns>.svc[.<clusterDomain>]:9419/metrics.
Reusing conf.source means a standalone plane pointed at the main release resolves its exporter unaided.
*/}}
{{- define "armonik.monitoring.metricsExporterUrl.default" -}}
  {{- $src := include "armonik.conf.source" . -}}
  {{- $domain := list .Values "global" "clusterDomain" | include "armonik.utils.index" -}}
  {{- $suffix := $domain | empty | ternary "" (printf ".%s" $domain) -}}
  {{- printf "http://%s-control-plane-metrics-exporter.%s.svc%s:9419/metrics" $src .Release.Namespace $suffix -}}
{{- end -}}

{{/*
Resolves prometheusUrl: the Grafana datasource, and a PromQL KEDA trigger's endpoint.
*/}}
{{- define "armonik.monitoring.prometheusUrl" -}}
  {{- $raw := list .Values "global" "armonik" "monitoring" "prometheusUrl" | include "armonik.utils.index" -}}
  {{- $url := tpl $raw . -}}
  {{- if empty $url -}}
    {{- fail "global.armonik.monitoring.prometheusUrl resolved empty: set it, or check that this render context carries .Values.global (a fabricated one, like the partition merge, must pass the full .Values)." -}}
  {{- end -}}
  {{- $url -}}
{{- end -}}

{{/*
Shared cluster Prometheus, http://prometheus-prometheus.<prometheusOperator ns>.svc[.<clusterDomain>]:9090;
the service name is fixed by the kps fullnameOverride in armonik-operators. An empty namespace fails rather
than emitting an unresolvable host. Override the value with a literal URL for a Prometheus we did not deploy.
*/}}
{{- define "armonik.monitoring.prometheusUrl.default" -}}
  {{- $ops := include "armonik.operators" . | fromYaml -}}
  {{- $ns := $ops.prometheusOperator.namespace -}}
  {{- if empty $ns -}}
    {{- fail "global.armonik.operators.prometheusOperator.namespace resolved empty: set it to the namespace of the release installing kube-prometheus-stack. It only defaults to this release's namespace when this release installs it." -}}
  {{- end -}}
  {{- $domain := list .Values "global" "clusterDomain" | include "armonik.utils.index" -}}
  {{- $suffix := $domain | empty | ternary "" (printf ".%s" $domain) -}}
  {{- printf "http://prometheus-prometheus.%s.svc%s:9090" $ns $suffix -}}
{{- end -}}

{{/*
searchNamespace for the Grafana dashboard sidecar: this release's namespace plus the monitoring one, where
kps renders its dashboard ConfigMaps, deduplicated. No resolver, the value being the grafana chart's own.
Reached through that chart's tpl of it, hence in the GRAFANA context: read only .Release and .Values.global.
*/}}
{{- define "armonik.monitoring.dashboardNamespaces.default" -}}
  {{- $ops := include "armonik.operators" . | fromYaml -}}
  {{- $ns := $ops.prometheusOperator.namespace -}}
  {{- if empty $ns -}}
    {{- fail "global.armonik.operators.prometheusOperator.namespace resolved empty: set it to the namespace of the release installing kube-prometheus-stack. It only defaults to this release's namespace when this release installs it." -}}
  {{- end -}}
  {{- list .Release.Namespace $ns | uniq | join "," -}}
{{- end -}}
