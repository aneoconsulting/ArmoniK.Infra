{{/*
Pod-template fragments, split one per patchable object: armonik.utils.patch parses what it patches,
and printed text cannot be patched.

Each takes the partition context built in deployment.yaml:
  root, name, partition, agentConf, workerConf, agentImage, workerImage, fluentBit, fluentBitImage
*/}}

{{/* Polling agent container, before agent.containerPatch. */}}
{{- define "armonik.compute.container.agent" -}}
{{- $agent := .partition.agent -}}
name: agent
image: {{ .agentImage.fullname | quote }}
imagePullPolicy: {{ .agentImage.pullPolicy | quote }}
{{- with $agent.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
securityContext:
  {{- toYaml $agent.securityContext | nindent 2 }}
ports:
  - name: {{ $agent.ports.name | quote }}
    containerPort: {{ $agent.ports.containerPort }}
    protocol: TCP
{{- with $agent.readinessProbe }}
readinessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $agent.livenessProbe }}
livenessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $agent.startupProbe }}
startupProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
env:
  {{- include "armonik.conf.generateEnv" .agentConf | nindent 2 }}
  {{- with $agent.extraEnv }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
envFrom:
  {{- include "armonik.conf.generateEnvFrom" .agentConf | nindent 2 }}
  {{- with $agent.extraEnvFrom }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
volumeMounts:
  {{- include "armonik.conf.generateVolumeMounts" .agentConf | nindent 2 }}
  - name: cache-volume
    mountPath: /cache
    mountPropagation: None
  {{- with $agent.extraVolumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}


{{/* Worker (user code) container, before worker.containerPatch. Never gets the core conf layer. */}}
{{- define "armonik.compute.container.worker" -}}
{{- $worker := .partition.worker -}}
name: worker
image: {{ .workerImage.fullname | quote }}
imagePullPolicy: {{ .workerImage.pullPolicy | quote }}
{{- with $worker.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $worker.livenessProbe }}
livenessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $worker.startupProbe }}
startupProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", {{ .root.Values.preStopWaitScript }}]
env:
  {{- include "armonik.conf.generateEnv" .workerConf | nindent 2 }}
  {{- with $worker.extraEnv }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
envFrom:
  {{- include "armonik.conf.generateEnvFrom" .workerConf | nindent 2 }}
  {{- with $worker.extraEnvFrom }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
volumeMounts:
  {{- include "armonik.conf.generateVolumeMounts" .workerConf | nindent 2 }}
  - name: cache-volume
    mountPath: /cache
    mountPropagation: None
  {{- with $worker.extraVolumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}


{{/* Fluent-bit sidecar, rendered only when fluentBit.isDaemonSet is false. */}}
{{- define "armonik.compute.container.fluentBit" -}}
name: fluent-bit
image: {{ .fluentBitImage.fullname | quote }}
imagePullPolicy: {{ .fluentBitImage.pullPolicy | quote }}
envFrom:
  - configMapRef:
      name: {{ .fluentBit.configMapName | quote }}
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", {{ .root.Values.preStopWaitScript }}]
volumeMounts:
  - name: cache-volume
    mountPath: /cache
    mountPropagation: None
  - name: varlog
    mountPath: /var/log
    readOnly: true
  - name: varlibdockercontainers
    mountPath: /var/lib/docker/containers
    readOnly: true
  - name: runlogjournal
    mountPath: /run/log/journal
    readOnly: true
  - name: dmesg
    mountPath: /var/log/dmesg
    readOnly: true
  - name: fluentbitconfig
    mountPath: /fluent-bit/etc
    readOnly: false
{{- end -}}


{{/* spec.template.spec of a partition Deployment, before podSpecPatch. */}}
{{- define "armonik.compute.podSpec" -}}
{{- $root := .root -}}
{{- $partition := .partition -}}
{{- $fluentBit := .fluentBit -}}
{{- $global := $root.Values.global | default dict -}}
{{- $agent := list (include "armonik.compute.container.agent" .) $partition.agent.containerPatch "agent.containerPatch" | include "armonik.utils.patch" | fromYaml -}}
{{- $worker := list (include "armonik.compute.container.worker" .) $partition.worker.containerPatch "worker.containerPatch" | include "armonik.utils.patch" | fromYaml -}}
{{- $containers := list $agent $worker -}}
{{- if not $fluentBit.isDaemonSet -}}
  {{- $containers = append $containers (include "armonik.compute.container.fluentBit" . | fromYaml) -}}
{{- end -}}
{{/* Extras go last: container 0 is what `kubectl logs` picks by default. */}}
{{- $containers = $partition.extraContainers | default list | concat $containers -}}
{{- with $partition.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $partition.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "armonik.serviceAccountName" $root | quote }}
serviceAccount: {{ include "armonik.serviceAccountName" $root | quote }}
automountServiceAccountToken: true
{{- with $partition.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $partition.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
{{- with $partition.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
terminationGracePeriodSeconds: {{ $partition.terminationGracePeriodSeconds }}
shareProcessNamespace: {{ $root.Values.shareProcessNamespace }}
enableServiceLinks: true
{{- with concat ($partition.imagePullSecrets | default list) ($root.Values.imagePullSecrets | default list) ($global.imagePullSecrets | default list) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
restartPolicy: {{ $root.Values.restartPolicy | quote }}
{{- with $partition.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- $containers | toYaml | nindent 2 }}
volumes:
  {{- include "armonik.conf.generateVolumes" (list .agentConf .workerConf) | nindent 2 }}
  - name: cache-volume
    emptyDir: {}
  {{- if not $fluentBit.isDaemonSet }}
  - name: dmesg
    hostPath:
      path: /var/log/dmesg
      type: ""
  - name: fluentbitconfig
    configMap:
      name: {{ $fluentBit.configMapName | quote }}
      defaultMode: 420
      optional: false
  - name: runlogjournal
    hostPath:
      path: /run/log/journal
      type: ""
  - name: varlibdockercontainers
    hostPath:
      path: /var/lib/docker/containers
      type: ""
  - name: varlog
    hostPath:
      path: /var/log
      type: ""
  {{- end }}
  {{- with $partition.extraVolumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}
