{{/*
sso values, validated, as YAML: `enabled: false` when sso is off, else the values plus publicUrl
without a trailing slash, host (host[:port] of publicUrl), secure (publicUrl is https) and
identityVar (the nginx variable carrying identityClaim from the auth subrequest). Takes the root.
*/}}
{{- define "armonik.ingress.sso" -}}
  {{- $sso := .Values.sso | default dict -}}
  {{- if not $sso.enabled -}}
enabled: false
  {{- else -}}
    {{- /* The default HTTPRoute matches content-type application/grpc exactly, so grpc+proto and
           grpc+json reach the web port, and a Gateway terminating TLS leaves nginx unable to
           verify client certificates on the grpc port. */ -}}
    {{- if or .Values.gateway.enabled .Values.httpRoute.enabled -}}
      {{- fail "sso.enabled is not supported with gateway mode yet: the HTTPRoute routes gRPC by an exact content-type match, so application/grpc+proto reaches the web port, and a Gateway terminating TLS leaves no client certificate for the grpc port to verify. Disable gateway.enabled and httpRoute.enabled." -}}
    {{- end -}}
    {{- $proxy := $sso.oauth2Proxy | default dict -}}
    {{- $image := $proxy.image | default dict -}}
    {{- $required := dict
          "sso.publicUrl" $sso.publicUrl
          "sso.oauth2Proxy.issuerUrl" $proxy.issuerUrl
          "sso.oauth2Proxy.clientId" $proxy.clientId
          "sso.oauth2Proxy.existingSecret" $proxy.existingSecret
          "sso.oauth2Proxy.image.tag" $image.tag -}}
    {{- range $key := keys $required | sortAlpha -}}
      {{- if index $required $key | empty -}}
        {{- printf "%s is required when sso.enabled" $key | fail -}}
      {{- end -}}
    {{- end -}}
    {{- $url := $sso.publicUrl | toString | trimSuffix "/" -}}
    {{- if not (regexMatch "^https?://[A-Za-z0-9.-]+(:[0-9]+)?$" $url) -}}
      {{- printf "sso.publicUrl must be scheme://host[:port] with an http or https scheme and no path, got %q" $sso.publicUrl | fail -}}
    {{- end -}}
    {{- if not (regexMatch "^https?://[^ ]+$" ($proxy.issuerUrl | toString)) -}}
      {{- printf "sso.oauth2Proxy.issuerUrl must be an http or https URL, got %q" $proxy.issuerUrl | fail -}}
    {{- end -}}
    {{- $version := regexFind "^v?[0-9]+\\.[0-9]+\\.[0-9]+" ($image.tag | toString) | trimPrefix "v" -}}
    {{- if not $version -}}
      {{- printf "sso.oauth2Proxy.image.tag must be an exact version tag such as v7.15.5, got %q" $image.tag | fail -}}
    {{- end -}}
    {{- if not (semverCompare ">=7.15.2" $version) -}}
      {{- printf "sso.oauth2Proxy.image.tag %q is older than v7.15.2, which fixes CVE-2026-34457" $image.tag | fail -}}
    {{- end -}}
    {{- $mode := $sso.identityMode | default "" | toString -}}
    {{- if not (has $mode (list "user" "group")) -}}
      {{- printf "sso.identityMode must be user or group, got %q" $mode | fail -}}
    {{- end -}}
    {{- $vars := dict
          "email" "$upstream_http_x_auth_request_email"
          "preferred_username" "$upstream_http_x_auth_request_preferred_username"
          "user" "$upstream_http_x_auth_request_user" -}}
    {{- $claim := $sso.identityClaim | default "" | toString -}}
    {{- if not (hasKey $vars $claim) -}}
      {{- printf "sso.identityClaim must be email, preferred_username or user, got %q" $claim | fail -}}
    {{- end -}}
    {{- if $sso.fingerprint | empty -}}
      {{- fail "sso.fingerprint must be non-empty: ArmoniK Core rejects a request without a fingerprint header" -}}
    {{- end -}}
    {{- /* These land inside quoted nginx strings and header values. */ -}}
    {{- $safe := "^[A-Za-z0-9._:@+=/-]*$" -}}
    {{- $literals := dict "sso.fingerprint" $sso.fingerprint "sso.cnPrefix" $sso.cnPrefix "sso.groupCnPrefix" $sso.groupCnPrefix -}}
    {{- range $key := keys $literals | sortAlpha -}}
      {{- $value := index $literals $key | default "" | toString -}}
      {{- if not (regexMatch $safe $value) -}}
        {{- printf "%s may only hold letters, digits and ._:@+=/-, got %q" $key $value | fail -}}
      {{- end -}}
    {{- end -}}
    {{- if eq $mode "group" -}}
      {{- if not $sso.groupMapping -}}
        {{- fail "sso.groupMapping must list at least one {group, cn} with sso.identityMode=group" -}}
      {{- end -}}
      {{- range $i, $entry := $sso.groupMapping -}}
        {{- $entry = $entry | default dict -}}
        {{- $group := $entry.group | default "" | toString -}}
        {{- $cn := $entry.cn | default "" | toString -}}
        {{- if or (not $group) (not $cn) -}}
          {{- printf "sso.groupMapping[%d] needs a non-empty group and cn" $i | fail -}}
        {{- end -}}
        {{- if regexMatch "[\"\\\\,[:cntrl:]]" $group -}}
          {{- printf "sso.groupMapping[%d].group may not contain a double quote, a backslash, a comma or a control character, got %q" $i $group | fail -}}
        {{- end -}}
        {{- if not (regexMatch $safe $cn) -}}
          {{- printf "sso.groupMapping[%d].cn may only hold letters, digits and ._:@+=/-, got %q" $i $cn | fail -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- $health := $sso.healthPath | default "" | toString -}}
    {{- if or (not (regexMatch "^/[A-Za-z0-9._-]+$" $health)) (regexMatch "(?i)^/(oauth2|admin|static|seq|grafana)$|^/armonik\\." $health) -}}
      {{- printf "sso.healthPath must be a single path segment such as /healthz, outside the routes nginx already serves, got %q" $health | fail -}}
    {{- end -}}
    {{- $duration := "^([0-9]+(\\.[0-9]+)?(ns|us|ms|s|m|h))+$" -}}
    {{- range $key := list "cookieExpire" "cookieRefresh" -}}
      {{- $value := index $proxy $key | toString -}}
      {{- if not (or (eq $value "0") (regexMatch $duration $value)) -}}
        {{- printf "sso.oauth2Proxy.%s must be a duration such as 8h or 30m, or 0, got %q" $key $value | fail -}}
      {{- end -}}
    {{- end -}}
    {{- if kindIs "bool" $proxy.sessionCookieMinimal | not -}}
      {{- printf "sso.oauth2Proxy.sessionCookieMinimal must be true or false, got %v" $proxy.sessionCookieMinimal | fail -}}
    {{- end -}}
    {{- /* oauth2-proxy refuses to start otherwise (pkg/validation/sessions.go). A valid duration
           is zero when it has no non-zero digit. */ -}}
    {{- if and $proxy.sessionCookieMinimal (regexMatch "[1-9]" ($proxy.cookieRefresh | toString)) -}}
      {{- printf "sso.oauth2Proxy.cookieRefresh must be 0 with sso.oauth2Proxy.sessionCookieMinimal, got %q: refreshing needs the OAuth tokens a minimal cookie drops" ($proxy.cookieRefresh | toString) | fail -}}
    {{- end -}}
    {{- range $proxy.extraArgs -}}
      {{- if regexMatch "^--?(ping-user-agent|gcp-healthchecks)(=|$)" (toString .) -}}
        {{- printf "sso.oauth2Proxy.extraArgs: %q is refused, health check User-Agents bypass auth_request (CVE-2026-34457)" (toString .) | fail -}}
      {{- end -}}
    {{- end -}}
    {{- $hc := .Values.healthCheckPolicy | default dict -}}
    {{- if $hc.enabled -}}
      {{- $hcConfig := list $hc "default" "config" | include "armonik.utils.index" | fromYaml | default dict -}}
      {{- if eq ($hcConfig.type | default "TCP") "HTTP" -}}
        {{- $path := list $hcConfig "httpHealthCheck" "requestPath" | include "armonik.utils.index" -}}
        {{- if ne $path $health -}}
          {{- printf "healthCheckPolicy.default.config.httpHealthCheck.requestPath must be sso.healthPath (%s) with sso.enabled, every other path requiring a session, got %q" $health $path | fail -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- $eso := $proxy.externalSecret | default dict -}}
    {{- if $eso.storeName -}}
      {{- $ops := include "armonik.operators" . | fromYaml -}}
      {{- if not $ops.externalSecrets.available -}}
        {{- fail "sso.oauth2Proxy.externalSecret.storeName needs global.armonik.operators.externalSecrets.available" -}}
      {{- end -}}
      {{- range $item := list "clientSecret" "cookieSecret" -}}
        {{- if list $eso $item "key" | include "armonik.utils.index" | empty -}}
          {{- printf "sso.oauth2Proxy.externalSecret.%s.key is required with externalSecret.storeName" $item | fail -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- $cidrs := list $sso "networkPolicy" "idpEgressCidrs" | include "armonik.utils.index" | fromYamlArray | default list -}}
    {{- range $cidrs -}}
      {{- if not (regexMatch "^[0-9A-Fa-f:.]+/[0-9]{1,3}$" (toString .)) -}}
        {{- printf "sso.networkPolicy.idpEgressCidrs: %q is not a CIDR" (toString .) | fail -}}
      {{- end -}}
    {{- end -}}
    {{- if and (list .Values "networkPolicy" "enabled" | include "armonik.utils.index") (empty $cidrs) -}}
      {{- fail "sso.networkPolicy.idpEgressCidrs must list the IdP's CIDRs with networkPolicy.enabled: oauth2-proxy reaches the IdP on TCP 443 from the nginx pod" -}}
    {{- end -}}
    {{- $out := deepCopy $sso -}}
    {{- $_ := set $out "publicUrl" $url -}}
    {{- $_ := regexReplaceAll "^https?://" $url "" | set $out "host" -}}
    {{- $_ := hasPrefix "https://" $url | set $out "secure" -}}
    {{- $_ := index $vars $claim | set $out "identityVar" -}}
    {{- $_ := set $out "idpEgressCidrs" $cidrs -}}
    {{- $out | toYaml -}}
  {{- end -}}
{{- end -}}

{{/*
nginx locations of the web server under SSO: the health path, the oauth2-proxy routes, and the two
targets of a 401: a browser goes to /oauth2/start with its original URI in
X-Auth-Request-Redirect (rd would need URL encoding nginx lacks), a gRPC-web call gets a
trailers-only UNAUTHENTICATED. Takes the server dict.
*/}}
{{- define "armonik.ingress.conf.ssoLocations" -}}
{{- $sso := include "armonik.ingress.sso" .root | fromYaml }}
    location = {{ $sso.healthPath }} {
        auth_request off;
        access_log off;
        default_type text/plain;
        return 200 "ok\n";
    }
    location /oauth2/ {
        auth_request off;
        proxy_pass http://127.0.0.1:4180;
        # Response headers past the 4 KB default: X-Auth-Request-Groups, Set-Cookie
        proxy_buffer_size 64k;
        proxy_buffers 8 64k;
        proxy_busy_buffers_size 128k;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $real_scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Auth-Request-Redirect $request_uri;
    }
    location = /oauth2/auth {
        internal;
        auth_request off;
        proxy_pass http://127.0.0.1:4180;
        # Response headers past the 4 KB default: X-Auth-Request-Groups, Set-Cookie
        proxy_buffer_size 64k;
        proxy_buffers 8 64k;
        proxy_busy_buffers_size 128k;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $real_scheme;
        proxy_set_header X-Original-URI $request_uri;
        # Never the client's: oauth2-proxy trusts these from nginx (GHSA-7x63-xv5r-3p2x)
        proxy_set_header X-Forwarded-Uri $request_uri;
        # Never a health check User-Agent (CVE-2026-34457)
        proxy_set_header User-Agent "nginx-auth-request";
    }
    location @sso_login {
        auth_request off;
        rewrite ^ /oauth2/start? break;
        proxy_pass http://127.0.0.1:4180;
        # Response headers past the 4 KB default: X-Auth-Request-Groups, Set-Cookie
        proxy_buffer_size 64k;
        proxy_buffers 8 64k;
        proxy_busy_buffers_size 128k;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $real_scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Auth-Request-Redirect $request_uri;
    }
    location @grpc_unauthenticated {
        auth_request off;
        # default_type takes no variable: empty, it emits no Content-Type of its own
        default_type "";
        add_header Content-Type $grpc_error_content_type always;
        add_header grpc-status 16 always;
        add_header grpc-message "Unauthenticated" always;
        return 200;
    }
{{- end -}}

{{/*
http-level maps of the SSO identity: $sso_cn, the CN the web server sends, empty when the session
yields none so ArmoniK Core rejects the call, and $grpc_error_content_type mirroring the request's
gRPC flavor. Takes the root.
*/}}
{{- define "armonik.ingress.conf.ssoMaps" -}}
{{- $sso := include "armonik.ingress.sso" . | fromYaml }}
map $http_content_type $grpc_error_content_type {
    default application/grpc;
    ~*^application/grpc-web-text application/grpc-web-text+proto;
    ~*^application/grpc-web application/grpc-web+proto;
}
{{- if eq $sso.identityMode "user" }}
map $sso_identity $sso_cn {
    default "{{ $sso.cnPrefix }}$sso_identity";
    "" "";
}
{{- else }}
map $sso_groups $sso_cn {
    default "";
{{- range $sso.groupMapping }}
    "~(^|,){{ regexQuoteMeta .group }}(,|$)" "{{ $sso.groupCnPrefix }}{{ .cn }}";
{{- end }}
}
{{- end }}
{{- end -}}

{{/*
NOTES lines for SSO, empty without it. Takes the ingress chart's root, so the umbrella passes
.Subcharts.ingress.
*/}}
{{- define "armonik.ingress.sso.notes" -}}
{{- $sso := include "armonik.ingress.sso" . | fromYaml -}}
{{- if $sso.enabled }}
SSO is enabled on the web port (admin GUI, gRPC-web, Grafana, Seq) through oauth2-proxy.
  Redirect URI to declare in the IdP client {{ $sso.oauth2Proxy.clientId | quote }}:
    {{ $sso.publicUrl }}/oauth2/callback
  The Secret {{ $sso.oauth2Proxy.existingSecret | quote }} must hold client-secret and cookie-secret.
  {{- if eq $sso.identityMode "user" }}
  Each user reaches ArmoniK as CN "{{ $sso.cnPrefix }}<{{ $sso.identityClaim }}>". Declare them without a fingerprint:
    control-plane.rbac.userCertificates.<user>.commonName: "{{ $sso.cnPrefix }}<{{ $sso.identityClaim }}>"
  {{- else }}
  Each groupMapping entry reaches ArmoniK as one CN; a user in no mapped group is rejected.
  Declare them without a fingerprint:
    {{- range $sso.groupMapping }}
    control-plane.rbac.userCertificates.<user>.commonName: "{{ $sso.groupCnPrefix }}{{ .cn }}"   (group {{ .group | quote }})
    {{- end }}
  {{- end }}
  {{- if not $sso.oauth2Proxy.sessionCookieMinimal }}
  WARNING: sessionCookieMinimal is off, so the session cookie also carries the OAuth tokens. Past
  4 KB (common with Keycloak or Entra ID) oauth2-proxy splits it in _0/_1, and nginx passes on only
  the first Set-Cookie of a refresh: the session breaks. Keep it on unless the tokens are needed.
  {{- end }}
  {{- if not .Values.mtls.enabled }}
  WARNING: mTLS is off, so the grpc port clears every identity header: SDK and CLI clients cannot
  authenticate. Enable tls and mtls for them, or keep authentication off in the control plane.
  {{- end }}
{{- end }}
{{- end -}}
