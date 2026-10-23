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
Port of the "control-port" entry in the umbrella's control-plane.service.ports, 0 when absent. A headless
Service resolves to the pods and maps no port, so the entry's containerPort in control-plane.ports then.
*/}}
{{- define "armonik.controlPlane.servicePort" -}}
	{{- $headless := list .Values "control-plane" "service" "serviceType" | include "armonik.utils.index" | eq "HeadLess" -}}
	{{- $ports := $headless | ternary (list .Values "control-plane" "ports") (list .Values "control-plane" "service" "ports") | include "armonik.utils.index" | fromYamlArray -}}
	{{- $port := 0 -}}
	{{- range $servicePort := $ports -}}
		{{- if eq (get $servicePort "name") "control-port" -}}
			{{- $port = get $servicePort ($headless | ternary "containerPort" "port") | int -}}
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

{{/*
imagePullSecrets of a pod spec, from a list of sources in precedence order (component, chart,
global.imagePullSecrets), any of them nil. An entry is a Secret name or a {name} reference, the two
forms the dependency charts split between, so one global value can serve ours under either. Renders
the list deduplicated by name, the field being a map keyed on it, or nothing when empty.

  {{- with list $component.imagePullSecrets $v.imagePullSecrets $global.imagePullSecrets | include "armonik.imagePullSecrets" }}
  imagePullSecrets: {{- . | nindent 2 }}
  {{- end }}
*/}}
{{- define "armonik.imagePullSecrets" -}}
  {{- $names := list -}}
  {{- range $source := . -}}
    {{- if not (kindIs "slice" ($source | default list)) -}}
      {{- printf "imagePullSecrets must be a list, got %s" (toJson $source) | fail -}}
    {{- end -}}
    {{- range $entry := $source -}}
      {{- $name := $entry -}}
      {{- if kindIs "map" $entry -}}
        {{- $name = $entry.name -}}
      {{- end -}}
      {{- if or (not $name) (kindIs "map" $name) (kindIs "slice" $name) -}}
        {{- printf "imagePullSecrets entry %s names no Secret: use \"<name>\" or {name: <name>}" (toJson $entry) | fail -}}
      {{- end -}}
      {{- $names = toString $name | append $names -}}
    {{- end -}}
  {{- end -}}
  {{- $secrets := list -}}
  {{- range $name := $names | uniq -}}
    {{- $secrets = dict "name" $name | append $secrets -}}
  {{- end -}}
  {{- with $secrets -}}
    {{- toYaml . -}}
  {{- end -}}
{{- end -}}


{{/*
Container securityContext of the ArmoniK processes sharing files (submitter, polling agent, worker):
runAsUser and runAsGroup each default to their global.armonik counterpart, a value set on the
container winning. Nulling a global leaves the image's own. Takes (list <securityContext> <root context>).

  {{- with list $v.securityContext $ | include "armonik.securityContext" }}
  securityContext: {{- . | nindent 2 }}
  {{- end }}
*/}}
{{- define "armonik.securityContext" -}}
  {{- $securityContext := index . 0 | default dict | deepCopy -}}
  {{- $global := (index . 1).Values.global | default dict -}}
  {{- $armonik := $global.armonik | default dict -}}
  {{- range $key := list "runAsUser" "runAsGroup" -}}
    {{- if index $securityContext $key | kindIs "invalid" -}}
      {{- $_ := unset $securityContext $key -}}
      {{- $id := index $armonik $key -}}
      {{- if not (kindIs "invalid" $id) -}}
        {{- $_ := set $securityContext $key $id -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- with $securityContext -}}
    {{- toYaml . -}}
  {{- end -}}
{{- end -}}
