{{/*
sso values, validated, as YAML: `enabled: false` when sso is off, else the values plus publicUrl
without a trailing slash, host (host[:port] of publicUrl), hostName (host alone, lowercased),
secure (publicUrl is https) and identityVar (the nginx variable carrying identityClaim from the
auth subrequest). Takes the root.
The single entry point: the armonik.ingress.sso.validate* helpers below fail and render nothing.
*/}}
{{- define "armonik.ingress.sso" -}}
  {{- $sso := .Values.sso | default dict -}}
  {{- if not (or (kindIs "invalid" $sso.enabled) (kindIs "bool" $sso.enabled)) -}}
    {{- printf "sso.enabled must be true or false, got the %s %q" (kindOf $sso.enabled) (toString $sso.enabled) | fail -}}
  {{- end -}}
  {{- if not $sso.enabled -}}
enabled: false
  {{- else -}}
    {{- range list "KubeVersion" "Gateway" "Required" "Urls" "Image" "Identity" "Groups" "Health" "Cookie" "ExtraArgs" "ExternalSecret" "Network" -}}
      {{- include (printf "armonik.ingress.sso.validate%s" .) $ -}}
    {{- end -}}
    {{- $url := $sso.publicUrl | toString | trimSuffix "/" -}}
    {{- $claim := $sso.identityClaim | toString -}}
    {{- $out := deepCopy $sso -}}
    {{- $_ := set $out "publicUrl" $url -}}
    {{- $_ := regexReplaceAll "^https?://" $url "" | set $out "host" -}}
    {{- $_ := regexReplaceAll "^https?://|:[0-9]+$" $url "" | lower | set $out "hostName" -}}
    {{- $_ := hasPrefix "https://" $url | set $out "secure" -}}
    {{- $_ := index (include "armonik.ingress.sso.identityVars" . | fromYaml) $claim | set $out "identityVar" -}}
    {{- $_ := list $sso "networkPolicy" "idpEgressCidrs" | include "armonik.utils.index" | fromYamlArray | default list | set $out "idpEgressCidrs" -}}
    {{- $out | toYaml -}}
  {{- end -}}
{{- end -}}

{{/* nginx variable per identityClaim, read from the auth subrequest. */}}
{{- define "armonik.ingress.sso.identityVars" -}}
email: $upstream_http_x_auth_request_email
preferred_username: $upstream_http_x_auth_request_preferred_username
user: $upstream_http_x_auth_request_user
{{- end -}}

{{/* oauth2-proxy is a native sidecar, on by default from Kubernetes 1.29. Older API servers drop
     its restartPolicy, leaving an init container that never exits and an nginx that never starts. */}}
{{- define "armonik.ingress.sso.validateKubeVersion" -}}
  {{- if semverCompare "<1.29.0-0" .Capabilities.KubeVersion.Version -}}
    {{- printf "sso.enabled needs Kubernetes 1.29 or later, oauth2-proxy running as a native sidecar (an init container with restartPolicy Always), got %s" .Capabilities.KubeVersion.Version | fail -}}
  {{- end -}}
{{- end -}}

{{/* The default HTTPRoute matches content-type application/grpc exactly, so grpc+proto and
     grpc+json reach the web port, and a Gateway terminating TLS leaves nginx unable to verify
     client certificates on the grpc port. */}}
{{- define "armonik.ingress.sso.validateGateway" -}}
  {{- if or .Values.gateway.enabled .Values.httpRoute.enabled -}}
    {{- fail "sso.enabled is not supported with gateway mode yet: the HTTPRoute routes gRPC by an exact content-type match, so application/grpc+proto reaches the web port, and a Gateway terminating TLS leaves no client certificate for the grpc port to verify. Disable gateway.enabled and httpRoute.enabled." -}}
  {{- end -}}
{{- end -}}

{{- define "armonik.ingress.sso.validateRequired" -}}
  {{- $sso := .Values.sso -}}
  {{- $proxy := $sso.oauth2Proxy | default dict -}}
  {{- $required := dict
        "sso.publicUrl" $sso.publicUrl
        "sso.oauth2Proxy.issuerUrl" $proxy.issuerUrl
        "sso.oauth2Proxy.clientId" $proxy.clientId
        "sso.oauth2Proxy.existingSecret" $proxy.existingSecret
        "sso.oauth2Proxy.image.tag" (list $proxy "image" "tag" | include "armonik.utils.index") -}}
  {{- range $key := keys $required | sortAlpha -}}
    {{- if index $required $key | empty -}}
      {{- printf "%s is required when sso.enabled" $key | fail -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "armonik.ingress.sso.validateUrls" -}}
  {{- $sso := .Values.sso -}}
  {{- if not (regexMatch "^https?://[A-Za-z0-9.-]+(:[0-9]+)?$" ($sso.publicUrl | toString | trimSuffix "/")) -}}
    {{- printf "sso.publicUrl must be scheme://host[:port] with an http or https scheme and no path, got %q" $sso.publicUrl | fail -}}
  {{- end -}}
  {{- if not (regexMatch "^https?://[^ ]+$" ($sso.oauth2Proxy.issuerUrl | toString)) -}}
    {{- printf "sso.oauth2Proxy.issuerUrl must be an http or https URL, got %q" $sso.oauth2Proxy.issuerUrl | fail -}}
  {{- end -}}
{{- end -}}

{{- define "armonik.ingress.sso.validateImage" -}}
  {{- $tag := .Values.sso.oauth2Proxy.image.tag | toString -}}
  {{- $version := regexFind "^v?[0-9]+\\.[0-9]+\\.[0-9]+" $tag | trimPrefix "v" -}}
  {{- if not $version -}}
    {{- printf "sso.oauth2Proxy.image.tag must be an exact version tag such as v7.15.5, got %q" $tag | fail -}}
  {{- end -}}
  {{- if not (semverCompare ">=7.15.2" $version) -}}
    {{- printf "sso.oauth2Proxy.image.tag %q is older than v7.15.2, which fixes CVE-2026-34457" $tag | fail -}}
  {{- end -}}
{{- end -}}

{{/* These land inside quoted nginx strings and header values. Takes {key, value}. */}}
{{- define "armonik.ingress.sso.validateLiteral" -}}
  {{- $value := .value | default "" | toString -}}
  {{- if not (regexMatch "^[A-Za-z0-9._:@+=/-]*$" $value) -}}
    {{- printf "%s may only hold letters, digits and ._:@+=/-, got %q" .key $value | fail -}}
  {{- end -}}
{{- end -}}

{{- define "armonik.ingress.sso.validateIdentity" -}}
  {{- $sso := .Values.sso -}}
  {{- $mode := $sso.identityMode | default "" | toString -}}
  {{- if not (has $mode (list "user" "group")) -}}
    {{- printf "sso.identityMode must be user or group, got %q" $mode | fail -}}
  {{- end -}}
  {{- $claim := $sso.identityClaim | default "" | toString -}}
  {{- if not (hasKey (include "armonik.ingress.sso.identityVars" . | fromYaml) $claim) -}}
    {{- printf "sso.identityClaim must be email, preferred_username or user, got %q" $claim | fail -}}
  {{- end -}}
  {{- if $sso.fingerprint | empty -}}
    {{- fail "sso.fingerprint must be non-empty: ArmoniK Core rejects a request without a fingerprint header" -}}
  {{- end -}}
  {{- /* A real certificate fingerprint here would let that certificate match the SSO entries. */ -}}
  {{- if $sso.fingerprint | toString | replace ":" "" | regexMatch "^[0-9A-Fa-f]{32,}$" -}}
    {{- printf "sso.fingerprint must not look like a certificate fingerprint (32 or more hex digits, with or without colons), got %q" ($sso.fingerprint | toString) | fail -}}
  {{- end -}}
  {{- /* The prefixes keep SSO identities apart from certificate CNs. */ -}}
  {{- $prefixes := list "cnPrefix" -}}
  {{- if eq $mode "group" -}}
    {{- $prefixes = append $prefixes "groupCnPrefix" -}}
  {{- end -}}
  {{- range $key := $prefixes -}}
    {{- if index $sso $key | empty -}}
      {{- printf "sso.%s must not be empty: SSO identities would share the certificate CN namespace" $key | fail -}}
    {{- end -}}
  {{- end -}}
  {{- range $key := list "cnPrefix" "fingerprint" "groupCnPrefix" -}}
    {{- dict "key" (printf "sso.%s" $key) "value" (index $sso $key) | include "armonik.ingress.sso.validateLiteral" -}}
  {{- end -}}
{{- end -}}

{{- define "armonik.ingress.sso.validateGroups" -}}
  {{- $sso := .Values.sso -}}
  {{- if eq ($sso.identityMode | toString) "group" -}}
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
      {{- dict "key" (printf "sso.groupMapping[%d].cn" $i) "value" $cn | include "armonik.ingress.sso.validateLiteral" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* healthPath, and an HTTP HealthCheckPolicy probing it: every other path requires a session. */}}
{{- define "armonik.ingress.sso.validateHealth" -}}
  {{- $health := .Values.sso.healthPath | default "" | toString -}}
  {{- if or (not (regexMatch "^/[A-Za-z0-9._-]+$" $health)) (regexMatch "(?i)^/(oauth2|admin|static|seq|grafana)$|^/armonik\\." $health) -}}
    {{- printf "sso.healthPath must be a single path segment such as /healthz, outside the routes nginx already serves, got %q" $health | fail -}}
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
{{- end -}}

{{- define "armonik.ingress.sso.validateCookie" -}}
  {{- $proxy := .Values.sso.oauth2Proxy -}}
  {{- range $key := list "cookieExpire" "cookieRefresh" "cookieCsrfExpire" -}}
    {{- $value := index $proxy $key | toString -}}
    {{- if not (include "armonik.ingress.isDuration" $value) -}}
      {{- printf "sso.oauth2Proxy.%s must be a duration such as 8h or 30m, or 0, got %q" $key $value | fail -}}
    {{- end -}}
  {{- end -}}
  {{- range $key := list "sessionCookieMinimal" "cookieCsrfPerRequest" -}}
    {{- if index $proxy $key | kindIs "bool" | not -}}
      {{- printf "sso.oauth2Proxy.%s must be true or false, got %v" $key (index $proxy $key) | fail -}}
    {{- end -}}
  {{- end -}}
  {{- /* oauth2-proxy refuses to start otherwise (pkg/validation/sessions.go). */ -}}
  {{- if and $proxy.sessionCookieMinimal (not (include "armonik.ingress.durationIsZero" ($proxy.cookieRefresh | toString))) -}}
    {{- printf "sso.oauth2Proxy.cookieRefresh must be 0 with sso.oauth2Proxy.sessionCookieMinimal, got %q: refreshing needs the OAuth tokens a minimal cookie drops" ($proxy.cookieRefresh | toString) | fail -}}
  {{- end -}}
{{- end -}}

{{- define "armonik.ingress.sso.validateExtraArgs" -}}
  {{- range .Values.sso.oauth2Proxy.extraArgs -}}
    {{- if regexMatch "^--?(ping-user-agent|gcp-healthchecks)(=|$)" (toString .) -}}
      {{- printf "sso.oauth2Proxy.extraArgs: %q is refused, health check User-Agents bypass auth_request (CVE-2026-34457)" (toString .) | fail -}}
    {{- end -}}
    {{- if regexMatch "^--?metrics-(secure-)?address(=|$)" (toString .) -}}
      {{- printf "sso.oauth2Proxy.extraArgs: %q is refused, the chart sets the metrics listener its probes use" (toString .) | fail -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "armonik.ingress.sso.validateExternalSecret" -}}
  {{- $eso := .Values.sso.oauth2Proxy.externalSecret | default dict -}}
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
{{- end -}}

{{- define "armonik.ingress.sso.validateNetwork" -}}
  {{- $cidrs := list .Values.sso "networkPolicy" "idpEgressCidrs" | include "armonik.utils.index" | fromYamlArray | default list -}}
  {{- range $cidrs -}}
    {{- if not (toString . | include "armonik.ingress.isCidr") -}}
      {{- printf "sso.networkPolicy.idpEgressCidrs: %q is not a CIDR" (toString .) | fail -}}
    {{- end -}}
  {{- end -}}
  {{- if and (list .Values "networkPolicy" "enabled" | include "armonik.utils.index") (empty $cidrs) -}}
    {{- fail "sso.networkPolicy.idpEgressCidrs must list the IdP's CIDRs with networkPolicy.enabled: oauth2-proxy reaches the IdP on TCP 443 from the nginx pod" -}}
  {{- end -}}
{{- end -}}

{{/* "true" when the string is a Go duration oauth2-proxy accepts (8h, 1h30m, 0.5s) or 0, else empty. */}}
{{- define "armonik.ingress.isDuration" -}}
  {{- regexMatch "^0$|^([0-9]+(\\.[0-9]+)?(ns|us|ms|s|m|h))+$" . | ternary "true" "" -}}
{{- end -}}

{{/* "true" when the string is a zero duration (0, 0s, 0h0m, 0.0s), else empty. */}}
{{- define "armonik.ingress.durationIsZero" -}}
  {{- regexMatch "^0$|^(0+(\\.0+)?(ns|us|ms|s|m|h))+$" . | ternary "true" "" -}}
{{- end -}}

{{/* "true" when the string is an IPv4 CIDR (octets 0-255, prefix 0-32) or an IPv6 one in hex
     notation (prefix 0-128), else empty. */}}
{{- define "armonik.ingress.isCidr" -}}
  {{- $octet := "(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])" -}}
  {{- $ipv4 := printf "^(%s\\.){3}%s/(3[0-2]|[12]?[0-9])$" $octet $octet -}}
  {{- $h := "[0-9A-Fa-f]{1,4}" -}}
  {{- $forms := list
        (printf "(%s:){7}%s" $h $h)
        (printf "(%s:){1,7}:" $h)
        (printf "(%s:){1,6}:%s" $h $h)
        (printf "(%s:){1,5}(:%s){1,2}" $h $h)
        (printf "(%s:){1,4}(:%s){1,3}" $h $h)
        (printf "(%s:){1,3}(:%s){1,4}" $h $h)
        (printf "(%s:){1,2}(:%s){1,5}" $h $h)
        (printf "%s:(:%s){1,6}" $h $h)
        (printf ":((:%s){1,7}|:)" $h) -}}
  {{- $ipv6 := printf "^(%s)/(12[0-8]|1[01][0-9]|[1-9]?[0-9])$" (join "|" $forms) -}}
  {{- or (regexMatch $ipv4 .) (regexMatch $ipv6 .) | ternary "true" "" -}}
{{- end -}}

{{/* Loopback address of the oauth2-proxy sidecar: its --http-address and nginx's proxy_pass. */}}
{{- define "armonik.ingress.oauth2Proxy.address" -}}
127.0.0.1:4180
{{- end -}}

{{/* Pod-IP port of the oauth2-proxy metrics listener, probed by the kubelet; no Service or
     NetworkPolicy rule exposes it. */}}
{{- define "armonik.ingress.oauth2Proxy.metricsPort" -}}
44180
{{- end -}}

{{/*
One nginx location proxying to oauth2-proxy. subrequest: the internal auth_request target, sent no
body and headers oauth2-proxy trusts from nginx; else a browser route carrying the original URI
in X-Auth-Request-Redirect. Takes {match, subrequest, rewrite}.
*/}}
{{- define "armonik.ingress.conf.oauth2ProxyLocation" }}
    location {{ .match }} {
        {{- if .subrequest }}
        internal;
        {{- end }}
        auth_request off;
        {{- with .rewrite }}
        rewrite {{ . }};
        {{- end }}
        proxy_pass http://{{ include "armonik.ingress.oauth2Proxy.address" . }};
        # Response headers past the 4 KB default: X-Auth-Request-Groups, Set-Cookie
        proxy_buffer_size 64k;
        proxy_buffers 8 64k;
        proxy_busy_buffers_size 128k;
        {{- if .subrequest }}
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        {{- end }}
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $real_scheme;
        {{- if .subrequest }}
        proxy_set_header X-Original-URI $request_uri;
        # Never the client's: oauth2-proxy trusts these from nginx (GHSA-7x63-xv5r-3p2x)
        proxy_set_header X-Forwarded-Uri $request_uri;
        # Never a health check User-Agent (CVE-2026-34457)
        proxy_set_header User-Agent "nginx-auth-request";
        {{- else }}
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Auth-Request-Redirect $request_uri;
        {{- end }}
    }
{{- end }}

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
{{- dict "match" "/oauth2/" | include "armonik.ingress.conf.oauth2ProxyLocation" }}
{{- dict "match" "= /oauth2/auth" "subrequest" true | include "armonik.ingress.conf.oauth2ProxyLocation" }}
{{- dict "match" "@sso_login" "rewrite" "^ /oauth2/start? break" | include "armonik.ingress.conf.oauth2ProxyLocation" }}
{{- dict "name" "unauthenticated" "status" 16 "message" "Unauthenticated" | include "armonik.ingress.conf.grpcErrorLocation" }}
{{- dict "name" "permission_denied" "status" 7 "message" "Permission denied" | include "armonik.ingress.conf.grpcErrorLocation" }}
{{- end -}}

{{/*
Named location @grpc_<name> answering a gRPC-web call with a trailers-only error: HTTP 200, the
status in headers, no body, so the client reports the error instead of following a redirect.
Takes {name, status, message}.
*/}}
{{- define "armonik.ingress.conf.grpcErrorLocation" }}
    location @grpc_{{ .name }} {
        auth_request off;
        # default_type takes no variable: empty, it emits no Content-Type of its own
        default_type "";
        add_header Content-Type $grpc_error_content_type always;
        add_header grpc-status {{ .status }} always;
        add_header grpc-message {{ .message | quote }} always;
        return 200;
    }
{{- end }}

{{/*
http-level maps of the SSO identity: $sso_cn, the CN the web server sends, empty when the session
yields none so ArmoniK Core rejects the call, and $grpc_error_content_type mirroring the request's
gRPC flavor. Takes the root.
*/}}
{{- define "armonik.ingress.conf.ssoMaps" -}}
{{- $sso := include "armonik.ingress.sso" . | fromYaml }}
# 1 when a request must first move to the publicUrl host: a login started on another host (an IP)
# sets its CSRF cookie there, and the IdP returns to publicUrl. The port is not compared, cookies
# ignoring it. Exempt: the health path and the sidecar probes, whose Host is the pod IP.
map "$host $uri" $sso_redirect {
    default 1;
    "~^{{ regexQuoteMeta $sso.hostName }} " 0;
    "~ ({{ regexQuoteMeta $sso.healthPath }}|/oauth2/ping|/oauth2/ready)$" 0;
}
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
  Browsers reaching the web port on another host (an IP, another name) are redirected to {{ $sso.publicUrl }}.
  The Secret {{ $sso.oauth2Proxy.existingSecret | quote }} must hold client-secret and cookie-secret.
  {{- if eq $sso.identityMode "user" }}
  Each user reaches ArmoniK as CN "{{ $sso.cnPrefix }}<{{ $sso.identityClaim }}>" and fingerprint {{ $sso.fingerprint | quote }}. Declare them with both:
    control-plane.rbac.userCertificates.<user>.commonName: "{{ $sso.cnPrefix }}<{{ $sso.identityClaim }}>"
    control-plane.rbac.userCertificates.<user>.fingerprint: {{ $sso.fingerprint | quote }}
  {{- else }}
  Each groupMapping entry reaches ArmoniK as one CN, with fingerprint {{ $sso.fingerprint | quote }}; a user in no
  mapped group is rejected. Declare them with both:
    {{- range $sso.groupMapping }}
    control-plane.rbac.userCertificates.<user>.commonName: "{{ $sso.groupCnPrefix }}{{ .cn }}"   (group {{ .group | quote }})
    {{- end }}
    control-plane.rbac.userCertificates.<user>.fingerprint: {{ $sso.fingerprint | quote }}
  {{- end }}
  A client certificate always presents its real fingerprint, so it never matches these entries,
  even one whose CA signed a "{{ $sso.cnPrefix }}..." CN.
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
