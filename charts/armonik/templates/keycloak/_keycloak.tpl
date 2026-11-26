{{/*
Name of the Keycloak CR, its StatefulSet and its Service, release-derived.
*/}}
{{- define "armonik.keycloak.name" -}}
  {{- printf "%s-keycloak" .Release.Name | trunc 40 | trimSuffix "-" -}}
{{- end -}}

{{/*
In-cluster URL of the Keycloak Service, which the ingress serves under the Keycloak path.
*/}}
{{- define "armonik.keycloak.serviceUrl" -}}
  {{- printf "http://%s.%s.svc.%s:8080" (include "armonik.keycloak.name" .) (include "armonik.namespace" .) (include "armonik.clusterDomain" .) -}}
{{- end -}}

{{/* Environment variable of the client secret in the realm import, a Keycloak placeholder. */}}
{{- define "armonik.keycloak.clientSecretEnv" -}}
ARMONIK_KEYCLOAK_CLIENT_SECRET
{{- end -}}

{{/*
Realm representation imported at every pod start, as JSON: the realm, its groups, and the client of
the ingress SSO, with an audience mapper (oauth2-proxy checks the audience) and a groups mapper
writing the group names to the groups claim of every token. keycloak.realm is merged over it last.
Takes the root.
*/}}
{{- define "armonik.keycloak.realm" -}}
  {{- $keycloak := include "armonik.keycloak" . | fromYaml -}}
  {{- $values := .Values.keycloak | default dict -}}
  {{- $sso := include "armonik.ingress.sso" .Subcharts.ingress | fromYaml -}}
  {{- $publicUrl := $sso.publicUrl -}}
  {{- $groups := list -}}
  {{- range $values.groups -}}
    {{- $groups = dict "name" (toString .) | append $groups -}}
  {{- end -}}
  {{- $mapperClaims := dict "access.token.claim" "true" "id.token.claim" "true" "userinfo.token.claim" "true" -}}
  {{- $client := dict
        "clientId" $keycloak.clientId
        "name" "ArmoniK"
        "enabled" true
        "protocol" "openid-connect"
        "publicClient" false
        "secret" (include "armonik.keycloak.clientSecretEnv" . | printf "${%s}")
        "standardFlowEnabled" true
        "directAccessGrantsEnabled" ($values.directAccessGrants | empty | not)
        "redirectUris" (list (printf "%s/oauth2/callback" $publicUrl))
        "webOrigins" (list $publicUrl)
        "attributes" (dict "pkce.code.challenge.method" "S256" "post.logout.redirect.uris" (printf "%s/*" $publicUrl))
        "protocolMappers" (list
          (dict "name" "audience" "protocol" "openid-connect" "protocolMapper" "oidc-audience-mapper"
                "config" (dict "included.client.audience" $keycloak.clientId "access.token.claim" "true" "id.token.claim" "true"))
          (dict "name" "groups" "protocol" "openid-connect" "protocolMapper" "oidc-group-membership-mapper"
                "config" (merge (dict "claim.name" (list $sso.oauth2Proxy "groupsClaim" | include "armonik.utils.index" | default "groups") "full.path" "false") $mapperClaims))) -}}
  {{- $realm := dict
        "realm" $keycloak.realm
        "enabled" true
        "sslRequired" "external"
        "groups" $groups
        "clients" (list $client) -}}
  {{- mergeOverwrite $realm (deepCopy ($values.realm | default dict)) | toJson -}}
{{- end -}}
