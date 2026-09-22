{{/*
Parses `[registry/]repository[:tag][@digest]` into the image fields, where repository is the whole path
under the registry, as the OCI spec defines it. The first segment is the registry when it carries a "."
or ":", or is "localhost". The digest is split off first, so the rest still decomposes and a registry
override reaches a digest-pinned reference.

  {{- $ref := include "armonik.utils.imageRef.parse" "fluent/fluent-bit:5.1.2" | fromYaml }}
*/}}
{{- define "armonik.utils.imageRef.parse" -}}
  {{- $out := dict "registry" "" "repository" "" "tag" "" "digest" "" -}}
  {{- $ref := . -}}
  {{- if contains "@" $ref -}}
    {{- $_ := splitList "@" $ref | last | set $out "digest" -}}
    {{- $ref = splitList "@" $ref | first -}}
  {{- end -}}
  {{- if $ref -}}
    {{- $parts := splitList "/" $ref -}}
    {{- $last := last $parts -}}
    {{- if contains ":" $last -}}
      {{- $_ := splitList ":" $last | last | set $out "tag" -}}
      {{- $parts = splitList ":" $last | first | list | concat (initial $parts) -}}
    {{- end -}}
    {{- $first := first $parts -}}
    {{- if and (gt (len $parts) 1) (or (contains "." $first) (contains ":" $first) (eq $first "localhost")) -}}
      {{- $_ := set $out "registry" $first -}}
      {{- $_ := rest $parts | join "/" | set $out "repository" -}}
    {{- else -}}
      {{- $_ := join "/" $parts | set $out "repository" -}}
    {{- end -}}
  {{- end -}}
  {{- $out | toYaml -}}
{{- end -}}


{{/*
Merges partial image configs left to right into the schema below, plus `fullname`. Each may instead be
a reference string; one that supplies the repository settles the registry too, so a bare
`busybox:1.37.0` cannot pick up a registry from a lower-precedence config. pullPolicy, which no string
carries, still merges.

`repository` is the whole path under the registry (dockerhubaneo/armonik_control), as everywhere else
in the ecosystem, which is also what lets renovate resolve it.

The tag defaults from the repository, not the call site, which is what a worker needs: a repository
listed in global.armonik.imageComponents takes its component's version from global.armonik.versions,
empty or absent meaning the chart AppVersion. Any other image must carry a tag. `latest` is never a
fallback: it installs cleanly, then drifts per node under IfNotPresent and defeats an airgap mirror.

global.imageRegistry overrides whatever registry was chosen, and may carry a path prefix. The values
path argument makes a failure name the key to set.

  {{- $image := list $ "metricsExporter.image" .Values.metricsExporter.image .Values.image | include "armonik.utils.imageConf" | fromYaml }}

schema: registry, repository, tag, digest (rendered repository[:tag]@digest), pullPolicy
*/}}
{{- define "armonik.utils.imageConf" -}}
  {{- $ctx := first . -}}
  {{- $path := index . 1 -}}
  {{- $imageConfs := slice . 2 -}}
  {{- $image := dict "registry" "" "repository" "" "tag" "" "digest" "" "pullPolicy" "" -}}
  {{/* Set once a reference string settled the repository, freezing the registry it spoke for. */}}
  {{- $settled := false -}}
  {{- range $imageConf := $imageConfs -}}
    {{- $isRef := kindIs "string" $imageConf -}}
    {{- $conf := $imageConf -}}
    {{- if $isRef -}}
      {{- $conf = include "armonik.utils.imageRef.parse" $imageConf | fromYaml -}}
    {{- end -}}
    {{- $conf = $conf | default dict -}}
    {{- $unset := $image.repository | empty -}}
    {{- if not $settled -}}
      {{- $_ := coalesce $image.registry $conf.registry | set $image "registry" -}}
    {{- end -}}
    {{- $_ := coalesce $image.repository $conf.repository | set $image "repository" -}}
    {{- $_ := coalesce $image.tag $conf.tag | set $image "tag" -}}
    {{- $_ := coalesce $image.digest $conf.digest | set $image "digest" -}}
    {{- $_ := coalesce $image.pullPolicy $conf.pullPolicy | set $image "pullPolicy" -}}
    {{- if and $isRef $unset $conf.repository -}}
      {{- $settled = true -}}
    {{- end -}}
  {{- end -}}
  {{/* Overrides rather than defaults, as in every chart honouring it: relocation must beat what a
       chart, a values file or a reference string chose. */}}
  {{- with list $ctx.Values "global" "imageRegistry" | include "armonik.utils.index" -}}
    {{- $_ := set $image "registry" . -}}
  {{- end -}}
  {{- if $image.repository | empty -}}
    {{- printf "%s.repository is required: no image repository resolved." $path | fail -}}
  {{- end -}}
  {{/* A digest pins the image, so no tag is invented for it. */}}
  {{- if and ($image.digest | empty) ($image.tag | empty) -}}
    {{- $components := list $ctx.Values "global" "armonik" "imageComponents" | include "armonik.utils.index" | fromYaml | default dict -}}
    {{- if hasKey $components ($image.repository | toString) -}}
      {{- $versions := list $ctx.Values "global" "armonik" "versions" | include "armonik.utils.index" | fromYaml | default dict -}}
      {{- $_ := index $components ($image.repository | toString) | index $versions | default $ctx.Chart.AppVersion | set $image "tag" -}}
    {{- end -}}
  {{- end -}}
  {{- if and ($image.digest | empty) ($image.tag | empty) -}}
    {{- printf "%s.tag is required: pin it, or map the repository to a component in global.armonik.imageComponents." $path | fail -}}
  {{- end -}}
  {{- $fullname := list $image.registry $image.repository | compact | join "/" -}}
  {{- with $image.tag -}}
    {{- $fullname = printf "%s:%s" $fullname . -}}
  {{- end -}}
  {{- with $image.digest -}}
    {{- $fullname = printf "%s@%s" $fullname . -}}
  {{- end -}}
  {{- $_ := set $image "fullname" $fullname -}}
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
