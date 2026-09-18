{{/* Pod-template fragments: armonik.utils.patch parses what it patches, so each is a define.
     Scheduling and sizing coalesce over the chart-level values; patches and extras do not.
     No extraContainers: a sidecar that never exits keeps the Job from finishing. */}}

{{/* Init container: the one-shot storage and partition setup, which then exits. */}}
{{- define "armonik.control.init.container" -}}
{{- $v := .root.Values -}}
{{- $init := $v.init -}}
name: init
image: {{ .image.fullname | quote }}
imagePullPolicy: {{ .image.pullPolicy | quote }}
env:
  {{- include "armonik.conf.generateEnv" .conf | nindent 2 }}
  {{- with $init.extraEnv }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
envFrom:
  {{- include "armonik.conf.generateEnvFrom" .conf | nindent 2 }}
  {{- with $init.extraEnvFrom }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
volumeMounts:
  {{- include "armonik.conf.generateVolumeMounts" .conf | nindent 2 }}
  {{- with $init.extraVolumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
terminationMessagePath: /dev/termination-log
terminationMessagePolicy: File
{{- with coalesce $init.resources $v.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}


{{/* Init Job pod spec: restartPolicy OnFailure, and no sidecars so the Job can finish. */}}
{{- define "armonik.control.init.podSpec" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $init := $v.init -}}
{{- $global := $v.global | default dict -}}
{{- $container := list (include "armonik.control.init.container" .) $init.containerPatch "init.containerPatch" | include "armonik.utils.patch" | fromYaml -}}
automountServiceAccountToken: true
{{- with $init.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- list $container | toYaml | nindent 2 }}
volumes:
  {{- include "armonik.conf.generateVolumes" (list .conf) | nindent 2 }}
  {{- with $init.extraVolumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with concat ($init.imagePullSecrets | default list) ($v.imagePullSecrets | default list) ($global.imagePullSecrets | default list) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "armonik.serviceAccountName" $root | quote }}
serviceAccount: {{ include "armonik.serviceAccountName" $root | quote }}
shareProcessNamespace: false
{{- with coalesce $init.nodeSelector $v.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $init.affinity $v.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $init.tolerations $v.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $init.priorityClassName $v.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
enableServiceLinks: true
dnsPolicy: ClusterFirst
restartPolicy: OnFailure
{{- end -}}
