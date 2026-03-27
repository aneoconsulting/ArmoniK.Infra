{{- define "armonik.conf.computeHelper" -}}
{{- end -}}

{{- define "armonik.conf.computeRaw" -}}
  {{- $ctx := include "armonik.conf.context" . | fromYaml -}}
  {{- list
        (include "armonik.conf.log" . | fromYaml)
        (include "armonik.conf.computeHelper" $ctx | fromYaml)
        $ctx.Values.compute
      | include "armonik.conf.merge"
  -}}
{{- end -}}

{{- define "armonik.conf.compute" -}}
  {{- $configmap := list "compute" . | include "armonik.conf.configmap" -}}
  {{- include "armonik.conf.computeRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
{{- end -}}

{{- define "armonik.conf.partitions" -}}
{{- $idx := 0 -}}
env:
  {{- range $partitionName, $partition := . }}
    {{- if hasKey $partition "name" | not }}
      {{- $_ := set $partition "name" $partitionName }}
    {{- end }}
    InitServices__Partitioning__Partitions__{{ $idx }}
  {{- end }}
{{- end -}}
