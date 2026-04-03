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


{{/* ---- partition env var generation ---- */}}
{{- define "armonik.compute.initConfHelper" -}}
env:
  Submitter__DefaultPartition: ""
  InitServices__InitDatabase: "true"
  InitServices__InitObjectStorage: "true"
  InitServices__InitQueue: "true"
  InitServices__StopAfterInit: "true"
  {{- $i := 0 }}
  {{- range $name, $config := .Values.partitions }}
  InitServices__Partitioning__Partitions__{{ $i }}: {{ dict "ParentPartitionIds" ($config.parentPartitionIds | default list) "PartitionId" $name "PodConfiguration" nil "PodMax" ($config.podMax | default 100) "PodReserved" ($config.podReserved | default 50) "PreemptionPercentage" ($config.preemptionPercentage | default 20) "Priority" ($config.priority | default 1) | toJson | quote }}
  {{- $i = add $i 1 }}
  {{- end }}
{{- end -}}

{{/* ---- build the full init job conf ----
     Uses init.configmaps to reference existing configmaps by name
     (avoids calling armonik.conf.jobs which depends on Bitnami helpers).
     Falls back to armonik.conf.jobs when init.configmaps is empty
     (umbrella chart deployment where all dependencies are present). */}}
{{- define "armonik.compute.initConf" -}}
  {{- if .Values.init.configmaps -}}
    {{- $partitionConf := include "armonik.compute.initConfHelper" . | fromYaml -}}
    {{- $cmConf := dict
          "env" dict
          "envConfigmap" .Values.init.configmaps
          "envFromConfigmap" dict
          "envSecret" list
          "envFromSecret" dict
          "mountConfigmap" dict
          "mountSecret" dict
    -}}
    {{- list $cmConf $partitionConf .Values.init.conf | include "armonik.conf.merge" -}}
  {{- else -}}
    {{- list
          (include "armonik.conf.jobs" . | fromYaml)
          (include "armonik.compute.initConfHelper" . | fromYaml)
          .Values.conf
          .Values.init.conf
        | include "armonik.conf.merge"
    -}}
  {{- end -}}
{{- end -}}
