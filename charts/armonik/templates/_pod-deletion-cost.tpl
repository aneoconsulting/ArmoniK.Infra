{{/* Container. */}}
{{- define "armonik.podDeletionCost.container" -}}
{{- $pdc := .root.Values.podDeletionCost -}}
name: pdc-update
image: {{ .image.fullname | quote }}
imagePullPolicy: {{ .image.pullPolicy | quote }}
env:
  {{- include "armonik.conf.generateEnv" (dict "env" .env) | nindent 2 }}
  {{- with $pdc.extraEnv }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with $pdc.extraEnvFrom }}
envFrom:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $pdc.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $pdc.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $pdc.extraVolumeMounts }}
volumeMounts:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}


{{/* Pod spec. */}}
{{- define "armonik.podDeletionCost.podSpec" -}}
{{- $root := .root -}}
{{- $pdc := $root.Values.podDeletionCost -}}
{{- $global := $root.Values.global | default dict -}}
{{- $container := list (include "armonik.podDeletionCost.container" .) $pdc.containerPatch "podDeletionCost.containerPatch" | include "armonik.utils.patch" | fromYaml -}}
{{- $containers := $pdc.extraContainers | default list | concat (list $container) -}}
{{- with $pdc.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- $containers | toYaml | nindent 2 }}
{{- with $pdc.extraVolumes }}
volumes:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with concat ($pdc.imagePullSecrets | default list) ($global.imagePullSecrets | default list) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ .serviceAccount | quote }}
serviceAccount: {{ .serviceAccount | quote }}
automountServiceAccountToken: true
shareProcessNamespace: false
{{- with $pdc.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $pdc.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $pdc.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $pdc.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
{{- with $pdc.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
enableServiceLinks: true
dnsPolicy: ClusterFirst
{{- end -}}
