{{- define "armonik.netpol.serviceEnabled" -}}
{{- $ctx := index . 0 -}}
{{- $svcCfg := index . 1 -}}
{{- if kindIs "bool" $svcCfg.enabled -}}
enabled: {{ $svcCfg.enabled }}
{{- else if $svcCfg.dependencyRef -}}
  {{- $dependecies := list $ctx.Values "dependencies" $svcCfg.dependencyRef "enabled" | include "armonik.utils.index" -}}
enabled: {{ $dependecies | default false }}
{{- else -}}
enabled: false
{{- end -}}
{{- end -}}

{{- define "armonik.netpol.egressRulesFromServices" -}}
{{- $ctx := index . 0 -}}
{{- $services := index . 1 -}}
{{- $rules := list -}}
{{- range $name, $svcCfg := $services }}
  {{- $enabled := (include "armonik.netpol.serviceEnabled" (list $ctx $svcCfg) | fromYaml).enabled -}}
  {{- if $enabled }}
    {{- $rules = append $rules (dict
          "to" (list (dict "podSelector" (dict "matchLabels" $svcCfg.labels)))
          "ports" (list (dict "protocol" ($svcCfg.protocol | default "TCP") "port" ($svcCfg.port | int)))) }}
  {{- end }}
{{- end }}
{{- $rules | toYaml -}}
{{- end -}}