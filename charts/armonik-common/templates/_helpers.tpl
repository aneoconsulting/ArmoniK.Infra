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

{{/*
Expand the name of the chart.
*/}}
{{- define "armonik.name" -}}
  {{-  .Values.nameOverride | default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the namespace of the chart.
*/}}
{{- define "armonik.namespace" -}}
  {{-  .Values.namespaceOverride | default .Release.Namespace }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "armonik.fullname" -}}
  {{- if .Values.fullnameOverride }}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- $name := default .Chart.Name .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
      {{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else }}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "armonik.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "armonik.labels" -}}
helm.sh/chart: {{ include "armonik.chart" . }}
{{ include "armonik.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{ .Values.commonLabels | toYaml }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "armonik.selectorLabels" -}}
app.kubernetes.io/name: {{ include "armonik.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "armonik.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "armonik.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Get PodDisruptionBudget API Version */}}
{{- define "armonik.pdb.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
      {{- print "policy/v1" -}}
  {{- else -}}
    {{- print "policy/v1beta1" -}}
  {{- end -}}
{{- end -}}

{{/* 

Usage:
{{- $call := dict "src" $src "dst" $dst "render" true -}}
{{- include "armonik.merge" $call -}}
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
{{- define "armonik.merge" -}}
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
          {{- $_ := include "armonik.merge" $call -}}
          {{- $_ := append $.dst $call.dst | set $ "dst" -}}
        {{- end -}}
      {{- else if kindIs "map" $.src | and $render -}}
        {{- $_ := set $ "dst" dict -}}
        {{- range $k, $v := $.src -}}
          {{- $call := merge (dict "src" $v) $options -}}
          {{- $_ := include "armonik.merge" $call -}}
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
          {{- $_ := include "armonik.merge" $call -}}
          {{- $_ := set $.dst $k $call.dst -}}
        {{- end -}}
      {{- else if kindIs "slice" $.src -}}
        {{/* Merge map with list */}}
        {{- $dst := $.dst -}}
        {{- $_ := set $ "dst" list -}}
        {{- range $.src -}}
          {{- $call := merge (dict "src" . "dst" (deepCopy $dst)) $options -}}
          {{- $_ := include "armonik.merge" $call -}}
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
            {{- $_ := include "armonik.merge" $call -}}
            {{- $_ := append $.dst $call.dst | set $ "dst" -}}
          {{- end -}}
        {{- else if $.overwrite -}}
          {{- $_ := unset $ "dst" -}}
          {{- $_ := include "armonik.merge" $ -}}
        {{- end -}}
      {{- else -}}
        {{/* Merge slice with scalar */}}
        {{- $dst := $.dst -}}
        {{- $_ := set $ "dst" list -}}
        {{- range $dst -}}
          {{- $call := merge (dict "src" $.src "dst" .) $options -}}
          {{- $_ := include "armonik.merge" $call -}}
          {{- $_ := append $.dst $call.dst | set $ "dst" -}}
        {{- end -}}
      {{- end -}}
    {{- else if $.overwrite -}}
      {{/* Merge scalar with something else */}}
      {{- $_ := unset $ "dst" -}}
      {{- $_ := include "armonik.merge" $ -}}
    {{- end -}}
  {{- end -}}

  {{/* Merge the remaining sources */}}
  {{- range $.srcs | default list -}}
    {{- $call := merge (dict "src" . "dst" $.dst) $options -}}
    {{- $_ := include "armonik.merge" $call -}}
    {{- $_ := set $ "dst" $call.dst -}}
  {{- end -}}

  {{- if $print -}}
    {{- $.dst | toYaml -}}
  {{- end -}}
{{- end -}}
