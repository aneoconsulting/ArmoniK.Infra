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

{{/*

*/}}
{{- define "armonik.image" -}}
  {{- $ctx := first . -}}
  {{- $imageConfs := rest . -}}
  {{- $image := dict
    "registry" ""
    "repository" ""
    "name" ""
    "tag" ""
    "pullPolicy" ""
  -}}
  {{- range $imageConf := $imageConfs -}}
    {{- $_ := coalesce $image.registry $imageConf.registry | set $image "registry" -}}
    {{- $_ := coalesce $image.repository $imageConf.repository | set $image "repository" -}}
    {{- $_ := coalesce $image.name $imageConf.name | set $image "name" -}}
    {{- $_ := coalesce $image.tag $imageConf.tag | set $image "tag" -}}
    {{- $_ := coalesce $image.pullPolicy $imageConf.pullPolicy | set $image "pullPolicy" -}}
  {{- end -}}
  {{- $_ := coalesce $image.tag $ctx.Chart.AppVersion "latest" | set $image "tag" -}}
  {{- if $image.registry -}}
    {{- $_ := printf "%s/%s/%s:%s" $image.registry $image.repository $image.name $image.tag | set $image "fullname" -}}
  {{- else if $image.repository -}}
    {{- $_ := printf "%s/%s:%s" $image.repository $image.name $image.tag | set $image "fullname" -}}
  {{- else -}}
    {{- $_ := printf "%s:%s" $image.name $image.tag | set $image "fullname" -}}
  {{- end -}}
  {{- $image | toYaml -}}
{{- end -}}
