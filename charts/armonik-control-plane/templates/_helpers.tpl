{{- define "armonik.control.confHelper" }}
{{- $defaultPartition := .Values.defaultPartition }}
{{- $partitionNames := .Values.extraPartitions }}
env:
  {{- if and $defaultPartition (has $defaultPartition $partitionNames) }}
  Submitter__DefaultPartition: {{ $defaultPartition }}
  {{- else if gt (len $partitionNames) 0 }}
  Submitter__DefaultPartition: {{ index $partitionNames 0 }}
  {{- else }}
  Submitter__DefaultPartition: ""
  {{- end }}
  InitServices__InitDatabase: {{ not .Values.init.enabled | quote }}
  InitServices__InitObjectStorage: {{ not .Values.init.enabled | quote }}
  InitServices__InitQueue: {{ not .Values.init.enabled | quote }}
  InitServices__StopAfterInit: "false"
{{- end }}

{{- define "armonik.control.initConfHelper" }}
{{- $defaultPartition := .Values.defaultPartition }}
{{- $partitionNames := .Values.extraPartitions }}
env:
  Submitter__DefaultPartition: ""
  InitServices__InitDatabase: "true"
  InitServices__InitObjectStorage: "true"
  InitServices__InitQueue: "true"
  InitServices__StopAfterInit: "true"
{{- end }}

{{- define "armonik.control.metricsConfHelper" }}
{{- $defaultPartition := .Values.defaultPartition }}
{{- $partitionNames := .Values.extraPartitions }}
env:
  Submitter__DefaultPartition: ""
  InitServices__InitDatabase: "false"
  InitServices__InitObjectStorage: "false"
  InitServices__InitQueue: "false"
  InitServices__StopAfterInit: "false"
{{- end }}
