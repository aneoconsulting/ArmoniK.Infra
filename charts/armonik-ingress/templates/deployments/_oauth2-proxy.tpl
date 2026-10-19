{{/* oauth2-proxy sidecar of the nginx pod, rendered with sso.enabled. It listens on loopback only,
     so its probes go through nginx's web port, where its ping and ready paths sit under /oauth2/.
     No --ping-user-agent or --gcp-healthchecks: with auth_request they bypass authentication
     (CVE-2026-34457). */}}
{{- define "armonik.ingress.oauth2Proxy.container" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $sso := include "armonik.ingress.sso" $root | fromYaml -}}
{{- $proxy := $sso.oauth2Proxy -}}
{{- $image := list $root "sso.oauth2Proxy.image" $proxy.image | include "armonik.utils.imageConf" | fromYaml -}}
{{- $probe := dict
      "port" (dict "protocol" "http" "root" $root | include "armonik.ingress.containerPort" | int)
      "scheme" ($v.tls.enabled | empty | ternary "HTTP" "HTTPS") -}}
name: oauth2-proxy
image: {{ $image.fullname | quote }}
imagePullPolicy: {{ $image.pullPolicy | quote }}
args:
  - "--provider=oidc"
  - {{ printf "--oidc-issuer-url=%s" $proxy.issuerUrl | quote }}
  - {{ printf "--client-id=%s" $proxy.clientId | quote }}
  - "--http-address=127.0.0.1:4180"
  - "--reverse-proxy=true"
  - "--trusted-proxy-ip=127.0.0.1/32"
  - "--set-xauthrequest=true"
  - "--upstream=static://202"
  - "--skip-provider-button=true"
  - {{ printf "--redirect-url=%s/oauth2/callback" $sso.publicUrl | quote }}
  - {{ printf "--whitelist-domain=%s" $sso.host | quote }}
  - "--code-challenge-method=S256"
  - {{ printf "--scope=%s" $proxy.scopes | quote }}
  - {{ printf "--oidc-groups-claim=%s" $proxy.groupsClaim | quote }}
  {{- range $proxy.allowedGroups }}
  - {{ printf "--allowed-group=%s" . | quote }}
  {{- end }}
  {{- range $proxy.emailDomains }}
  - {{ printf "--email-domain=%s" . | quote }}
  {{- end }}
  - {{ printf "--cookie-secure=%t" $sso.secure | quote }}
  - "--cookie-samesite=lax"
  - {{ printf "--cookie-expire=%s" $proxy.cookieExpire | quote }}
  - {{ printf "--cookie-refresh=%s" ($proxy.cookieRefresh | toString) | quote }}
  - {{ printf "--session-cookie-minimal=%t" $proxy.sessionCookieMinimal | quote }}
  - "--ping-path=/oauth2/ping"
  - "--ready-path=/oauth2/ready"
  - "--silence-ping-logging=true"
  {{- range $proxy.extraArgs }}
  - {{ . | toString | quote }}
  {{- end }}
env:
  - name: OAUTH2_PROXY_CLIENT_SECRET
    valueFrom:
      secretKeyRef:
        name: {{ $proxy.existingSecret | quote }}
        key: client-secret
  - name: OAUTH2_PROXY_COOKIE_SECRET
    valueFrom:
      secretKeyRef:
        name: {{ $proxy.existingSecret | quote }}
        key: cookie-secret
livenessProbe:
  httpGet:
    path: /oauth2/ping
    port: {{ $probe.port }}
    scheme: {{ $probe.scheme }}
  periodSeconds: 10
  failureThreshold: 3
readinessProbe:
  httpGet:
    path: /oauth2/ready
    port: {{ $probe.port }}
    scheme: {{ $probe.scheme }}
  periodSeconds: 10
{{- with $proxy.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
securityContext:
  {{- $proxy.securityContext | default (merge (dict "readOnlyRootFilesystem" true) ($v.securityContext | default dict | deepCopy)) | toYaml | nindent 2 }}
terminationMessagePath: /dev/termination-log
terminationMessagePolicy: File
{{- end -}}
