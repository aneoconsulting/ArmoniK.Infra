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
Returns the name of the service account to use
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
Cluster DNS domain for callers needing a complete name (ingress Certificate dnsNames, nginx upstreams):
tls.clusterDomain, clusterDomain, global.clusterDomain, then the Kubernetes default. Callers that can
stop at ".svc" read global.clusterDomain and drop the suffix when it is empty.
*/}}
{{- define "armonik.clusterDomain" -}}
  {{- $tls := .Values.tls | default dict -}}
  {{- $global := list .Values "global" "clusterDomain" | include "armonik.utils.index" -}}
  {{- coalesce $tls.clusterDomain .Values.clusterDomain $global "cluster.local" -}}
{{- end -}}

{{/*
  Generic port lookup.
*/}}
{{- define "armonik.netpol.port" -}}
{{- $ports := .ports | default list -}}
{{- $name := .name -}}
{{- range $port := $ports -}}
  {{- if eq $port.name $name -}}
    {{- $port.containerPort -}}
  {{- end -}}
{{- end -}}
{{- end -}}
