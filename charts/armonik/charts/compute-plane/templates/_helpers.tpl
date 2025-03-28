{{/*
Expand the name of the chart.
*/}}
{{- define "computePlane.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "computePlane.fullname" -}}
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
{{- define "computePlane.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "computePlane.labels" -}}
helm.sh/chart: {{ include "computePlane.chart" . }}
{{ include "computePlane.selectorLabels" . }}
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
{{- define "computePlane.selectorLabels" -}}
app.kubernetes.io/name: {{ include "computePlane.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "computePlane.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "computePlane.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
The image to use
*/}}
{{- define "computePlane.image" -}}
{{- printf "%s:%s" .Values.image.repository (default (printf "v%s" .Chart.AppVersion) .Values.image.tag) }}
{{- end }}

{{/*
The image to use for the addon resizer
*/}}
{{- define "computePlane.addonResizer.image" -}}
{{- printf "%s:%s" .Values.addonResizer.image.repository .Values.addonResizer.image.tag }}
{{- end }}

{{/*
ConfigMap name of addon resizer
*/}}
{{- define "computePlane.addonResizer.configMap" -}}
{{- printf "%s-%s" (include "computePlane.fullname" .) "nanny-config" }}
{{- end }}

{{/*
Role name of addon resizer
*/}}
{{- define "computePlane.addonResizer.role" -}}
{{ printf "system:%s-nanny" (include "computePlane.fullname" .) }}
{{- end }}

{{/* Get PodDisruptionBudget API Version */}}
{{- define "computePlane.pdb.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
      {{- print "policy/v1" -}}
  {{- else -}}
    {{- print "policy/v1beta1" -}}
  {{- end -}}
{{- end -}}

{{- define "armonikCore.tag" }}
{{- if .Values.global.version.armonikCore }}{{ .Values.global.version.armonikCore }}{{- end }}
{{- end }}

{{- define "armonikPollingagent.tag" }}
{{- if .Values.global.version.armonikPollingagent }}{{ .Values.global.version.armonikPollingagent }}{{- end }}
{{- end }}
