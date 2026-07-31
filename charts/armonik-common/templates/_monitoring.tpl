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
  {{- $domain := list .Values "global" "armonik" "clusterDomain" | include "armonik.utils.index" -}}
  {{- printf "http://%s-control-plane-metrics-exporter.%s.svc%s:9419/metrics" $src .Release.Namespace (ternary "" (printf ".%s" $domain) (empty $domain)) -}}
{{- end -}}

{{/*
Namespace of the armonik-operators release (the shared kube-prometheus-stack), read from the value
whose default is this release's own namespace. Nothing in a release can discover it, hence the value;
the two helpers below build on it. Fails on empty instead of letting a blank segment reach a host or
the sidecar's namespace list.
*/}}
{{- define "armonik.monitoring.namespace" -}}
  {{- $ns := tpl (list .Values "global" "armonik" "monitoring" "namespace" | include "armonik.utils.index") . -}}
  {{- if empty $ns -}}
    {{- fail "global.armonik.monitoring.namespace resolved empty. Set it to the namespace of the armonik-operators release; the chart default is this release's own namespace." -}}
  {{- end -}}
  {{- $ns -}}
{{- end -}}

{{/*
searchNamespace list for the Grafana dashboard sidecar: this release's namespace plus the monitoring
one, where kps renders its dashboard ConfigMaps. Deduplicated for the all-in-one case.

Reached through the grafana chart's tpl of sidecar.dashboards.searchNamespace, hence in the GRAFANA
subchart's context: read nothing but .Release and .Values.global here.
*/}}
{{- define "armonik.monitoring.dashboardNamespaces" -}}
  {{- list .Release.Namespace (include "armonik.monitoring.namespace" .) | uniq | join "," -}}
{{- end -}}

{{/*
Shared cluster Prometheus, for the Grafana datasource and PromQL KEDA triggers:
http://prometheus-prometheus.<armonik.monitoring.namespace>.svc[.<clusterDomain>]:9090, the service
name being fixed by the kps fullnameOverride in armonik-operators.

Fails instead of emitting an unresolvable host when this release does not deploy the prometheus
operator and the monitoring namespace is still the release namespace: Prometheus is then elsewhere
and nothing here knows where.
*/}}
{{- define "armonik.monitoring.prometheusUrl" -}}
  {{- $ns := include "armonik.monitoring.namespace" . -}}
  {{- if and (not (include "armonik.operators" . | fromYaml).prometheusOperator.deploy) (eq $ns .Release.Namespace) -}}
    {{- fail (printf "global.armonik.monitoring: this release does not install kube-prometheus-stack (global.armonik.operators.prometheusOperator.deploy=false), so the shared Prometheus is not in namespace %q and its location is unknown. Set global.armonik.monitoring.namespace to the namespace of the armonik-operators release (which also points the Grafana sidecar at the kps dashboards), or global.armonik.monitoring.prometheusUrl to a full URL." .Release.Namespace) -}}
  {{- end -}}
  {{- $domain := list .Values "global" "armonik" "clusterDomain" | include "armonik.utils.index" -}}
  {{- printf "http://prometheus-prometheus.%s.svc%s:9090" $ns (ternary "" (printf ".%s" $domain) (empty $domain)) -}}
{{- end -}}
