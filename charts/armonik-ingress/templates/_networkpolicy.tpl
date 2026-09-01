{{/*
  Generic namespace selector: matches the current namespace of the subchart
  passed in context.
*/}}
{{- define "armonik.netpol.namespaceSelector" -}}
matchLabels:
  kubernetes.io/metadata.name: {{ include "armonik.namespace" . | quote }}
{{- end -}}


{{/*
  Nginx -> GUI
*/}}
{{- define "armonik.netpol.rule.guiTo" -}}
{{- $guiPort := include "armonik.netpol.port" (dict
      "ports" .Values.gui.ports
      "name" "gui"
    ) | int -}}
to:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      matchLabels:
        app.kubernetes.io/name: ingress
        app.kubernetes.io/component: gui
ports:
  - protocol: TCP
    port: {{ $guiPort }}
{{- end -}}


{{/*
  Nginx -> control-plane.
*/}}
{{- define "armonik.netpol.rule.controlPlaneTo" -}}
to:
  - namespaceSelector: {}
    podSelector:
      matchLabels:
        app.kubernetes.io/name: control-plane
ports:
  - protocol: TCP
    port: 1080
{{- end -}}


{{/*
  Nginx -> grafana.
*/}}
{{- define "armonik.netpol.rule.grafanaTo" -}}
to:
  - namespaceSelector: {}
    podSelector:
      matchLabels:
        app.kubernetes.io/name: grafana
ports:
  - protocol: TCP
    port: 3000 
{{- end -}}


{{/*
  Nginx -> seq.
*/}}
{{- define "armonik.netpol.rule.seqTo" -}}
to:
  - namespaceSelector: {}
    podSelector:
      matchLabels:
        app: seq
ports:
  - protocol: TCP
    port: "ui"
{{- end -}}


{{/*
  GUI ingress: from the nginx front pod only.
*/}}
{{- define "armonik.netpol.rule.guiFrom" -}}
from:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      matchLabels:
        app.kubernetes.io/name: ingress
        app.kubernetes.io/component: ingress
{{- end -}}


{{/*
  External entrypoint into nginx
*/}}
{{- define "armonik.netpol.rule.nginxExternal" -}}
from: []
ports:
  - protocol: TCP
    port: 8080
  - protocol: TCP
    port: 9080
{{- end -}}


{{/*
  Optional extra health-check ingress rule only rendered when networkPolicy.healthCheck.enabled is true.
*/}}
{{- define "armonik.netpol.rule.ingressHealthCheck" -}}
{{- $healthCheckEnabled := .Values.networkPolicy.healthCheck.enabled | default false -}}
{{- if $healthCheckEnabled }}
from:
  {{- toYaml .Values.networkPolicy.healthCheck.from | nindent 2 }}
ports:
  {{- toYaml .Values.networkPolicy.healthCheck.ports | nindent 2 }}
{{- end -}}
{{- end -}}


{{/*
  Egress rules for the NGINX front pod:
  nginx -> DNS
  nginx -> GUI            (same namespace, precise selector)
  nginx -> control-plane   (namespaceSelector: {})
  nginx -> grafana         (namespaceSelector: {})
  nginx -> seq             (namespaceSelector: {})
*/}}
{{- define "armonik.netpol.nginxEgress" -}}
{{- list
      (list "armonik.netpol.dnsRule" dict)
      (list "armonik.netpol.rule.guiTo" .)
      (list "armonik.netpol.rule.controlPlaneTo" .)
      (list "armonik.netpol.rule.grafanaTo" .)
      (list "armonik.netpol.rule.seqTo" .)
    | include "armonik.netpol.mergeRules"
-}}
{{- end -}}


{{/*
  Ingress rules for the NGINX front pod:
  - external client -> nginx (8080/9080)
  - optional health-check
*/}}
{{- define "armonik.netpol.nginxIngress" -}}
{{- list
      (list "armonik.netpol.rule.nginxExternal" .)
      (list "armonik.netpol.rule.ingressHealthCheck" .)
    | include "armonik.netpol.mergeRules"
-}}
{{- end -}}


{{/*
  Egress rules for the GUI pod: DNS only
*/}}
{{- define "armonik.netpol.guiEgress" -}}
{{- list
      (list "armonik.netpol.dnsRule" dict)
    | include "armonik.netpol.mergeRules"
-}}
{{- end -}}


{{/*
  NGINX front NetworkPolicy configuration.
*/}}
{{- define "armonik.netpol.ingressNginx" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: ingress
    app.kubernetes.io/component: ingress

policyTypes:
  - Ingress
  - Egress

ingress:
  rules:
    {{- include "armonik.netpol.nginxIngress" . | nindent 4 }}
  extraRules:
    {{- toYaml (.Values.networkPolicy.ingress.extraRules | default list) | nindent 4 }}

egress:
  rules:
    {{- include "armonik.netpol.nginxEgress" . | nindent 4 }}
  extraRules:
    {{- toYaml (.Values.networkPolicy.egress.extraRules | default list) | nindent 4 }}
{{- end -}}


{{/*
  GUI NetworkPolicy configuration.
*/}}
{{- define "armonik.netpol.ingressGui" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: ingress
    app.kubernetes.io/component: gui

policyTypes:
  - Ingress
  - Egress

ingress:
  rules:
    {{- list
          (list "armonik.netpol.rule.guiFrom" .)
        | include "armonik.netpol.mergeRules"
        | nindent 4
    }}
  extraRules:
    {{- toYaml (.Values.networkPolicy.ingress.extraRules | default list) | nindent 4 }}

egress:
  rules:
    {{- include "armonik.netpol.guiEgress" . | nindent 4 }}
  extraRules:
    {{- toYaml (.Values.networkPolicy.egress.extraRules | default list) | nindent 4 }}
{{- end -}}
