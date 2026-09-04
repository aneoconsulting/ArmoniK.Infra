{{/*
SEQ locations
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
Grafana locations
*/}}
{{- /* Grafana runs with a path-less root_url and never learns its public path: we inject it
        below, so one Grafana serves under any prefix. Per-cluster: derive from the cluster key. */}}
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
Renders the Nginx ingress configuration

Usage:
{{- dict "root" . "useEso" true |include "armonik.conf.render"}}
{{- dict "root" . "useEso" false | include "armonik.conf.render"}}

*/}}
{{- define "armonik.conf.render" -}}
{{- $root := .root -}}
{{- $useEso := .useEso -}}
{{- $tls := $root.Values.tls.enabled | default false }}
{{- $mtls := $root.Values.mtls.enabled | default false }}
{{- $cnPattern := include "armonik.ingress.mtlsCnPattern" $root.Values }}
{{- $lbHost := include "armonik.fullname" $root | printf "%s-load-balancer" | trunc 63 | trimSuffix "-" }}
{{- $guiHost := include "armonik.fullname" $root | printf "%s-gui" | trunc 63 | trimSuffix "-" }}
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
map "$http_x_certificate_client_cn|$ssl_client_s_dn_cn" $client_cn {
    default $ssl_client_s_dn_cn;
{{- if $cnPattern }}
    ~^(.+)|({{ $cnPattern }})$ $http_x_certificate_client_cn;
{{- end }}
}
map "$http_x_certificate_client_fingerprint|$ssl_client_s_dn_cn" $client_fingerprint {
    default $ssl_client_fingerprint;
{{- if $cnPattern }}
    ~^(.+)|({{ $cnPattern }})$ $http_x_certificate_client_fingerprint;
{{- end }}
}
{{- end }}

upstream armonik {
    zone armonik_zone 32k;
    {{- if $root.Values.loadBalancer.enabled }}
    # Load balancer enabled: route gRPC through it
    server {{ $lbHost }}.{{ $svcSuffix }}:{{ $root.Values.loadBalancer.conf.listenPort }} resolve;
    {{- else if $root.Values.control_plane_url }}
    # External URL
    server {{ $root.Values.control_plane_url | quote }} resolve;
    {{- else if $useEso }}
    server {{`{{ index . "control-plane" | quote }}`}} resolve;
    {{- end }}
    keepalive 128;
    keepalive_time 8h;
    keepalive_timeout 1h;
}

server {
    {{- if $tls }}
    # ===== TLS ENABLED =====
    listen 8443 ssl http2;
    listen [::]:8443 ssl http2;
    listen 9443 ssl http2;
    listen [::]:9443 ssl http2;
    {{- if or $root.Values.tls.ssl.certificatePath $root.Values.tls.ssl.keyPath }}
    ssl_certificate     {{ default "/ingress/tls.crt" $root.Values.tls.ssl.certificatePath | quote}};
    ssl_certificate_key {{ default "/ingress/tls.key" $root.Values.tls.ssl.keyPath | quote}};
    {{- else }}
    # TLS enabled but no certificate paths configured — mount certificate at /ingress or set .Values.tls.ssl.certificatePath and .Values.tls.ssl.keyPath
    {{- end }}
    {{- if $mtls }}
    ssl_verify_client on;
    ssl_client_certificate /ingressclient/ca.pem;
    {{- else }}
    ssl_verify_client off;
    proxy_hide_header X-Certificate-Client-CN;
    proxy_hide_header X-Certificate-Client-Fingerprint;
    {{- end }}
    ssl_protocols {{ default "TLSv1.2 TLSv1.3" $root.Values.tls.ssl.protocols }};
    ssl_ciphers {{ default "EECDH+AESGCM:EECDH+AES256" $root.Values.tls.ssl.ciphers }};
    ssl_conf_command Ciphersuites {{ default "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256" $root.Values.tls.ssl.cipherSuites }};
    {{- else }}
    # ===== TLS DISABLED =====
    listen 8080;
    listen [::]:8080;
    listen 9080 http2;
    listen [::]:9080 http2;
    {{- end }}

    sendfile on;
    tcp_nopush on;

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
    location ~* ^/armonik\. {
        {{- if $mtls }}
        grpc_set_header X-Certificate-Client-CN $client_cn;
        grpc_set_header X-Certificate-Client-Fingerprint $client_fingerprint;
        {{- end }}
        grpc_pass grpc://armonik;
        # Apparently, multiple chunks in a grpc stream is counted has a single body
        # So disable the limit
        client_max_body_size 0;
        # add a timeout of 1 month to avoid grpc exception for long task
        # TODO: find better configuration
        proxy_read_timeout 30d;
        proxy_send_timeout 1d;
        grpc_read_timeout 30d;
        grpc_send_timeout 1d;
    }

    location /static/ {
        alias /static/;
    }

    proxy_buffering off;
    proxy_request_buffering off;
    {{- if $root.Values.seq_url }}
    set $seq_upstream {{ $root.Values.seq_url | quote }};
    {{ include "armonik.seq.locations" $root }}
    {{- else if $useEso }}
    {{`{{- if .seq }}`}}
    set $seq_upstream {{`{{ .seq | quote }}`}};
    {{ include "armonik.seq.locations" $root }}
    {{`{{- end }}`}}
    {{- end }}

    {{- if $root.Values.grafana_url }}
    set $grafana_upstream {{ $root.Values.grafana_url | quote }};
    {{ include "armonik.grafana.locations" $root }}
    {{- else if $useEso }}
    {{`{{- if .grafana }}`}}
    set $grafana_upstream {{`{{ .grafana | quote }}`}};
    {{ include "armonik.grafana.locations" $root }}
    {{`{{- end }}`}}
    {{- end }}
}
{{- end -}}
