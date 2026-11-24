{{/*
Component images, the armonik.utils.imageConf results: each is resolved once here so the workload, its
version label and the resources dedicated to it cannot drift apart. The init Job and the
metrics-exporter fall back on the control-plane image.
*/}}
{{- define "armonik.control.imageConf" -}}
{{- list . "image" .Values.image | include "armonik.utils.imageConf" }}
{{- end }}

{{- define "armonik.control.metricsExporter.imageConf" -}}
{{- list . "metricsExporter.image" .Values.metricsExporter.image .Values.image | include "armonik.utils.imageConf" }}
{{- end }}

{{- define "armonik.control.init.imageConf" -}}
{{- list . "init.image" .Values.init.image .Values.image | include "armonik.utils.imageConf" }}
{{- end }}

{{- define "armonik.control.podDeletionCost.imageConf" -}}
{{- list . "podDeletionCost.image" (.Values.podDeletionCost | default dict).image | include "armonik.utils.imageConf" }}
{{- end }}

{{/*
Control-plane conf: auth flags, and Submitter__DefaultPartition set to defaultPartition when it is
one of extraPartitions, else to an arbitrary one of them (keys is unordered), else empty.
Authorization without authentication fails.
*/}}
{{- define "armonik.control.confHelper" }}
{{- $defaultPartition := .Values.defaultPartition }}
{{- $partitionNames := .Values.extraPartitions | default dict | keys | default list }}
env:
  {{- if and (not .Values.rbac.authentication.required) .Values.rbac.authorization.required  -}}
    {{- fail "Authorization requires authentication to be enabled" }}
  {{- end }}
  Authenticator__RequireAuthentication: {{ .Values.rbac.authentication.required }}
  Authenticator__RequireAuthorization: {{ .Values.rbac.authorization.required }}
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
Init conf: one-shot database, object storage and queue setup, then one indexed InitServices entry
per partition of extraPartitions, role, user and user certificate. With createBuiltInRoles, the
built-in roles join rbac.roles, which wins on a name collision.
*/}}
{{- define "armonik.control.init.confHelper" }}
env:
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
  {{- $roles := .Values.rbac.roles | default dict }}
  {{- if .Values.rbac.createBuiltInRoles }}
    {{- $_ := include "armonik.control.rbac.builtInRoles" . | fromYaml | merge $roles -}}
  {{- end }}
  {{- $i := 0 }}
  {{- range $role, $permissions := $roles }}
  InitServices__Authentication__Roles__{{ $i }}: {{ include "armonik.control.rbac.role.format" (list $role $permissions) | quote }}
    {{- $i = add $i 1 }}
  {{- end }}
  {{- $i = 0 }} {{/* Each list is indexed from 0. */}}
  {{- range $user, $roles := .Values.rbac.users }}
  InitServices__Authentication__Users__{{ $i }}: {{ include "armonik.control.rbac.user.format" (list $user $roles) | quote }}
      {{- $i = add $i 1 }}
    {{- end }}
  {{- $i = 0 }} {{/* Each list is indexed from 0. */}}
  {{- range $user, $certData := .Values.rbac.userCertificates }}
    {{- $commonName := $certData.commonName }}
    {{- $fingerprint := $certData.fingerprint }}
  InitServices__Authentication__UserCertificates__{{ $i }}: {{ include "armonik.control.rbac.userCertificate.format" (list $user $commonName $fingerprint) | quote }}
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

{{/*
Events Deployment conf, over armonik.control.confHelper: no database, object storage or queue setup,
so it never races the init over the schema.
*/}}
{{- define "armonik.control.events.confHelper" }}
env:
  InitServices__InitDatabase: "false"
  InitServices__InitObjectStorage: "false"
  InitServices__InitQueue: "false"
{{- end }}
