{{- define "armonik.netpol.dnsRule" -}}
{{- $cfg := . | default dict -}}
{{- $namespace := $cfg.namespace | default "kube-system" -}}
{{- $labels := $cfg.labels | default (dict "k8s-app" "kube-dns") -}}
{{- $ports := $cfg.ports | default (list (dict "protocol" "UDP" "port" 53) (dict "protocol" "TCP" "port" 53)) -}}
to:
  - namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: {{ $namespace }}
    podSelector:
      matchLabels:
        {{- toYaml $labels | nindent 8 }}
ports:
  {{- toYaml $ports | nindent 2 }}
{{- end -}}