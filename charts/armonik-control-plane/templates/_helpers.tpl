{{/*
Control-plane conf: authorization (armonik.control.authorizationEnv), and Submitter__DefaultPartition
set to defaultPartition when it is one of extraPartitions, else to an arbitrary one of them (keys is
unordered), else empty.
*/}}
{{- define "armonik.control.confHelper" }}
{{- $defaultPartition := .Values.defaultPartition }}
{{- $partitionNames := .Values.extraPartitions | default dict | keys | default list }}
{{- include "armonik.control.legacyRbacGuard" .Values }}
env:
  {{- include "armonik.control.authorizationEnv" . | nindent 2 }}
  {{- if and $defaultPartition (has $defaultPartition $partitionNames) }}
  Submitter__DefaultPartition: {{ $defaultPartition }}
  {{- else if gt (len $partitionNames) 0 }}
  Submitter__DefaultPartition: {{ index $partitionNames 0 }}
  {{- else }}
  Submitter__DefaultPartition: ""
  {{- end }}
  InitServices__StopAfterInit: "false"
{{- end }}

{{/*
Init conf: one-shot database, object storage and queue setup, one indexed InitServices entry per
partition of extraPartitions, and the authorization the init reconciles with the database (the same
as the control plane's, which validates it at startup).
*/}}
{{- define "armonik.control.init.confHelper" }}
{{- include "armonik.control.legacyRbacGuard" .Values }}
env:
  {{- include "armonik.control.authorizationEnv" . | nindent 2 }}
  Submitter__DefaultPartition: ""
  InitServices__InitDatabase: "true"
  InitServices__InitObjectStorage: "true"
  InitServices__InitQueue: "true"
  InitServices__StopAfterInit: "true"
  {{- $i := 0 }}
  {{- range $name, $config := .Values.extraPartitions }}
  InitServices__Partitioning__Partitions__{{ $i }}: {{ dict "ParentPartitionIds" ($config.parentPartitionIds | default list) "PartitionId" $name "PodConfiguration" nil "PodMax" ($config.podMax | default 100) "PodReserved" ($config.podReserved | default 50) "PreemptionPercentage" ($config.preemptionPercentage | default 20) "Priority" ($config.priority | default 1) | toJson | quote }}
    {{- $i = add $i 1 }}
  {{- end }}
{{- end }}

{{/* Metrics-exporter conf: no default partition, no storage or queue setup. */}}
{{- define "armonik.control.metrics.confHelper" }}
env:
  Submitter__DefaultPartition: ""
  InitServices__InitDatabase: "false"
  InitServices__InitObjectStorage: "false"
  InitServices__InitQueue: "false"
  InitServices__StopAfterInit: "false"
{{- end }}
