{{/*
Returns AK Core-compliant Json representation of an AK Role object.

Usage:
  {{- include "armonik.control.rbac.role.format" (list <roleName> <permissions>) }}

Schema: 
  roleName: string
  permissions: list of string
  
Example:
  {{- include "armonik.control.rbac.role.format" (list "TaskCounter" (list "Tasks:GetTask" "Tasks:ListTasks" "Submitter:CountTasks") ) }}
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
Returns AK Core-compliant Json representation of an AK User object.

Usage:
  {{- include "armonik.control.rbac.user.format" (list <username> <roles>) }}

Schema: 
  username: string
  roles: list of string
  
Example:
  {{- include "armonik.control.rbac.user.format" (list "admin" (list "Submitter") ) }}
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
Returns AK Core-compliant Json representation of an AK UserCertificate object.

Usage:
  {{- include "armonik.control.rbac.userCertificate.format" (list <username> <commonName> <fingerprint>) }}

Schema: 
  username: string
  commonName: string
  fingerprint: string

Example:
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
Returns built-in roles defined under the "builtin-roles" folder as YAML.
Files under "builtin-roles" can be either YAML or JSON

Usage:
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