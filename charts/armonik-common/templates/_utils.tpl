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
      "Values" (list $root.Values "global" "armonik-dependencies" $dependency | include "armonik.utils.index" | fromYaml)
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
Constructs and returns an image configuration object (see schema below) representing the most complete image configuration
given a context and one or more image configuration objects.

Here, "the most complete image configuration" means that the template retrieves each 
attribute from the first image object passed to it (i.e. with precedence from left to right).

If no tag is found in the provided image configuration objects, the templates looks into the `appVersion`  defined in Chart.yaml
and ultimately sets it to "latest" if no `appVersion` was found.

Thus, when calling this template for an third-party image deployed with the armonik-dependencies chart, 
is adviced to set the context to the dependency context, especially if you know no tag is provided. 

Usage:
 {{- include "armonik.utils.finalImageConf" (list <context> <imageConf1> <imageConf2> ...)| fromYaml }}
Example:
{{- $ctx :=  list $ "mongodb" | include "armonik.dependencyContext" | fromYaml -}}
{{- $imageConf := list $ctx .Values.mongodb.image .Values.mongodbCommon.image  | include "armonik.utils.finalImageConf" | fromYaml }}

image configuration object schema:
  registry: string
  repository: string
  name: string
  tag: string
  pullPolicy: string in ['IfNotPresent', 'Always', 'Never']
*/}}
{{- define "armonik.utils.finalImageConf" -}}
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


{{/*
Like index, but does not error if any intermediary key is absent.
If result is empty, it is not printed out, and thus is directly compatible with conditions.

To get the result as a value other than a string you would need to convert it back using the following functions:
- bool: `empty`
- int: `int`
- array: `fromYamlArray`
- object: `fromYaml`
*/}}
{{- define "armonik.utils.index" -}}
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
Usage:
{{- $call := dict "src" $src "dst" $dst "render" true -}}
{{- include "armonik.utils.merge" $call -}}
{{- $dst := $call.dst -}}

schema:
  # destination of the merge. If dst is a dict or a list, it will be modified in-place
  dst: any
  # value to merge into dst
  src: any
  # values to merge into dst, if both src and srcs are set, src is first merged before each elements of srcs are merged
  srcs: list
  # if overwrite is enabled, src values will have precedence over dst
  overwrite: bool = false
  # if nullIsAbsent, null values will be considered as if the key does not exist at all
  nullIsAbsent: bool = true
  # if emptyStringIsAbsent, empty values will be considered as if the key does not exist at all
  emptyStringIsAbsent: bool = true
  # if render, string values will be rendered before being merged
  render: bool = false
  # if concatList, when both src and dst are non-empty list, they will be concatenated together instead of one replacing the other
  concatList: bool = false
  # Context passed to rendering
  context: any
  # Prints the result as yaml
  print: bool = true
 */}}
{{- define "armonik.utils.merge" -}}
  {{/* Default options */}}
  {{- $overwrite := eq $.overwrite nil | ternary false $.overwrite -}}
  {{- $nullIsAbsent := eq $.nullIsAbsent nil | ternary true $.nullIsAbsent -}}
  {{- $emptyStringIsAbsent := eq $.emptyStringIsAbsent nil | ternary true $.emptyStringIsAbsent -}}
  {{- $render := eq $.render nil | ternary false $.render -}}
  {{- $concatList := eq $.concatList nil | ternary false $.concatList -}}
  {{- $print := eq $.print nil | ternary true $.print -}}
  {{- $options := pick $ "overwrite" "nullIsAbsent" "emptyStringIsAbsent" "render" "concatList" "context" -}}
  {{- $_ := set $options "print" false -}}

  {{/* Render template if enabled */}}
  {{- if kindIs "string" $.src | and $render -}}
    {{- $_ := tpl ($.src | default "") $.context | set $ "src" -}}
  {{- end -}}

  {{/* If dst is absent */}}
  {{- if or (hasKey $ "dst" | not) (eq $.dst nil | and $nullIsAbsent) (and $emptyStringIsAbsent (kindIs "string" $.dst) (not $.dst)) -}}
    {{- if hasKey $ "src" -}}
      {{- if kindIs "slice" $.src | and $render -}}
        {{- $_ := set $ "dst" list -}}
        {{- range $.src -}}
          {{- $call := merge (dict "src" .) $options -}}
          {{- $_ := include "armonik.utils.merge" $call -}}
          {{- $_ := append $.dst $call.dst | set $ "dst" -}}
        {{- end -}}
      {{- else if kindIs "map" $.src | and $render -}}
        {{- $_ := set $ "dst" dict -}}
        {{- range $k, $v := $.src -}}
          {{- $call := merge (dict "src" $v) $options -}}
          {{- $_ := include "armonik.utils.merge" $call -}}
          {{- $_ := set $.dst $k $call.dst -}}
        {{- end -}}
      {{- else -}}
        {{- $_ := set $ "dst" $.src -}}
      {{- end -}}
    {{- else -}}
      {{- $_ := unset $ "dst" -}}
    {{- end -}}

  {{/* Else if src is present */}}
  {{- else if or (hasKey $ "src" | not) (eq $.src nil | and $nullIsAbsent) (and $emptyStringIsAbsent (kindIs "string" $.src) (not $.src)) | not -}}
    {{- if kindIs "map" $.dst -}}
      {{- if kindIs "map" $.src -}}
        {{/* Merge map with map */}}
        {{- range $k, $v := $.src -}}
          {{- $call := merge (dict "src" $v) $options -}}
          {{- if hasKey $.dst $k -}}
            {{- $_ := set $call "dst" (index $.dst $k) -}}
          {{- end -}}
          {{- $_ := include "armonik.utils.merge" $call -}}
          {{- $_ := set $.dst $k $call.dst -}}
        {{- end -}}
      {{- else if kindIs "slice" $.src -}}
        {{/* Merge map with list */}}
        {{- $dst := $.dst -}}
        {{- $_ := set $ "dst" list -}}
        {{- range $.src -}}
          {{- $call := merge (dict "src" . "dst" (deepCopy $dst)) $options -}}
          {{- $_ := include "armonik.utils.merge" $call -}}
          {{- $_ := append $.dst $call.dst | set $ "dst" -}}
        {{- end -}}
      {{- else -}}
        {{/* Merge map with scalar */}}
        {{- kindOf $.src | printf "cannot merge a map with a %s" | fail -}}
      {{- end -}}
    {{- else if kindIs "slice" $.dst -}}
      {{- if kindIs "slice" $.src -}}
        {{/* Merge slice with slice */}}
        {{- if $.concatList -}}
          {{- range $.src -}}
            {{- $call := merge (dict "src" .) $options -}}
            {{- $_ := include "armonik.utils.merge" $call -}}
            {{- $_ := append $.dst $call.dst | set $ "dst" -}}
          {{- end -}}
        {{- else if $.overwrite -}}
          {{- $_ := unset $ "dst" -}}
          {{- $_ := include "armonik.utils.merge" $ -}}
        {{- end -}}
      {{- else -}}
        {{/* Merge slice with scalar */}}
        {{- $dst := $.dst -}}
        {{- $_ := set $ "dst" list -}}
        {{- range $dst -}}
          {{- $call := merge (dict "src" $.src "dst" .) $options -}}
          {{- $_ := include "armonik.utils.merge" $call -}}
          {{- $_ := append $.dst $call.dst | set $ "dst" -}}
        {{- end -}}
      {{- end -}}
    {{- else if $.overwrite -}}
      {{/* Merge scalar with something else */}}
      {{- $_ := unset $ "dst" -}}
      {{- $_ := include "armonik.utils.merge" $ -}}
    {{- end -}}
  {{- end -}}

  {{/* Merge the remaining sources */}}
  {{- range $.srcs | default list -}}
    {{- $call := merge (dict "src" . "dst" $.dst) $options -}}
    {{- $_ := include "armonik.utils.merge" $call -}}
    {{- $_ := set $ "dst" $call.dst -}}
  {{- end -}}

  {{- if $print -}}
    {{- $.dst | toYaml -}}
  {{- end -}}
{{- end -}}