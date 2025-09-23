{{/*
Like index, but does not error if any intermediary key is absent.
If result is empty, it is not printed out, and thus is directly compatible with conditions.

To get the result as a value other than a string you would need to convert it back using the following functions:
- bool: `empty`
- int: `int`
- array: `fromYamlArray`
- object: `fromYaml`
*/}}
{{- define "armonik.index" -}}
  {{- $value := first . | dict "value" -}}
  {{- range $key := rest . -}}
    {{- if $value.value -}}
      {{- $_ := index $value.value $key | set $value "value" -}}
    {{- end -}}
  {{- end -}}
  {{- if $value.value -}}
    {{- $value.value | toYaml -}}
  {{- end -}}
{{- end -}}

{{/*
Gets the context of a dependency to execute named templates from this dependency

# Usage

{{ $ctx := list $ "mongodb" | include "armonik.dependencyContext" $ | fromYaml }}
*/}}
{{- define "armonik.dependencyContext" -}}
  {{- $root := index . 0 -}}
  {{- $dependency := index . 1 -}}
  {{-
    $context := dict
      "Values" (list $root.Values "global" "armonik-dependencies" $dependency | include "armonik.index" | fromYaml)
      "Chart" (dict
        "IsRoot" $root.Chart.IsRoot
        "Name" $dependency
        "Type" "application")
      "Capabilities" $root.Capabilities
      "Files" dict
      "Release" $root.Release
      "Subcharts" dict
      "Template" $root.Template
  -}}
  {{- $context | toYaml -}}
{{- end -}}
