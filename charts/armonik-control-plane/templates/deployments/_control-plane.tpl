{{/* Pod-template fragments: armonik.utils.patch parses what it patches, so each is a define. */}}

{{/* Control-plane API container: conf-layer env and mounts, probes, and the extra* additions. */}}
{{- define "armonik.control.container" -}}
{{- $v := .root.Values -}}
name: control-plane
image: {{ .image.fullname | quote }}
imagePullPolicy: {{ .image.pullPolicy | quote }}
ports:
  {{- range $v.ports }}
  - name: {{ .name | quote }}
    containerPort: {{ .containerPort }}
    protocol: {{ .protocol | quote }}
  {{- end }}
env:
  {{- include "armonik.conf.generateEnv" .conf | nindent 2 }}
  {{- with $v.extraEnv }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
envFrom:
  {{- include "armonik.conf.generateEnvFrom" .conf | nindent 2 }}
  {{- with $v.extraEnvFrom }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with $v.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.livenessProbe }}
livenessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.startupProbe }}
startupProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with list $v.securityContext .root | include "armonik.securityContext" }}
securityContext: {{- . | nindent 2 }}
{{- end }}
volumeMounts:
  {{- include "armonik.conf.generateVolumeMounts" .conf | nindent 2 }}
  {{- with $v.extraVolumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}


{{/* Control-plane pod spec: the patched container, its conf volumes, and scheduling. */}}
{{- define "armonik.control.podSpec" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $global := $v.global | default dict -}}
{{- $deployment := $v.deployment | default dict -}}
{{- $container := list (include "armonik.control.container" .) $v.containerPatch "containerPatch" | include "armonik.utils.patch" | fromYaml -}}
{{- $containers := $v.extraContainers | default list | concat (list $container) -}}
{{- with $v.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- $containers | toYaml | nindent 2 }}
volumes:
  {{- include "armonik.conf.generateVolumes" (list .conf) | nindent 2 }}
  {{- with $v.extraVolumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with list $deployment.imagePullSecrets $v.imagePullSecrets $global.imagePullSecrets | include "armonik.imagePullSecrets" }}
imagePullSecrets: {{- . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "armonik.serviceAccountName" $root | quote }}
serviceAccount: {{ include "armonik.serviceAccountName" $root | quote }}
automountServiceAccountToken: true
shareProcessNamespace: false
{{- with $v.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
{{- with $v.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
enableServiceLinks: true
{{- end -}}


{{/*
Control-plane Deployment, shared by the main one and the events one. Takes dict "root" (the chart
context, or the fabricated one of the events Deployment), "component", "name", "conf" (resolved), and
"replicas" (nil leaves the count to the ScaledObject). Labels, annotations and the pod spec come from
.root.Values.
*/}}
{{- define "armonik.control.deployment" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $image := include "armonik.control.imageConf" $root | fromYaml -}}
{{- $ctx := dict "root" $root "conf" .conf "image" $image -}}
{{- $podSpec := list (include "armonik.control.podSpec" $ctx) $v.podSpecPatch "podSpecPatch" | include "armonik.utils.patch" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .name | quote }}
  namespace: {{ include "armonik.namespace" $root }}
  labels:
    app.kubernetes.io/component: {{ .component | quote }}
    {{- include "armonik.labels" (list $root $image) | nindent 4 }}
    {{- with $v.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $v.annotations}}
  annotations:
  {{- range $key, $value := . }}
    {{ $key }}: {{ $value }}
  {{- end }}
  {{- end }}
spec:
  progressDeadlineSeconds: 600
  {{- if not (kindIs "invalid" .replicas) }}
  replicas: {{ .replicas }}
  {{- end }}
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app.kubernetes.io/component: {{ .component | quote }}
      {{- include "armonik.selectorLabels" $root | nindent 6 }}
  template:
    metadata:
      labels:
        app.kubernetes.io/component: {{ .component | quote }}
        armonik.fr/deployment: {{ include "armonik.conf.source" $root | quote }}
        {{- include "armonik.labels" (list $root $image) | nindent 8 }}
        {{- with $v.labels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with $v.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with $v.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec: {{- $podSpec | nindent 6 }}
{{- end -}}


{{/* Name of the events Deployment and of its Service. */}}
{{- define "armonik.control.events.name" -}}
  {{- include "armonik.fullname" . | printf "%s-events" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
