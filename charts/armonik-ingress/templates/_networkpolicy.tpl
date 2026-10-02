{{/*
  Egress rule: nginx to the GUI pod, on its gui port.
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
  Ingress rule: any source to nginx on 8080/9080.
  TODO: the TLS ports 8443/9443 (armonik.ingress.containerPort) are not admitted.
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
  nginx egress rules: DNS and the GUI.
*/}}
{{- define "armonik.netpol.nginxEgress" -}}
  {{- dict
        "armonik.netpol.dnsRule" dict
        "armonik.netpol.rule.guiTo" .
      | include "armonik.netpol.mergeRules"
  -}}
{{- end -}}


{{/*
  nginx ingress rules: the external rule alone, listed directly since it always renders.
*/}}
{{- define "armonik.netpol.nginxIngress" -}}
  {{- list (include "armonik.netpol.rule.nginxExternal" . | fromYaml) | toYaml -}}
{{- end -}}


{{/*
  nginx NetworkPolicy config: the chart's rules plus networkPolicy.nginx.extra*Rules.
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


{{/*
  Health-check NetworkPolicy config, entirely from networkPolicy.healthCheck{PodSelector,Rules}.
*/}}
{{- define "armonik.netpol.ingressHealthCheck" -}}
podSelector:
  {{- .Values.networkPolicy.healthCheckPodSelector | default dict | toYaml | nindent 2 }}
ingress:
  {{- .Values.networkPolicy.healthCheckRules | default list | toYaml | nindent 2 }}
{{- end -}}


{{/*
  GUI NetworkPolicy config: ingress from nginx, egress to DNS, plus networkPolicy.gui.extra*Rules.
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
