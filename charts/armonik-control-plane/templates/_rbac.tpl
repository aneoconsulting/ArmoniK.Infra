{{/*
An AK Core Role as JSON, for the InitServices__Authentication__Roles__<i> env entries.

  {{- include "armonik.control.rbac.role.format" (list "TaskCounter" (list "Tasks:GetTask" "Tasks:ListTasks")) }}
*/}}
{{- define "armonik.control.rbac.role.format" }}
  {{- $roleName := index . 0 }}
  {{- $permissions := index . 1 }}
  {{- $formattedRole := dict 
    "Name" $roleName
    "Permissions" $permissions
  -}}
  {{- $formattedRole | toJson -}}
{{- end }}

{{/*
An AK Core User as JSON, for the InitServices__Authentication__Users__<i> env entries.

  {{- include "armonik.control.rbac.user.format" (list "admin" (list "Submitter")) }}
*/}}
{{- define "armonik.control.rbac.user.format" }}
  {{- $username := index . 0}}
  {{- $roles := index . 1 }}
  {{- $formattedUser := dict 
    "Name" $username
    "Roles" $roles
  -}}
  {{- $formattedUser | toJson -}}
{{- end }}


{{/*
An AK Core UserCertificate as JSON, for the InitServices__Authentication__UserCertificates__<i>
env entries.

  {{- include "armonik.control.rbac.userCertificate.format" (list "admin" "armonik.admin" "4rm0n1K4dm1n") }}
*/}}
{{- define "armonik.control.rbac.userCertificate.format" }}
  {{- $username := index . 0 }}
  {{- $commonName := index . 1 }}
  {{- $fingerprint := index . 2 }}
  {{- $formattedUserCertificate := dict 
    "User" $username 
    "Cn" $commonName
    "Fingerprint" $fingerprint
  -}}
  {{- $formattedUserCertificate | toJson -}}
{{- end }}


{{/*
The built-in roles, read from the chart's builtin-roles/ folder (YAML or JSON), as YAML.

  {{- include "armonik.control.rbac.builtInRoles" . | fromYaml }}
*/}}
{{- define "armonik.control.rbac.builtInRoles" }}
  {{- $builtInRoles := dict }}
  {{- range $path, $_ := .Files.Glob "builtin-roles/*"}}
    {{- range $role, $permissions := $.Files.Get $path | fromYaml }}
      {{- $_ := merge $builtInRoles (dict $role $permissions) }}
    {{- end }}
  {{- end }}
  {{- $builtInRoles | toYaml }}
{{- end }}
