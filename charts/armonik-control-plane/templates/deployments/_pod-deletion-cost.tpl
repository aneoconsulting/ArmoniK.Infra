{{/* Container. */}}
{{- define "armonik.control.podDeletionCost.container" -}}
{{- $v := .root.Values -}}
{{- $pdc := $v.podDeletionCost -}}
name: pdc-update
image: {{ .image.fullname | quote }}
imagePullPolicy: {{ .image.pullPolicy | quote }}
env:
  {{- include "armonik.conf.generateEnv" .conf | nindent 2 }}
  {{- with $pdc.extraEnv }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
envFrom:
  {{- include "armonik.conf.generateEnvFrom" .conf | nindent 2 }}
  {{- with $pdc.extraEnvFrom }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with coalesce $pdc.resources $v.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $pdc.securityContext $v.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $pdc.extraVolumeMounts }}
volumeMounts:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}


{{/* Pod spec. */}}
{{- define "armonik.control.podDeletionCost.podSpec" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $pdc := $v.podDeletionCost -}}
{{- $global := $v.global | default dict -}}
{{- $container := list (include "armonik.control.podDeletionCost.container" .) $pdc.containerPatch "podDeletionCost.containerPatch" | include "armonik.utils.patch" | fromYaml -}}
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
{{- with list $pdc.imagePullSecrets $v.imagePullSecrets $global.imagePullSecrets | include "armonik.imagePullSecrets" }}
imagePullSecrets: {{- . | nindent 2 }}
{{- end }}
serviceAccountName: {{ .serviceAccount | quote }}
serviceAccount: {{ .serviceAccount | quote }}
automountServiceAccountToken: true
shareProcessNamespace: false
{{- with coalesce $pdc.nodeSelector $v.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $pdc.affinity $v.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $pdc.tolerations $v.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $pdc.priorityClassName $v.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
{{- with coalesce $pdc.podSecurityContext $v.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
enableServiceLinks: true
dnsPolicy: ClusterFirst
{{- end -}}
