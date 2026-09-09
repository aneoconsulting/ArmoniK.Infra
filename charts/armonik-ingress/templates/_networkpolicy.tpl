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
        app.kubernetes.io/component: gui
        {{- include "armonik.selectorLabels" . | nindent 8 }}
ports:
  - protocol: TCP
    port: {{ $guiPort }}
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
        app.kubernetes.io/component: ingress
        {{- include "armonik.selectorLabels" . | nindent 8 }}
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
  Egress rules for the NGINX front pod: DNS, GUI .
*/}}
{{- define "armonik.netpol.nginxEgress" -}}
{{- list
      (list "armonik.netpol.dnsRule" dict)
      (list "armonik.netpol.rule.guiTo" .)
    | include "armonik.netpol.mergeRules"
-}}
{{- end -}}


{{/*
  Ingress rules for the NGINX front pod: external client -> nginx (8080/9080). Wrapped in a
  single list directly (not mergeRules) since nginxExternal always renders - mergeRules' merge
  and null-filtering machinery is only needed for multiple or conditionally-empty rules.
*/}}
{{- define "armonik.netpol.nginxIngress" -}}
{{- list (include "armonik.netpol.rule.nginxExternal" . | fromYaml) | toYaml -}}
{{- end -}}


{{/*
  NGINX front NetworkPolicy configuration.
*/}}
{{- define "armonik.netpol.ingressNginx" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/component: ingress
    {{- include "armonik.selectorLabels" . | nindent 4 }}

ingress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (include "armonik.netpol.nginxIngress" .)
        "extra" .Values.networkPolicy.nginx.extraIngressRules
    ) | nindent 2 }}

egress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (include "armonik.netpol.nginxEgress" .)
        "extra" .Values.networkPolicy.nginx.extraEgressRules
    ) | nindent 2 }}
{{- end -}}


{{- define "armonik.netpol.ingressHealthCheck" -}}
podSelector:
  {{- .Values.networkPolicy.healthCheckPodSelector | default dict | toYaml | nindent 2 }}
ingress:
  {{- .Values.networkPolicy.healthCheckRules | default list | toYaml | nindent 2 }}
{{- end -}}


{{/*
  GUI NetworkPolicy configuration.
*/}}
{{- define "armonik.netpol.ingressGui" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/component: gui
    {{- include "armonik.selectorLabels" . | nindent 4 }}

ingress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (list (include "armonik.netpol.rule.guiFrom" . | fromYaml) | toYaml)
        "extra" .Values.networkPolicy.gui.extraIngressRules
    ) | nindent 2 }}

egress:
  {{- include "armonik.netpol.mergeExtra" (dict
        "rules" (list (include "armonik.netpol.dnsRule" dict | fromYaml) | toYaml)
        "extra" .Values.networkPolicy.gui.extraEgressRules
    ) | nindent 2 }}
{{- end -}}
