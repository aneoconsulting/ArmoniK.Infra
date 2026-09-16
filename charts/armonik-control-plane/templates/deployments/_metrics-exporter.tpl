{{/* Pod-template fragments: armonik.utils.patch parses what it patches, so each is a define.
     Scheduling and sizing coalesce over the chart-level values; patches and extras do not. */}}

{{/* Metrics-exporter container; sizing and probes fall back to the chart-level values. */}}
{{- define "armonik.control.metrics.container" -}}
{{- $v := .root.Values -}}
{{- $me := $v.metricsExporter -}}
name: metrics-exporter
image: {{ .image.fullname | quote }}
imagePullPolicy: {{ .image.pullPolicy | quote }}
ports:
  {{- range $me.ports }}
  - name: {{ .name | quote }}
    containerPort: {{ .containerPort }}
    protocol: {{ .protocol | quote }}
  {{- end }}
env:
  {{- include "armonik.conf.generateEnv" .conf | nindent 2 }}
  {{- with $me.extraEnv }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
envFrom:
  {{- include "armonik.conf.generateEnvFrom" .conf | nindent 2 }}
  {{- with $me.extraEnvFrom }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with coalesce $me.resources $v.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $me.livenessProbe $v.livenessProbe }}
livenessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $me.startupProbe $v.startupProbe }}
startupProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
volumeMounts:
  {{- include "armonik.conf.generateVolumeMounts" .conf | nindent 2 }}
  {{- with $me.extraVolumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}


{{/* Metrics-exporter pod spec; scheduling falls back to the chart-level values. */}}
{{- define "armonik.control.metrics.podSpec" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $me := $v.metricsExporter -}}
{{- $global := $v.global | default dict -}}
{{- $container := list (include "armonik.control.metrics.container" .) $me.containerPatch "metricsExporter.containerPatch" | include "armonik.utils.patch" | fromYaml -}}
{{- $containers := $me.extraContainers | default list | concat (list $container) -}}
{{- with $me.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- $containers | toYaml | nindent 2 }}
volumes:
  {{- include "armonik.conf.generateVolumes" (list .conf) | nindent 2 }}
  {{- with $me.extraVolumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with concat ($me.imagePullSecrets | default list) ($v.imagePullSecrets | default list) ($global.imagePullSecrets | default list) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "armonik.serviceAccountName" $root | quote }}
serviceAccount: {{ include "armonik.serviceAccountName" $root | quote }}
automountServiceAccountToken: true
shareProcessNamespace: false
{{- with coalesce $me.nodeSelector $v.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $me.affinity $v.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $me.tolerations $v.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $me.priorityClassName $v.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
enableServiceLinks: true
dnsPolicy: ClusterFirst
{{- end -}}
