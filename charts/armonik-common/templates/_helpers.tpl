{{/*
Chart name: nameOverride, else .Chart.Name (the alias under an umbrella).
*/}}
{{- define "armonik.name" -}}
  {{-  .Values.nameOverride | default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Target namespace: namespaceOverride, else .Release.Namespace.
*/}}
{{- define "armonik.namespace" -}}
  {{-  .Values.namespaceOverride | default .Release.Namespace }}
{{- end }}

{{/*
Fully qualified app name, truncated to 63 chars (DNS label): fullnameOverride, else
<release>-<name>, collapsed to <release> when the release name already contains the name.
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
<chart>-<version> for the helm.sh/chart label.
*/}}
{{- define "armonik.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
ServiceAccount name: serviceAccount.name, tpl-rendered so a chart can default it to a release-derived
name, else armonik.fullname. Required when create=false.
*/}}
{{- define "armonik.serviceAccountName" -}}
  {{- $name := tpl (.Values.serviceAccount.name | default "") . -}}
  {{- if .Values.serviceAccount.create }}
    {{- $name | default (include "armonik.fullname" .) }}
  {{- else }}
    {{- $name | required "serviceAccount.name is required when serviceAccount.create is false: set it to the name of the existing ServiceAccount to use" }}
  {{- end }}
{{- end }}

{{/* PodDisruptionBudget apiVersion: policy/v1 when served, else policy/v1beta1. */}}
{{- define "armonik.pdb.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
      {{- print "policy/v1" -}}
  {{- else -}}
    {{- print "policy/v1beta1" -}}
  {{- end -}}
{{- end -}}


{{/*
Common labels, plus .Values.commonLabels.
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
Selector labels: name and instance only, since selectors are immutable and changing them breaks upgrades.
*/}}
{{- define "armonik.selectorLabels" -}}
app.kubernetes.io/name: {{ include "armonik.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end }}

{{/*
Cluster DNS domain for callers needing a complete name (Certificate dnsNames, nginx upstreams):
tls.clusterDomain, clusterDomain, global.clusterDomain, then "cluster.local". Callers that can stop at
".svc" read global.clusterDomain instead and drop the suffix when it is empty.
*/}}
{{- define "armonik.clusterDomain" -}}
  {{- $tls := .Values.tls | default dict -}}
  {{- $global := list .Values "global" "clusterDomain" | include "armonik.utils.index" -}}
  {{- coalesce $tls.clusterDomain .Values.clusterDomain $global "cluster.local" -}}
{{- end -}}

{{/*
Port of the "control-port" entry in the umbrella's control-plane.service.ports, 0 when absent.
*/}}
{{- define "armonik.controlPlane.servicePort" -}}
	{{- $ports := list .Values "control-plane" "service" "ports" | include "armonik.utils.index" | fromYamlArray -}}
	{{- $port := 0 -}}
	{{- range $servicePort := $ports -}}
		{{- if eq (get $servicePort "name") "control-port" -}}
			{{- $port = int (get $servicePort "port") -}}
		{{- end -}}
	{{- end -}}
	{{- $port -}}
{{- end }}

{{/*
containerPort of the entry named .name in .ports, empty when none matches.

  {{ include "armonik.netpol.port" (dict "ports" $ports "name" "grpc") }}
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
