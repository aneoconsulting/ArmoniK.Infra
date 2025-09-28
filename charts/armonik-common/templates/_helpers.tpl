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
