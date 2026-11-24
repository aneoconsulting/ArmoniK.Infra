{{/* oauth2-proxy native sidecar of the nginx pod (an init container restarted Always), rendered
     with sso.enabled: nginx starts once its startupProbe passes, and it stops after nginx.
     It serves on loopback only. The startup and liveness probes hit the metrics listener, which
     serves /metrics on every path and nothing else, so they neither wait for nginx (it starts
     after them) nor restart oauth2-proxy when only nginx fails. The readiness probe goes through
     nginx's web port to the real listener; it gates no start and restarts nothing.
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
{{- $metricsPort := include "armonik.ingress.oauth2Proxy.metricsPort" . | int -}}
name: oauth2-proxy
image: {{ $image.fullname | quote }}
imagePullPolicy: {{ $image.pullPolicy | quote }}
restartPolicy: Always
ports:
  - name: sso-metrics
    containerPort: {{ $metricsPort }}
    protocol: TCP
args:
  - "--provider=oidc"
  - {{ printf "--oidc-issuer-url=%s" $proxy.issuerUrl | quote }}
  - {{ printf "--client-id=%s" $proxy.clientId | quote }}
  - {{ include "armonik.ingress.oauth2Proxy.address" . | printf "--http-address=%s" | quote }}
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
  - {{ printf "--cookie-csrf-per-request=%t" $proxy.cookieCsrfPerRequest | quote }}
  - {{ printf "--cookie-csrf-expire=%s" ($proxy.cookieCsrfExpire | toString) | quote }}
  - "--ping-path=/oauth2/ping"
  - "--ready-path=/oauth2/ready"
  - "--silence-ping-logging=true"
  - {{ printf "--metrics-address=:%d" $metricsPort | quote }}
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
startupProbe:
  httpGet:
    path: /metrics
    port: sso-metrics
  periodSeconds: 2
  failureThreshold: 30
livenessProbe:
  httpGet:
    path: /metrics
    port: sso-metrics
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
