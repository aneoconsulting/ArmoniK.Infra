{{/*
Methods of authorization.authentication, validated: "None", or Xfcc, Token and Proxy separated by
commas, each at most once. Returns the normalized value ("None", or the methods joined by commas in
the order written). Takes .Values.
*/}}
{{- define "armonik.control.authentication" -}}
  {{- $raw := (.authorization | default dict).authentication | default "None" | toString -}}
  {{- $methods := list -}}
  {{- range $method := splitList "," $raw -}}
    {{- $method = trim $method -}}
    {{- if not (has $method (list "Xfcc" "Token" "Proxy" "None")) -}}
      {{- printf "authorization.authentication %q holds %q: use None, or Xfcc, Token and Proxy separated by commas" $raw $method | fail -}}
    {{- end -}}
    {{- if has $method $methods -}}
      {{- printf "authorization.authentication %q repeats %q" $raw $method | fail -}}
    {{- end -}}
    {{- $methods = append $methods $method -}}
  {{- end -}}
  {{- if and (has "None" $methods) (gt (len $methods) 1) -}}
    {{- printf "authorization.authentication %q combines None with a method: None alone allows every request" $raw | fail -}}
  {{- end -}}
  {{- join "," $methods -}}
{{- end -}}

{{/*
Permission sets as a map of name to permissions: the access model sets with accessModelSets, then
authorization.permissionSets, which wins on a name. A null entry removes a set. Takes the root context.
*/}}
{{- define "armonik.control.permissionSets" -}}
  {{- $authorization := .Values.authorization | default dict -}}
  {{- $sets := dict -}}
  {{- if $authorization.accessModelSets -}}
    {{- $sets = .Files.Get "access-model/permission-sets.yaml" | fromYaml -}}
  {{- end -}}
  {{- range $name, $permissions := $authorization.permissionSets -}}
    {{- if kindIs "invalid" $permissions -}}
      {{- $_ := unset $sets $name -}}
    {{- else if not (kindIs "slice" $permissions) -}}
      {{- printf "authorization.permissionSets.%s must be a list of permissions" $name | fail -}}
    {{- else -}}
      {{- $_ := set $sets $name $permissions -}}
    {{- end -}}
  {{- end -}}
  {{- $sets | toYaml -}}
{{- end -}}

{{/*
ArmoniK Core authorization env (Authorization__*, Identity__*), rendered only when authentication
selects a method: with None, Core allows every request and reads none of it. Grants and sets are
indexed in name order, so the render is stable. Takes the root context.
*/}}
{{- define "armonik.control.authorizationEnv" -}}
  {{- $authorization := .Values.authorization | default dict -}}
  {{- $authentication := include "armonik.control.authentication" .Values -}}
  {{- if ne $authentication "None" -}}
    {{- $revision := $authorization.configRevision | default 0 | toString -}}
    {{- if not (regexMatch "^[0-9]+$" $revision) -}}
      {{- printf "authorization.configRevision must be a non-negative integer, got %q" $revision | fail -}}
    {{- end }}
Authorization__Authentication: {{ $authentication | quote }}
Authorization__ConfigRevision: {{ $revision | quote }}
    {{- $i := 0 }}
    {{- range $name, $permissions := include "armonik.control.permissionSets" . | fromYaml }}
Authorization__PermissionSets__{{ $i }}__Name: {{ $name | quote }}
      {{- range $j, $permission := $permissions }}
Authorization__PermissionSets__{{ $i }}__Permissions__{{ $j }}: {{ $permission | toString | quote }}
      {{- end }}
      {{- $i = add1 $i }}
    {{- end }}
    {{- $i = 0 }}
    {{- range $id, $grant := $authorization.grants }}
      {{- if not (kindIs "invalid" $grant) }}
        {{- if not (kindIs "map" $grant) }}
          {{- printf "authorization.grants.%s must be a map with principal, permissionSet and an optional condition" $id | fail }}
        {{- end }}
        {{- range $key := list "principal" "permissionSet" }}
          {{- if not (index $grant $key) }}
            {{- printf "authorization.grants.%s.%s is required" $id $key | fail }}
          {{- end }}
        {{- end }}
Authorization__Grants__{{ $i }}__Id: {{ $id | quote }}
Authorization__Grants__{{ $i }}__Principal: {{ $grant.principal | toString | quote }}
Authorization__Grants__{{ $i }}__PermissionSet: {{ $grant.permissionSet | toString | quote }}
        {{- if $grant.condition }}
Authorization__Grants__{{ $i }}__Condition: {{ $grant.condition | toString | quote }}
        {{- end }}
        {{- $i = add1 $i }}
      {{- end }}
    {{- end }}
    {{- range $key, $value := $authorization.identity }}
      {{- if not (kindIs "invalid" $value) }}
Identity__{{ $key }}: {{ $value | toString | quote }}
      {{- end }}
    {{- end }}
  {{- end -}}
{{- end -}}

{{/*
Fails on the rbac values of the removed ArmoniK Core authentication: they would be silently ignored,
leaving every request allowed. Takes .Values.
*/}}
{{- define "armonik.control.legacyRbacGuard" -}}
  {{- if .rbac -}}
    {{- fail "rbac (users, roles, user certificates) is removed with the ArmoniK Core authentication it configured: set authorization instead (methods, grants and permission sets), see the chart values" -}}
  {{- end -}}
{{- end -}}
