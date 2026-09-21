{{/*
Coalesces {registry, repository, name, tag, pullPolicy} left to right and adds `fullname`. An absent
tag falls back to the context's .Chart.AppVersion, then "latest", so for a dependency's image pass
that dependency's scope (.Subcharts.dependencies.Subcharts.<dep>), not the umbrella's.

{{- $imageConf := list $ .Values.image | include "armonik.utils.imageConf" | fromYaml }}
*/}}
{{- define "armonik.utils.imageConf" -}}
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

A string value is rendered raw and must be `quote`d before being inserted into a template.
Any other value is toYaml-encoded and needs a conversion function to get the proper type:
- bool: `empty | not`
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
    {{- if kindIs "string" $value.value -}}
      {{- $value.value -}}
    {{- else -}}
      {{- $value.value | toYaml -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


{{/* 
{{- $call := dict "src" $src "dst" $dst "render" true -}}
{{- include "armonik.utils.merge" $call -}}
{{- $dst := $call.dst -}}

schema:
  dst: any                        # merged into in place when a dict or a list
  src: any                        # merged first, before srcs
  srcs: list                      # merged in order after src
  overwrite: bool = false         # src wins over dst
  nullIsAbsent: bool = true       # null reads as "key not set"
  emptyStringIsAbsent: bool = true
  render: bool = false            # tpl string values before merging, against `context`
  concatList: bool = false        # two non-empty lists concatenate instead of replacing
  context: any
  print: bool = true              # emit the result as yaml
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


{{/*
Merges a user patch over a rendered YAML fragment, the patch winning.

A list replaces rather than merges by key, so a key the fragment already builds is refused: dropping
what the chart put in `containers` or `env` would surface as a broken workload, not a render error.
`command` and `args` are exempt. Null is absent to the merge, so a patch cannot delete.

{{- $spec := list (include "armonik.compute.podSpec" $ctx) $partition.podSpecPatch "podSpecPatch" | include "armonik.utils.patch" -}}
*/}}
{{- define "armonik.utils.patch" -}}
  {{- $base := index . 0 | fromYaml -}}
  {{- $patch := index . 1 | default dict -}}
  {{- $name := index . 2 -}}
  {{- range $key, $value := $patch -}}
    {{- if and (kindIs "slice" $value) (kindIs "slice" (index $base $key)) (has $key (list "command" "args") | not) -}}
      {{- printf "%s.%s: the chart builds %s and a patch would replace it wholesale. Add to it with the matching extra* value, or change the chart value that builds it." $name $key $key | fail -}}
    {{- end -}}
  {{- end -}}
  {{- dict "dst" $base "src" $patch "overwrite" true "print" false | include "armonik.utils.merge" -}}
  {{- $base | toYaml -}}
{{- end -}}
