{{- define "armonik.netpol.render" -}}
{{- $ctx := .context -}}
{{- $component := .component -}}
{{- $cfg := .config -}}
{{- if $cfg.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "armonik.fullname" $ctx }}-{{ $component }}
  namespace: {{ $cfg.namespace | default (include "armonik.namespace" $ctx) }}
  labels:
    app.kubernetes.io/component: {{ $component }}
    {{- include "armonik.labels" $ctx | nindent 4 }}
spec:
  podSelector:
    {{- toYaml $cfg.podSelector | nindent 4 }}
  policyTypes:
    {{- toYaml ($cfg.policyTypes | default (list "Ingress" "Egress")) | nindent 4 }}
  {{- $ingressRules := concat ($cfg.ingress.rules | default list) ($cfg.ingress.extraRules | default list) }}
  {{- if $ingressRules }}
  ingress:
    {{- toYaml $ingressRules | nindent 4 }}
  {{- end }}
  {{- $egressRules := concat ($cfg.egress.rules | default list) ($cfg.egress.extraRules | default list) }}
  {{- if $egressRules }}
  egress:
    {{- toYaml $egressRules | nindent 4 }}
  {{- end }}
{{- end }}
{{- end -}}