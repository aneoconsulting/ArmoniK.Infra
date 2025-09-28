{{/* Get common conf for agent and worker */}}
{{- define "armonik.compute.CommonConfHelper" -}}
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
{{- define "armonik.compute.AgentConfHelper" -}}
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
{{- define "armonik.compute.WorkerConfHelper" -}}
{{- $partitionName := index . 0 -}}
{{- $partition := index . 1 -}}
{{- end -}}
