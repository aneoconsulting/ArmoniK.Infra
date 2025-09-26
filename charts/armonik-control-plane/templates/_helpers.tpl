{{/*
Expand the name of the chart.
*/}}
{{- define "armonik.control.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "armonik.control.fullname" -}}
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
{{- define "armonik.control.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "armonik.control.labels" -}}
helm.sh/chart: {{ include "armonik.control.chart" . }}
{{ include "armonik.control.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "armonik.control.selectorLabels" -}}
app.kubernetes.io/name: {{ include "armonik.control.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "armonik.control.metricsLabels" -}}
helm.sh/chart: {{ include "armonik.control.chart" . }}
{{ include "armonik.control.metricsSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "armonik.control.metricsSelectorLabels" -}}
app.kubernetes.io/name: {{ include "armonik.control.name" . }}-metrics
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "armonik.control.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "armonik.control.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
The image to use
*/}}
{{- define "armonik.control.image" -}}
{{- printf "%s:%s" .Values.image.repository (default (printf "v%s" .Chart.AppVersion) .Values.image.tag) }}
{{- end }}

{{/*
The image to use for the addon resizer
*/}}
{{- define "armonik.control.addonResizer.image" -}}
{{- printf "%s:%s" .Values.addonResizer.image.repository .Values.addonResizer.image.tag }}
{{- end }}

{{/*
ConfigMap name of addon resizer
*/}}
{{- define "armonik.control.addonResizer.configMap" -}}
{{- printf "%s-%s" (include "armonik.control.fullname" .) "nanny-config" }}
{{- end }}

{{/*
Role name of addon resizer
*/}}
{{- define "armonik.control.addonResizer.role" -}}
{{ printf "system:%s-nanny" (include "armonik.control.fullname" .) }}
{{- end }}

{{/* Get PodDisruptionBudget API Version */}}
{{- define "armonik.control.pdb.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
      {{- print "policy/v1" -}}
  {{- else -}}
    {{- print "policy/v1beta1" -}}
  {{- end -}}
{{- end -}}

{{- define "armonikCore.tag" }}
{{- if .Values.global.version.armonikCore }}{{ .Values.global.version.armonikCore }}
{{- else if .Values.image.tag }}{{ .Values.image.tag }}
{{- end }}
{{- end }}


{{- define "armonik.control.confHelper" }}
{{- $defaultPartition := .Values.defaultPartition }}
{{- $partitionNames := .Values.extraPartitions }}
env:
  {{- if and $defaultPartition (has $defaultPartition $partitionNames) }}
  Submitter__DefaultPartition: {{ $defaultPartition }}
  {{- else if gt (len $partitionNames) 0 }}
  Submitter__DefaultPartition: {{ index $partitionNames 0 }}
  {{- else }}
  Submitter__DefaultPartition: ""
  {{- end }}
  InitServices__InitDatabase: {{ not .Values.init.enabled | quote }}
  InitServices__InitObjectStorage: {{ not .Values.init.enabled | quote }}
  InitServices__InitQueue: {{ not .Values.init.enabled | quote }}
  InitServices__StopAfterInit: "false"
{{- end }}

{{- define "armonik.control.initConfHelper" }}
{{- $defaultPartition := .Values.defaultPartition }}
{{- $partitionNames := .Values.extraPartitions }}
env:
  Submitter__DefaultPartition: ""
  InitServices__InitDatabase: "true"
  InitServices__InitObjectStorage: "true"
  InitServices__InitQueue: "true"
  InitServices__StopAfterInit: "true"
{{- end }}

{{- define "armonik.control.metricsConfHelper" }}
{{- $defaultPartition := .Values.defaultPartition }}
{{- $partitionNames := .Values.extraPartitions }}
env:
  Submitter__DefaultPartition: ""
  InitServices__InitDatabase: "false"
  InitServices__InitObjectStorage: "false"
  InitServices__InitQueue: "false"
  InitServices__StopAfterInit: "false"
{{- end }}
