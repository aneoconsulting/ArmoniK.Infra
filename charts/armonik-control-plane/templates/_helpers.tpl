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
  {{- $i = 0 }} {{/* Necessary ? */}}
  {{- range $user, $roles := .Values.rbac.users }}
  InitServices__Authentication__Users__{{ $i }}: {{ include "armonik.control.rbac.user.format" (list $user $roles) | quote }}
      {{- $i = add $i 1 }}
    {{- end }}
  {{- $i = 0 }} {{/* Necessary ? */}}
  {{- range $user, $certData := .Values.rbac.userCertificates }}
    {{- $commonName := $certData.commonName }}
    {{- $fingerprint := $certData.fingerprint }}
  InitServices__Authentication__UserCertificates__{{ $i }}: {{ include "armonik.control.rbac.userCertificate.format" (list $user $commonName $fingerprint) | quote }}
    {{- $i = add $i 1 }}
  {{- end }}
{{- end }}

{{- define "armonik.control.metrics.confHelper" }}
env:
  Submitter__DefaultPartition: ""
  InitServices__InitDatabase: "false"
  InitServices__InitObjectStorage: "false"
  InitServices__InitQueue: "false"
  InitServices__StopAfterInit: "false"
{{- end }}
