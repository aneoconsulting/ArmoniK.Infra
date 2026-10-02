{{/*
Partitions that deploy, as YAML: .Values.partitions minus null entries, a null being a removal from a
lower-precedence values file ({} is a real partition inheriting partitionCommon). The guard and every
per-partition range read this, never .Values.partitions.
*/}}
{{- define "armonik.compute.partitions" -}}
  {{- $live := dict -}}
  {{- range $name, $config := .Values.partitions -}}
    {{- if not (kindIs "invalid" $config) -}}
      {{- $_ := set $live $name $config -}}
    {{- end -}}
  {{- end -}}
  {{- $live | toYaml -}}
{{- end -}}

{{/*
Channel conf shared by agent and worker: unix sockets under the /cache volume, or localhost ports
with socketType tcp. Takes (list <name> <partition>), as do the two helpers below.
*/}}
{{- define "armonik.compute.confHelper" -}}
{{- $partitionName := index . 0 -}}
{{- $partition := index . 1 -}}
env:
  ComputePlane__AgentChannel__SocketType: {{ $partition.socketType | quote }}
  ComputePlane__WorkerChannel__SocketType: {{ $partition.socketType | quote }}
{{- if eq $partition.socketType "tcp" }}
  ComputePlane__AgentChannel__Address: http://localhost:6667
  ComputePlane__WorkerChannel__Address: http://localhost:6666
{{- else }}
  ComputePlane__AgentChannel__Address: /cache/armonik_agent.sock
  ComputePlane__WorkerChannel__Address: /cache/armonik_worker.sock
{{- end }}
{{- end -}}

{{/* Agent-only conf: partition id, message batch, grace delay and worker readiness checks. */}}
{{- define "armonik.compute.agent.confHelper" -}}
{{- $partitionName := index . 0 -}}
{{- $partition := index . 1 -}}
env:
  Amqp__PartitionId: {{ $partitionName | quote }}
  Pollster__PartitionId: {{ $partitionName | quote }}
  ComputePlane__MessageBatchSize: {{ $partition.agent.messageBatchSize | quote }}
  InitWorker__WorkerCheckRetries: {{ $partition.worker.checkRetries | quote }}
  InitWorker__WorkerCheckDelay: {{ $partition.worker.checkDelay | quote }}
  Pollster__GraceDelay: {{ $partition.agent.graceDelay | quote }}
{{- end -}}

{{/* Worker-only conf: none, the hook keeping the worker builder parallel to the agent's. */}}
{{- define "armonik.compute.worker.confHelper" -}}
{{- $partitionName := index . 0 -}}
{{- $partition := index . 1 -}}
{{- end -}}


{{/*
Init Job conf: one-shot database, object storage and queue setup, plus one
InitServices__Partitioning entry per partition.
*/}}
{{- define "armonik.compute.init.confHelper" -}}
env:
  Submitter__DefaultPartition: ""
  InitServices__InitDatabase: "true"
  InitServices__InitObjectStorage: "true"
  InitServices__InitQueue: "true"
  InitServices__StopAfterInit: "true"
  {{- $i := 0 }}
  {{- range $name, $config := include "armonik.compute.partitions" . | fromYaml }}
  InitServices__Partitioning__Partitions__{{ $i }}: {{ dict "ParentPartitionIds" ($config.parentPartitionIds | default list) "PartitionId" $name "PodConfiguration" nil "PodMax" ($config.podMax | default 100) "PodReserved" ($config.podReserved | default 50) "PreemptionPercentage" ($config.preemptionPercentage | default 20) "Priority" ($config.priority | default 1) | toJson | quote }}
  {{- $i = add $i 1 }}
  {{- end }}
{{- end -}}

{{/*
Prometheus ingress on the polling-agent metrics port. The source namespace resolves in
armonik.netpol.rule.prometheusIngress (armonik-common).
*/}}
{{- define "armonik.netpol.computePlane.prometheusIngress" -}}
  {{- list . (.Values.partitionCommon.agent.ports.containerPort | int) .Values.networkPolicy.prometheusPodSelector | include "armonik.netpol.rule.prometheusIngress" -}}
{{- end -}}


{{/* Compute-plane NetworkPolicy spec: Prometheus ingress, DNS egress, plus the extra*Rules. */}}
{{- define "armonik.netpol.computePlane" -}}
podSelector:
  matchLabels:
    {{- include "armonik.selectorLabels" $ | nindent 4 }}

ingress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (dict "armonik.netpol.computePlane.prometheusIngress" . | include "armonik.netpol.mergeRules")
        "extra" .Values.networkPolicy.extraIngressRules
    ) | nindent 2 }}

egress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (list (include "armonik.netpol.dnsRule" dict | fromYaml) | toYaml)
        "extra" .Values.networkPolicy.extraEgressRules
    ) | nindent 2 }}
{{- end -}}
