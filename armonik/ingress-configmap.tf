# Envvars
locals {
  armonik_conf = <<EOF
resolver kube-dns.kube-system ipv6=off;

map $http_accept_language $accept_language {
    default en;
%{for lang in var.ingress.langs~}
    ~*^${lang} ${lang};
%{endfor~}
}

map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

%{if var.ingress != null ? var.ingress.mtls : false~}
map $ssl_client_s_dn $ssl_client_s_dn_cn {
    default "";
    ~CN=(?<CN>[^,/]+) $CN;
}
%{endif~}

%{if var.ingress != null ? var.ingress.mtls : false~}
# Check if the $http_x_certificate_client_cn header is present and the common name is in the list of
# trusted cns. If so, it uses that value; otherwise, it defaults to the Cn from the SSL certificate
map "$http_x_certificate_client_cn|$ssl_client_s_dn_cn" $client_cn {
    default                                $ssl_client_s_dn_cn;
%{if can(coalesce(local.cn_regex_pattern))~}
    ~^(.+)\|(${local.cn_regex_pattern})$   $http_x_certificate_client_cn;
%{endif~}
}

# Check if the $http_x_certificate_client_fingerprint header is present and the common name is in the list of
# trusted cns. If so, it uses that value; otherwise, it defaults to the Fingerprint from the SSL certificate
map "$http_x_certificate_client_fingerprint|$ssl_client_s_dn_cn" $client_fingerprint {
    default                                $ssl_client_fingerprint;
%{if can(coalesce(local.cn_regex_pattern))~}
    ~^(.+)\|(${local.cn_regex_pattern})$   $http_x_certificate_client_fingerprint;
%{endif~}
}
%{endif~}

upstream armonik {
    server ${local.control_plane_endpoints.ip}:${local.control_plane_endpoints.port} resolve;
    keepalive 128;
    keepalive_time 8h;
    keepalive_timeout 1h;
}

server {
%{if var.ingress != null ? var.ingress.tls : false~}
    listen 8443 ssl http2;
    listen [::]:8443 ssl http2;
    listen 9443 ssl http2;
    listen [::]:9443 ssl http2;
    ssl_certificate     /ingress/ingress.crt;
    ssl_certificate_key /ingress/ingress.key;
%{if var.ingress.mtls~}
    ssl_verify_client on;
    ssl_client_certificate /ingressclient/ca.pem;
%{else~}
    ssl_verify_client off;
    proxy_hide_header X-Certificate-Client-CN;
    proxy_hide_header X-Certificate-Client-Fingerprint;
%{endif~}
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers EECDH+AESGCM:EECDH+AES256;
    ssl_conf_command Ciphersuites TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256;
%{else~}
    listen 8080;
    listen [::]:8080;
    listen 9080 http2;
    listen [::]:9080 http2;
%{endif~}

%{if var.oauth_configuration != null}
    location = /auth {
      internal;
      proxy_pass ${var.oauth_configuration.provider_root_URI}${var.oauth_configuration.provider_user_info_endpoint};
      proxy_set_header Cookie $http_cookie;
      proxy_pass_request_body off;
      proxy_set_header Content-Length "";
      proxy_set_header X-Original-URI $request_uri;
    }

    error_page 401 = @errorAuth;
    error_page 403 = @errorAuth;

    location @errorAuth {
      return 302 ${var.oauth_configuration.provider_root_URI}/${var.oauth_configuration.provider_authorization_endpoint}?client_id=${var.oauth_configuration.client_id}&response_type=${var.oauth_configuration.response_type}&redirect_uri=${local.ingress_http_url}/admin/en/;
    }
    
    auth_request /auth;
    auth_request_set $auth_status $upstream_status;
%{endif~}

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
%{for lang in var.ingress.langs~}
    location = /admin/${lang} {
        rewrite ^ $scheme://$http_host/admin/${lang}/;
    }
%{endfor~}
%{if local.admin_app_url != null~}
    set $admin_app_upstream ${local.admin_app_url};
    location /admin/ {
        auth_request off;
        proxy_pass $admin_app_upstream$uri$is_args$args;
    }
%{endif~}
    location ~* ^/armonik\. {
%{if var.ingress != null ? var.ingress.mtls : false~}
        grpc_set_header X-Certificate-Client-CN $client_cn ;
        grpc_set_header X-Certificate-Client-Fingerprint $client_fingerprint;
%{endif~}
%{if var.ingress != null && length(var.ingress.cors_allowed_host) != 0~}
        add_header Access-Control-Allow-Origin ${var.ingress.cors_allowed_host} always;
        add_header Access-Control-Allow-Methods ${join(",", var.ingress.cors_allowed_methods)} always;
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin ${var.ingress.cors_allowed_host} always;
            add_header Access-Control-Allow-Methods ${join(",", var.ingress.cors_allowed_methods)};
            add_header 'Access-Control-Allow-Credentials' 'true';
            add_header 'Access-Control-Allow-Headers' ${join(",", setunion(local.cors_default_grpc_headers, local.cors_all_headers))};
            add_header 'Access-Control-Max-Age' ${var.ingress.cors_preflight_max_age};
            add_header 'Content-Type' 'text/plain charset=UTF-8';
            add_header 'Content-Length' 0;
            return 204;
        }
%{endif~}
        grpc_pass grpc://armonik;

        # Apparently, multiple chunks in a grpc stream is counted has a single body
        # So disable the limit
        client_max_body_size 0;

        # add a timeout of 1 month to avoid grpc exception for long task
        # TODO: find better configuration
        client_body_timeout 1d;
        proxy_read_timeout 30d;
        proxy_send_timeout 1d;
        grpc_read_timeout 30d;
        grpc_send_timeout 1d;
    }

    location /static/ {
%{if var.ingress != null && length(var.ingress.cors_allowed_host) != 0~}
        add_header Access-Control-Allow-Origin ${var.ingress.cors_allowed_host} always;
        add_header Access-Control-Allow-Methods ${join(",", var.ingress.cors_allowed_methods)} always;
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin ${var.ingress.cors_allowed_host} always;
            add_header Access-Control-Allow-Methods ${join(",", var.ingress.cors_allowed_methods)};
            add_header 'Access-Control-Allow-Credentials' 'true';
            add_header 'Access-Control-Allow-Headers' ${join(",", local.cors_all_headers)};
            add_header 'Access-Control-Max-Age' ${var.ingress.cors_preflight_max_age};
            add_header 'Content-Type' 'text/plain charset=UTF-8';
            add_header 'Content-Length' 0;
            return 204;
        }
%{endif~}
        alias /static/;
    }


    proxy_buffering off;
    proxy_request_buffering off;

%{if var.shared_storage_settings.file_storage_type == "s3"~}
 set $minio_upstream ${var.shared_storage_settings.service_url};
 location / {
    client_max_body_size 0;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_connect_timeout 300;
    # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    chunked_transfer_encoding off;

    proxy_pass $minio_upstream$uri$is_args$args; # This uses the upstream directive definition to load balance
 }

 set $minioconsole_upstream ${var.shared_storage_settings.console_url};
 location /minioconsole {
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-NginX-Proxy true;

    rewrite ^/minioconsole/(.*) /$1 break;
    sub_filter '<head>' '<head><base href="$${scheme}://$${http_host}/minioconsole/">';
    sub_filter_once on;

    # This is necessary to pass the correct IP to be hashed
    real_ip_header X-Real-IP;

    proxy_connect_timeout 300;

    # To support websockets in MinIO versions released after January 2023
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    chunked_transfer_encoding off;

    proxy_pass $minioconsole_upstream$uri$is_args$args; # This uses the upstream directive definition to load balance and assumes a static Console port of 9001
 }
 %{endif~}


%{if length(var.seq) > 0~}
    set $seq_upstream ${var.seq.web_url};
    location = /seq {
        rewrite ^ $scheme://$http_host/seq/ permanent;
    }
    location /seq/ {
%{if var.ingress != null ? var.ingress.mtls : false~}
        proxy_set_header X-Certificate-Client-CN $ssl_client_s_dn_cn;
        proxy_set_header X-Certificate-Client-Fingerprint $ssl_client_fingerprint;
%{endif~}
        proxy_set_header Host $http_host;
        proxy_set_header Accept-Encoding "";
        rewrite  ^/seq/(.*)  /$1 break;
        proxy_pass $seq_upstream$uri$is_args$args;
        sub_filter '<head>' '<head><base href="$${scheme}://$${http_host}/seq/">';
        sub_filter_once on;
        proxy_hide_header content-security-policy;
    }
%{endif~}
%{if length(var.grafana) > 0~}
    set $grafana_upstream ${var.grafana.url};
    location = /grafana {
        rewrite ^ $scheme://$http_host/grafana/ permanent;
    }
    location /grafana/ {
        rewrite  ^/grafana/(.*)  /$1 break;
%{if var.ingress != null ? var.ingress.mtls : false~}
        proxy_set_header X-Certificate-Client-CN $ssl_client_s_dn_cn;
        proxy_set_header X-Certificate-Client-Fingerprint $ssl_client_fingerprint;
%{endif~}
        proxy_set_header Host $http_host;
        proxy_pass $grafana_upstream$uri$is_args$args;
        sub_filter '<head>' '<head><base href="$${scheme}://$${http_host}/grafana/">';
        sub_filter_once on;
        proxy_intercept_errors on;
        error_page 301 302 307 =302 $${scheme}://$${http_host}$${upstream_http_location};
    }
    location /grafana/api/live {
        rewrite  ^/grafana/(.*)  /$1 break;
%{if var.ingress != null ? var.ingress.mtls : false~}
        proxy_set_header X-Certificate-Client-CN $ssl_client_s_dn_cn;
        proxy_set_header X-Certificate-Client-Fingerprint $ssl_client_fingerprint;
%{endif~}
%{if var.ingress != null ? var.ingress.tls : false~}
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
%{endif~}
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_pass $grafana_upstream$uri$is_args$args;
    }
%{endif~}
}
EOF

  static = merge(var.static, var.environment_description != null ? { "environment.json" = var.environment_description } : {})
}

resource "kubernetes_config_map" "ingress" {
  count = (var.ingress != null ? 1 : 0)
  metadata {
    name      = "ingress-nginx"
    namespace = var.namespace
  }
  data = {
    "armonik.conf" = local.armonik_conf
  }
}

resource "kubernetes_config_map" "static" {
  count = (var.ingress != null ? 1 : 0)
  metadata {
    name      = "ingress-nginx-static"
    namespace = var.namespace
  }
  data = {
    for k, v in local.static :
    k => jsonencode(v)
  }
}

resource "local_file" "ingress_conf_file" {
  count           = (var.ingress != null ? 1 : 0)
  content         = local.armonik_conf
  filename        = "${path.root}/generated/configmaps/ingress/armonik.conf"
  file_permission = "0644"
}
