{{/*
Full URL of the control-plane metrics-exporter /metrics endpoint - the source KEDA scrapes directly
(default scaling path, no Prometheus in the loop). Precedence:
global.armonik.monitoring.metricsExporterUrl (tpl-rendered if set) >
http://<conf.source>-control-plane-metrics-exporter.<release-ns>.svc[.<clusterDomain>]:9419/metrics.

The default reuses armonik.conf.source (the SAME indirection as the conf Secret names): under the
umbrella that's the release name, and a standalone compute-plane that sets conf.source=<main-release>
(as it already must, to find the conf Secrets) therefore resolves the main control-plane's exporter
with no extra flag. The host stops at ".svc" (resolves in-cluster without assuming the cluster domain);
set global.armonik.clusterDomain to force an FQDN. Override metricsExporterUrl only for edge cases -
a control-plane in another namespace, or with a custom fullnameOverride.

# Usage

{{ include "armonik.monitoring.metricsExporterUrl" $ }}
*/}}
{{- define "armonik.monitoring.metricsExporterUrl" -}}
  {{- $v := list .Values "global" "armonik" "monitoring" "metricsExporterUrl" | include "armonik.utils.index" -}}
  {{- if $v -}}
    {{- tpl $v . -}}
  {{- else -}}
    {{- $src := include "armonik.conf.source" . -}}
    {{- $domain := list .Values "global" "armonik" "clusterDomain" | include "armonik.utils.index" -}}
    {{- printf "http://%s-control-plane-metrics-exporter.%s.svc%s:9419/metrics" $src .Release.Namespace (ternary "" (printf ".%s" $domain) (empty $domain)) -}}
  {{- end -}}
{{- end -}}
