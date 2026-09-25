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
{{- with $v.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
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
{{- with concat ($v.imagePullSecrets | default list) ($global.imagePullSecrets | default list) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
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
