{{/* "pdc" layer: pdcHelper hook (PrometheusUrl default when control-plane.podDeletionCost.enabled) + conf.pdc. */}}
{{- define "armonik.conf.pdcHelper" -}}
{{- $cp := index .Values "control-plane" | default dict -}}
{{- $pdc := $cp.podDeletionCost | default dict -}}
{{- if and $pdc.enabled (not $pdc.prometheusUrl) }}
env:
  PrometheusUrl: {{ include "armonik.monitoring.prometheusUrl" . | quote }}
{{- end }}
{{- end -}}

{{- define "armonik.conf.pdc" -}}
  {{- list
        (include "armonik.conf.pdcHelper" . | fromYaml)
        (list .Values "conf" "pdc" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
