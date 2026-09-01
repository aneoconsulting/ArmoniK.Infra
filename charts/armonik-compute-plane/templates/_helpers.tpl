{{/*
Live partitions: .Values.partitions minus null entries, which are removals from a lower-precedence
values file ({} stays, being a real partition inheriting partitionCommon). Single source for "which
partitions deploy": the guard and the Deployment / ScaledObject / init ranges all range over this.

# Usage
{{- $partitions := include "armonik.compute.partitions" . | fromYaml }}
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

{{/* Get common conf for agent and worker */}}
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

{{/* Get conf for agent */}}
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

{{/* Get conf for worker */}}
{{- define "armonik.compute.worker.confHelper" -}}
{{- $partitionName := index . 0 -}}
{{- $partition := index . 1 -}}
{{- end -}}


{{/* ---- partition env var generation ---- */}}
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
  Compute-plane NetworkPolicy configuration.
*/}}
{{- define "armonik.netpol.computePlane" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: compute-plane

policyTypes:
  - Ingress
  - Egress

ingress:
  rules: []
  extraRules:
    {{- .Values.networkPolicy.extraIngressRules | default list | toYaml | nindent 4 }}

egress:
  rules:
    {{- list
        (list "armonik.netpol.dnsRule" dict)
      | include "armonik.netpol.mergeRules"
      | nindent 2
    }}
  extraRules:
    {{- .Values.networkPolicy.extraEgressRules | default list | toYaml | nindent 4 }}
{{- end -}}
