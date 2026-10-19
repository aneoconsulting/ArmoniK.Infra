{{/*
Name shared by the nginx conf Secret, its ExternalSecret, and the SecretStore with its RBAC.
*/}}
{{- define "armonik.ingress.confName" -}}
  {{- include "armonik.fullname" . | printf "%s-nginx-conf" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
nginx locations proxying /seq/ to $seq_upstream.
*/}}
{{- define "armonik.seq.locations" }}
location = /seq {
    rewrite ^ $scheme://$http_host/seq/ permanent;
}

location /seq/ {
    proxy_set_header Host $http_host;
    proxy_set_header Accept-Encoding "";
    rewrite ^/seq/(.*) /$1 break;
    proxy_pass $seq_upstream$uri$is_args$args;

    sub_filter '<head>' '<head><base href="${real_scheme}://${http_host}/seq/">';
    sub_filter_once on;
    proxy_hide_header content-security-policy;
}
{{- end }}


{{/*
nginx locations proxying /grafana/ to $grafana_upstream.
*/}}
{{- /* Grafana runs with a path-less root_url and never learns its public path, so it is injected
        below and one Grafana serves under any prefix. For a per-cluster Grafana, derive the path
        from the cluster key. */}}
{{- define "armonik.grafana.locations" }}
{{- $grafanaPath := "/grafana" }}
location = {{ $grafanaPath }}{
    rewrite ^ $real_scheme://$http_host{{ $grafanaPath }}/ permanent;
}

location {{ $grafanaPath }}/ {
    proxy_set_header Host $http_host;
    # sub_filter needs an uncompressed body
    proxy_set_header Accept-Encoding "";

    rewrite ^{{ $grafanaPath }}/(.*) /$1 break;

    proxy_pass $grafana_upstream$uri$is_args$args;

    # <base> covers Grafana's relative URLs (assets, API), appSubUrl the absolute ones it
    # builds itself. Literal matches, so both need a path-less root_url: guarded in the
    # umbrella (armonik/templates/validate.yaml). Checked against grafana 11.6.1.
    sub_filter '<base href="/" />' '<base href="{{ $grafanaPath }}/" />';
    sub_filter '"appSubUrl":""' '"appSubUrl":"{{ $grafanaPath }}"';

    sub_filter_once on;
    # Same for Location headers, relative or upstream-absolute.
    proxy_redirect / $real_scheme://$http_host{{ $grafanaPath }}/;
    proxy_redirect $grafana_upstream/ $real_scheme://$http_host{{ $grafanaPath }}/;
}

location {{ $grafanaPath }}/api/live {
    proxy_set_header Host $http_host;

    rewrite ^{{ $grafanaPath }}/(.*) /$1 break;

    proxy_http_version 1.1;

    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;

    proxy_pass $grafana_upstream$uri$is_args$args;
}
{{- end }}

{{/*
nginx configuration: the http-level resolver, maps and upstream once, then one server per port
role. With useEso, an upstream absent from values becomes an ESO template reference to the URLs
Secret key (control-plane, seq, grafana).

Usage:
{{- dict "root" . "useEso" true | include "armonik.conf.render" }}
*/}}
{{- define "armonik.conf.render" -}}
{{- $root := .root -}}
{{- $useEso := .useEso -}}
{{- $mtls := $root.Values.mtls.enabled | default false }}
{{- $cnPattern := include "armonik.ingress.mtlsCnPattern" $root.Values }}
{{- $headers := include "armonik.ingress.identityHeaders" $root.Values | fromYaml }}
{{- $sso := include "armonik.ingress.sso" $root | fromYaml }}
{{- $lbHost := include "armonik.fullname" $root | printf "%s-load-balancer" | trunc 63 | trimSuffix "-" }}
{{- $svcSuffix := printf "%s.svc.%s" (include "armonik.namespace" $root) (include "armonik.clusterDomain" $root) }}
resolver kube-dns.kube-system ipv6=off;

map $http_accept_language $accept_language {
    default en;
    ~*^en en;
}
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
map $http_x_forwarded_proto $real_scheme {
default   $scheme;
https     https;
}

{{- if $mtls }}
map $ssl_client_s_dn $ssl_client_s_dn_cn {
    default "";
    ~CN=(?<CN>[^,/]+) $CN;
}
map "{{ $headers.commonName.var }}|$ssl_client_s_dn_cn" $client_cn {
    default $ssl_client_s_dn_cn;
{{- if $cnPattern }}
    ~^(.+)\|({{ $cnPattern }})$ {{ $headers.commonName.var }};
{{- end }}
}
map "{{ $headers.fingerprint.var }}|$ssl_client_s_dn_cn" $client_fingerprint {
    default $ssl_client_fingerprint;
{{- if $cnPattern }}
    ~^(.+)\|({{ $cnPattern }})$ {{ $headers.fingerprint.var }};
{{- end }}
}
{{- end }}
{{- if $sso.enabled }}
{{ include "armonik.ingress.conf.ssoMaps" $root }}
{{- end }}

upstream armonik {
    zone armonik_zone 32k;
    {{- if $root.Values.loadBalancer.enabled }}
    # gRPC through the multi-cluster load balancer
    server {{ $lbHost }}.{{ $svcSuffix }}:{{ $root.Values.loadBalancer.conf.listenPort }} resolve;
    {{- else if $root.Values.control_plane_url }}
    # External control-plane URL
    server {{ $root.Values.control_plane_url | quote }} resolve;
    {{- else if $useEso }}
    server {{`{{ index . "control-plane" | quote }}`}} resolve;
    {{- end }}
    keepalive 128;
    keepalive_time 8h;
    keepalive_timeout 1h;
}
{{- range list "web" "grpc" }}

{{ dict "root" $root "useEso" $useEso "role" . | include "armonik.ingress.conf.server" }}
{{- end }}
{{- end -}}

{{/*
One nginx server: role web listens on 8080 (8443 with TLS), role grpc on 9080 (9443 with TLS). The
ports follow tls.enabled alone, as nginx terminates TLS whenever it is set; the Service targets
come from armonik.ingress.containerPort. With SSO the web server authenticates through
oauth2-proxy instead of client certificates.

Usage:
{{ dict "root" $root "useEso" $useEso "role" "web" | include "armonik.ingress.conf.server" }}
*/}}
{{- define "armonik.ingress.conf.server" -}}
{{- $root := .root -}}
{{- $tls := $root.Values.tls.enabled | default false }}
{{- $mtls := $root.Values.mtls.enabled | default false }}
{{- $headers := include "armonik.ingress.identityHeaders" $root.Values | fromYaml }}
{{- $ports := index (dict "web" (list 8080 8443) "grpc" (list 9080 9443)) .role }}
{{- if not $ports }}
  {{- printf "armonik.ingress.conf.server: unknown role %q, expected web or grpc" .role | fail }}
{{- end }}
{{- $sso := include "armonik.ingress.sso" $root | fromYaml }}
{{- $ssoWeb := and $sso.enabled (eq .role "web") }}
{{- $port := $tls | empty | ternary (index $ports 0) (index $ports 1) -}}
server {
    # {{ .role }} port
    {{- if $tls }}
    # TLS enabled
    listen {{ $port }} ssl http2;
    listen [::]:{{ $port }} ssl http2;
    {{- if or $root.Values.tls.ssl.certificatePath $root.Values.tls.ssl.keyPath }}
    ssl_certificate     {{ default "/ingress/tls.crt" $root.Values.tls.ssl.certificatePath | quote}};
    ssl_certificate_key {{ default "/ingress/tls.key" $root.Values.tls.ssl.keyPath | quote}};
    {{- else }}
    # TLS enabled but no certificate paths: mount the certificate at /ingress, or set tls.ssl.certificatePath and tls.ssl.keyPath
    {{- end }}
    {{- if and $mtls (not $ssoWeb) }}
    ssl_verify_client on;
    ssl_client_certificate /ingressclient/ca.crt;
    {{- else }}
    ssl_verify_client off;
    proxy_hide_header {{ $headers.commonName.name }};
    proxy_hide_header {{ $headers.fingerprint.name }};
    {{- end }}
    ssl_protocols {{ default "TLSv1.2 TLSv1.3" $root.Values.tls.ssl.protocols }};
    ssl_ciphers {{ default "EECDH+AESGCM:EECDH+AES256" $root.Values.tls.ssl.ciphers }};
    ssl_conf_command Ciphersuites {{ default "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256" $root.Values.tls.ssl.cipherSuites }};
    {{- else }}
    # TLS disabled
    listen {{ $port }};
    listen [::]:{{ $port }};
    http2 on;
    {{- end }}

    sendfile on;
    tcp_nopush on;
    {{- if $ssoWeb }}

    # SSO: every location requires an oauth2-proxy session unless it turns auth_request off
    auth_request /oauth2/auth;
    error_page 401 = @sso_login;
    # Pass on the session cookie oauth2-proxy renews (cookieRefresh)
    auth_request_set $auth_cookie $upstream_http_set_cookie;
    add_header Set-Cookie $auth_cookie;
    {{- end }}
{{ include "armonik.ingress.conf.locations" . }}
}
{{- end -}}

{{/*
The locations of one server, with the server-level directives between them (upstream variables,
buffering). Takes the server's dict. Both roles serve every route, except with SSO: the web server
adds the oauth2-proxy routes, the grpc server keeps the gRPC API alone.
*/}}
{{- define "armonik.ingress.conf.locations" -}}
{{- $root := .root -}}
{{- $useEso := .useEso -}}
{{- $guiHost := include "armonik.fullname" $root | printf "%s-gui" | trunc 63 | trimSuffix "-" }}
{{- $svcSuffix := printf "%s.svc.%s" (include "armonik.namespace" $root) (include "armonik.clusterDomain" $root) }}
{{- $sso := include "armonik.ingress.sso" $root | fromYaml }}
{{- if and $sso.enabled (eq .role "grpc") }}
{{- include "armonik.ingress.conf.apiLocation" . }}
    location / {
        return 404;
    }
{{- else }}
{{- if $sso.enabled }}
{{- include "armonik.ingress.conf.ssoLocations" . }}
{{- end }}
    location = / {
        rewrite ^ $scheme://$http_host/admin/$accept_language/;
    }
    location = /admin {
        rewrite ^ $scheme://$http_host/admin/$accept_language/;
    }
    location = /admin/ {
        rewrite ^ $scheme://$http_host/admin/$accept_language/;
    }
    location = /admin/en {
        rewrite ^ $scheme://$http_host/admin/en/;
    }
    set $admin_app_upstream http://{{ $guiHost }}.{{ $svcSuffix }}:1080;
    location /admin/ {
        proxy_pass $admin_app_upstream$uri$is_args$args;
    }
{{- include "armonik.ingress.conf.apiLocation" . }}

    location /static/ {
        alias /static/;
    }

    proxy_buffering off;
    proxy_request_buffering off;
    {{- if $root.Values.seq_url }}
    set $seq_upstream {{ $root.Values.seq_url | quote }};
    {{ include "armonik.seq.locations" $root }}
    {{- else if $useEso }}
    {{`{{- if index . "seq" }}`}}
    set $seq_upstream {{`{{ index . "seq" | quote }}`}};
    {{ include "armonik.seq.locations" $root }}
    {{`{{- end }}`}}
    {{- end }}

    {{- if $root.Values.grafana_url }}
    set $grafana_upstream {{ $root.Values.grafana_url | quote }};
    {{ include "armonik.grafana.locations" $root }}
    {{- else if $useEso }}
    {{`{{- if index . "grafana" }}`}}
    set $grafana_upstream {{`{{ index . "grafana" | quote }}`}};
    {{ include "armonik.grafana.locations" $root }}
    {{`{{- end }}`}}
    {{- end }}
{{- end }}
{{- end -}}

{{/*
The gRPC API location (also gRPC-web): identity headers from the SSO session on the web server
under SSO, else from the client certificate with mTLS, else cleared. Takes the server's dict.
*/}}
{{- define "armonik.ingress.conf.apiLocation" -}}
{{- $root := .root -}}
{{- $mtls := $root.Values.mtls.enabled | default false }}
{{- $headers := include "armonik.ingress.identityHeaders" $root.Values | fromYaml }}
{{- $sso := include "armonik.ingress.sso" $root | fromYaml }}
{{- $ssoWeb := and $sso.enabled (eq .role "web") }}
    location ~* ^/armonik\. {
        {{- if $ssoWeb }}
        auth_request /oauth2/auth;
        error_page 401 = @grpc_unauthenticated;
        auth_request_set $auth_cookie $upstream_http_set_cookie;
        auth_request_set $sso_identity {{ $sso.identityVar }};
        auth_request_set $sso_groups $upstream_http_x_auth_request_groups;
        # Identity from the SSO session only, never from the client
        grpc_set_header {{ $headers.commonName.name }} $sso_cn;
        grpc_set_header {{ $headers.fingerprint.name }} "{{ $sso.fingerprint }}";
        grpc_set_header {{ $headers.impersonationUsername.name }} "";
        grpc_set_header {{ $headers.impersonationId.name }} "";
        {{- else if $mtls }}
        grpc_set_header {{ $headers.commonName.name }} $client_cn;
        grpc_set_header {{ $headers.fingerprint.name }} $client_fingerprint;
        {{- else }}
        # No client certificate: never forward identity headers sent by the client
        grpc_set_header {{ $headers.commonName.name }} "";
        grpc_set_header {{ $headers.fingerprint.name }} "";
        grpc_set_header {{ $headers.impersonationUsername.name }} "";
        grpc_set_header {{ $headers.impersonationId.name }} "";
        {{- end }}
        grpc_pass grpc://armonik;
        # A whole gRPC stream seems to count as one body, so disable the size limit.
        client_max_body_size 0;
        # 30-day read timeout so long tasks do not raise a gRPC exception.
        # TODO: find a better configuration
        proxy_read_timeout 30d;
        proxy_send_timeout 1d;
        grpc_read_timeout 30d;
        grpc_send_timeout 1d;
    }
{{- end -}}
