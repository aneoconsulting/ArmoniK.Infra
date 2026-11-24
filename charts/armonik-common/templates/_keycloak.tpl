{{/*
Keycloak served by the ArmoniK ingress, from global.armonik.keycloak, validated: enabled, realm,
clientId, and path, the ingress path Keycloak is served under (its http-relative-path). The issuer of
the realm is <ingress.sso.publicUrl><path>/realms/<realm>. Takes the root.
*/}}
{{- define "armonik.keycloak" -}}
  {{- $keycloak := list .Values "global" "armonik" "keycloak" | include "armonik.utils.index" | fromYaml -}}
  {{- $enabled := $keycloak.enabled -}}
  {{- if not (or (kindIs "invalid" $enabled) (kindIs "bool" $enabled)) -}}
    {{- printf "global.armonik.keycloak.enabled must be true or false, got %v" $enabled | fail -}}
  {{- end -}}
  {{- range $key := list "realm" "clientId" -}}
    {{- $value := index $keycloak $key | default "" | toString -}}
    {{- if and $enabled (not (regexMatch "^[A-Za-z0-9][A-Za-z0-9._-]*$" $value)) -}}
      {{- printf "global.armonik.keycloak.%s must be letters, digits and ._- with keycloak enabled, got %q" $key $value | fail -}}
    {{- end -}}
  {{- end }}
enabled: {{ $enabled | empty | not }}
realm: {{ $keycloak.realm | default "" | quote }}
clientId: {{ $keycloak.clientId | default "" | quote }}
path: /auth
{{- end -}}
