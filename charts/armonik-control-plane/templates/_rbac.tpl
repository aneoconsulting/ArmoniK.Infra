{{/*
Role as the JSON ArmoniK Core expects: {"Name", "Permissions"}.

Usage:
  {{- include "armonik.control.rbac.role.format" (list "TaskCounter" (list "Tasks:GetTask" "Submitter:CountTasks")) }}
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
User as the JSON ArmoniK Core expects: {"Name", "Roles"}.

Usage:
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
User certificate as the JSON ArmoniK Core expects: {"User", "Cn", "Fingerprint"}.

Usage:
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


{{/* Built-in roles, as a YAML map of role to permissions, from builtin-roles/* (YAML or JSON files). */}}
{{- define "armonik.control.rbac.builtInRoles" }}
  {{- $builtInRoles := dict }}
  {{- range $path, $_ := .Files.Glob "builtin-roles/*"}}
    {{- range $role, $permissions := $.Files.Get $path | fromYaml }}
      {{- $_ := merge $builtInRoles (dict $role $permissions) }}
    {{- end }}
  {{- end }}
  {{- $builtInRoles | toYaml }}
{{- end }}
