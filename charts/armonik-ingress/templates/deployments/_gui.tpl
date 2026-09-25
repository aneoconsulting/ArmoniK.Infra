{{/* Pod-template fragments: armonik.utils.patch parses what it patches, so each is a define.
     Scheduling, sizing and securityContexts coalesce over the chart-level values; patches and extras do not. */}}

{{/* Admin GUI container; sizing and probes fall back to the chart-level values. */}}
{{- define "armonik.ingress.gui.container" -}}
{{- $v := .root.Values -}}
{{- $gui := $v.gui -}}
name: gui
image: {{ .image.fullname | quote }}
imagePullPolicy: {{ .image.pullPolicy | quote }}
ports:
  {{- range $gui.ports }}
  - name: {{ .name | quote }}
    containerPort: {{ .containerPort }}
    protocol: TCP
  {{- end }}
terminationMessagePath: /dev/termination-log
terminationMessagePolicy: File
{{- with coalesce $gui.resources $v.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $gui.livenessProbe $v.livenessProbe }}
livenessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $gui.startupProbe $v.startupProbe }}
startupProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $gui.readinessProbe $v.readinessProbe }}
readinessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $gui.securityContext $v.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $gui.extraEnv }}
env:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $gui.extraEnvFrom }}
envFrom:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $gui.extraVolumeMounts }}
volumeMounts:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}


{{/* GUI pod spec; scheduling falls back to the chart-level values. */}}
{{- define "armonik.ingress.gui.podSpec" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $gui := $v.gui -}}
{{- $global := $v.global | default dict -}}
{{- $container := list (include "armonik.ingress.gui.container" .) $gui.containerPatch "gui.containerPatch" | include "armonik.utils.patch" | fromYaml -}}
{{- $containers := $gui.extraContainers | default list | concat (list $container) -}}
automountServiceAccountToken: true
{{- with $gui.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- $containers | toYaml | nindent 2 }}
dnsPolicy: ClusterFirst
shareProcessNamespace: false
{{- with concat ($gui.imagePullSecrets | default list) ($v.imagePullSecrets | default list) ($global.imagePullSecrets | default list) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $gui.nodeSelector $v.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $gui.affinity $v.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $gui.tolerations $v.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $gui.priorityClassName $v.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
{{- with coalesce $gui.podSecurityContext $v.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
enableServiceLinks: true
{{- with $gui.extraVolumes }}
volumes:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
