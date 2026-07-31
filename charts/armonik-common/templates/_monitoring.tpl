{{/*
Derivations for global.armonik.monitoring.*: each is that value's default, shipped as a template
string by every root chart and tpl-rendered by the consumer, so an override just replaces it.
A derivation must therefore never read the value it defaults (tpl would recurse).

  values.yaml   metricsExporterUrl: '{{ include "armonik.monitoring.metricsExporterUrl" . }}'
  template      {{- $url := tpl (list $.Values "global" "armonik" "monitoring" "metricsExporterUrl" | include "armonik.utils.index") $ -}}
*/}}

{{/*
Control-plane metrics-exporter /metrics, scraped directly by KEDA (default scaling path):
http://<conf.source>-control-plane-metrics-exporter.<release-ns>.svc[.<clusterDomain>]:9419/metrics.

conf.source is the same indirection as the conf Secret names, so a standalone compute-plane that
already points it at the main release resolves that release's exporter unaided. Reading a chart-level
value (conf.source) makes this the one helper here that needs one of OUR charts as context.
*/}}
{{- define "armonik.monitoring.metricsExporterUrl" -}}
  {{- $src := include "armonik.conf.source" . -}}
  {{- $domain := list .Values "global" "clusterDomain" | include "armonik.utils.index" -}}
  {{- $suffix := $domain | empty | ternary "" (printf ".%s" $domain) -}}
  {{- printf "http://%s-control-plane-metrics-exporter.%s.svc%s:9419/metrics" $src .Release.Namespace $suffix -}}
{{- end -}}

{{/*
searchNamespace list for the Grafana dashboard sidecar: this release's namespace plus the monitoring
one, where kps renders its dashboard ConfigMaps. Deduplicated for the all-in-one case.

Reached through the grafana chart's tpl of sidecar.dashboards.searchNamespace, hence in the GRAFANA
subchart's context: read nothing but .Release and .Values.global here.
*/}}
{{- define "armonik.monitoring.dashboardNamespaces" -}}
  {{- $ops := include "armonik.operators" . | fromYaml -}}
  {{- $ns := $ops.prometheusOperator.namespace -}}
  {{- if empty $ns -}}
    {{- fail "global.armonik.operators.prometheusOperator.namespace resolved empty: set it to the namespace of the release installing kube-prometheus-stack. It only defaults to this release's namespace when this release installs it." -}}
  {{- end -}}
  {{- list .Release.Namespace $ns | uniq | join "," -}}
{{- end -}}

{{/*
Shared cluster Prometheus, for the Grafana datasource and PromQL KEDA triggers:
http://prometheus-prometheus.<prometheusOperator namespace>.svc[.<clusterDomain>]:9090, the service
name being fixed by the kps fullnameOverride in armonik-operators. That namespace is empty, hence fatal,
unless this release installs kps or it was stated: no unresolvable host gets emitted. Point the value at a
literal URL for a Prometheus armonik-operators did not deploy.
*/}}
{{- define "armonik.monitoring.prometheusUrl" -}}
  {{- $ops := include "armonik.operators" . | fromYaml -}}
  {{- $ns := $ops.prometheusOperator.namespace -}}
  {{- if empty $ns -}}
    {{- fail "global.armonik.operators.prometheusOperator.namespace resolved empty: set it to the namespace of the release installing kube-prometheus-stack. It only defaults to this release's namespace when this release installs it." -}}
  {{- end -}}
  {{- $domain := list .Values "global" "clusterDomain" | include "armonik.utils.index" -}}
  {{- $suffix := $domain | empty | ternary "" (printf ".%s" $domain) -}}
  {{- printf "http://prometheus-prometheus.%s.svc%s:9090" $ns $suffix -}}
{{- end -}}
