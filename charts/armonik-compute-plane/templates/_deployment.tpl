{{/*
Pod-template fragments, one define per patchable object, since armonik.utils.patch parses what it
patches. Each takes the partition context built in deployment.yaml:
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
{{- with $agent.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
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


{{/* Worker (user code) native sidecar, before worker.containerPatch. Never gets the core layer. */}}
{{- define "armonik.compute.container.worker" -}}
{{- $worker := .partition.worker -}}
name: worker
image: {{ .workerImage.fullname | quote }}
imagePullPolicy: {{ .workerImage.pullPolicy | quote }}
{{- with $worker.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $worker.securityContext }}
securityContext:
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
restartPolicy: Always
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


{{/* Fluent-bit native sidecar, rendered only when fluentBit.isDaemonSet is false. */}}
{{- define "armonik.compute.container.fluentBit" -}}
name: fluent-bit
image: {{ .fluentBitImage.fullname | quote }}
imagePullPolicy: {{ .fluentBitImage.pullPolicy | quote }}
envFrom:
  - configMapRef:
      name: {{ .fluentBit.configMapName | quote }}
restartPolicy: Always
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
{{/* The agent starts once the worker sidecar's startup probe passes, so that probe cannot wait on it. */}}
{{- with $worker.startupProbe -}}
  {{- $probe := . -}}
  {{- $agentPorts := list (toString $partition.agent.ports.containerPort) $partition.agent.ports.name -}}
  {{- range $handler := list "httpGet" "tcpSocket" "grpc" -}}
    {{- $port := dig $handler "port" "" $probe | toString -}}
    {{- if $agentPorts | has $port -}}
      {{- printf "worker.startupProbe.%s probes the agent port %s: the worker is a native sidecar, so the agent only starts once that probe passes and the pod deadlocks. Leave it empty and raise agent.startupProbe.failureThreshold for a slow worker." $handler $port | fail -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{/*
The worker probes the agent's /liveness, and the agent latches its first failed liveness check
for good, which a worker still starting triggers. So unless set, the worker's first liveness
check waits out the agent's whole startup budget (Kubernetes defaults for unset fields).
*/}}
{{- with $worker.livenessProbe -}}
  {{- if not (hasKey . "initialDelaySeconds") -}}
    {{- $startup := $agent.startupProbe | default dict -}}
    {{- $budget := mul (coalesce $startup.periodSeconds 10) (coalesce $startup.failureThreshold 3) | add ($startup.initialDelaySeconds | default 0) -}}
    {{- $_ := set . "initialDelaySeconds" $budget -}}
  {{- end -}}
{{- end -}}
{{/*
Native sidecars stop after the agent, in reverse order: the worker outlives the agent draining
its current task, and fluent-bit, first in, ships every other container's logs, the extra init
containers' included.
*/}}
{{- $initContainers := list -}}
{{- if not $fluentBit.isDaemonSet -}}
  {{- $initContainers = append $initContainers (include "armonik.compute.container.fluentBit" . | fromYaml) -}}
{{- end -}}
{{- $initContainers = append ($partition.extraInitContainers | default list | concat $initContainers) $worker -}}
{{/* Extras go last: container 0 is what `kubectl logs` picks by default. */}}
{{- $containers := $partition.extraContainers | default list | concat (list $agent) -}}
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
initContainers: {{- $initContainers | toYaml | nindent 2 }}
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
