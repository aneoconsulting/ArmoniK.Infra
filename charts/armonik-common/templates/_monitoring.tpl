{{/*
Each value comes as a pair: `<value>.default` derives the default, `<value>` resolves whatever the value
holds, tpl-rendering it since that default is a template string. Only values.yaml calls a `.default`,
which must never read its own value, or tpl recurses.

  values.yaml   prometheusUrl: '{{ include "armonik.monitoring.prometheusUrl.default" . }}'
  template      {{- $url := include "armonik.monitoring.prometheusUrl" $ -}}
*/}}

{{/*
Resolves metricsExporterUrl. Its default reads the chart-level conf.source, so only our charts can call it.
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
http://<conf.source>-control-plane-metrics-exporter.<ns>.svc[.<clusterDomain>]:9419/metrics, <ns> being
this chart's armonik.namespace (the umbrella's namespace-guard keeps both planes in one namespace).
Right under the umbrella: conf.source is its release name, and the "control-plane" alias makes
armonik.fullname <release>-control-plane. Wrong for a standalone control-plane release, whose service is
<that release>-armonik-control-plane-metrics-exporter: set global.armonik.monitoring.metricsExporterUrl
there, as global.armonik.controlPlane for the control-plane URL.
*/}}
{{- define "armonik.monitoring.metricsExporterUrl.default" -}}
  {{- $src := include "armonik.conf.source" . -}}
  {{- $domain := list .Values "global" "clusterDomain" | include "armonik.utils.index" -}}
  {{- $suffix := $domain | empty | ternary "" (printf ".%s" $domain) -}}
  {{- printf "http://%s-control-plane-metrics-exporter.%s.svc%s:9419/metrics" $src (include "armonik.namespace" .) $suffix -}}
{{- end -}}

{{/*
Resolves prometheusUrl: the Grafana datasource, and a PromQL KEDA trigger's endpoint.
*/}}
{{- define "armonik.monitoring.prometheusUrl" -}}
  {{- $raw := list .Values "global" "armonik" "monitoring" "prometheusUrl" | include "armonik.utils.index" -}}
  {{- $url := tpl $raw . -}}
  {{- if empty $url -}}
    {{- fail "global.armonik.monitoring.prometheusUrl resolved empty: set it. It only derives where this release installs kube-prometheus-stack, never in a layered install nor in a plane chart." -}}
  {{- end -}}
  {{- $url -}}
{{- end -}}

{{/*
Prometheus of the kube-prometheus-stack this release installs, named by that chart's own helpers.
Empty where kps is not in .Subcharts (layered install, plane chart), where its name is unknowable
without lookup, so the resolver fails.
*/}}
{{- define "armonik.monitoring.prometheusUrl.default" -}}
  {{- $kps := index .Subcharts "kube-prometheus" -}}
  {{- with .Subcharts.operators -}}
    {{- $kps = index .Subcharts "kube-prometheus" | default $kps -}}
  {{- end -}}
  {{- with $kps -}}
    {{- $domain := list $.Values "global" "clusterDomain" | include "armonik.utils.index" -}}
    {{- $suffix := $domain | empty | ternary "" (printf ".%s" $domain) -}}
    {{- printf "http://%s-prometheus.%s.svc%s:%d"
          (include "kube-prometheus-stack.fullname" .)
          (include "kube-prometheus-stack.namespace" .)
          $suffix
          (.Values.prometheus.service.port | int) -}}
  {{- end -}}
{{- end -}}

{{/*
searchNamespace of the Grafana dashboard sidecar: this release's namespace plus the one where kps renders
its dashboard ConfigMaps, deduplicated. No resolver: the value is the grafana chart's own, and it tpl-renders
it in the GRAFANA context, so read only .Release and .Values.global here.
*/}}
{{- define "armonik.monitoring.dashboardNamespaces.default" -}}
  {{- $ops := include "armonik.operators" . | fromYaml -}}
  {{- $ns := $ops.prometheusOperator.namespace -}}
  {{- if empty $ns -}}
    {{- fail "global.armonik.operators.prometheusOperator.namespace resolved empty: set it to the namespace of the release installing kube-prometheus-stack. It only defaults to this release's namespace when this release installs it." -}}
  {{- end -}}
  {{- list .Release.Namespace $ns | uniq | join "," -}}
{{- end -}}
