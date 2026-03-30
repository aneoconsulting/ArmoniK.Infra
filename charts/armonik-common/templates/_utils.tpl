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