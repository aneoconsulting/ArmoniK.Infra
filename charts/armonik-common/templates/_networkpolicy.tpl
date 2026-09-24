{{/*
  Renders a NetworkPolicy for a component.

  Usage:
    {{ include "armonik.netpol.render" (dict
      "context" .
      "component" "control-plane"
      "config" $config
    ) }}

  Args:
    context: Helm context.
    component: Component name used in the policy name and labels.
    config: NetworkPolicy configuration, including podSelector, ingress,
            egress, namespace, and optional policyTypes.

  If policyTypes is not set, it is inferred from the configured ingress
  and egress rules.
*/}}
{{- define "armonik.netpol.render" -}}
{{- $ctx := .context | default dict -}}
{{- $component := .component | default dict -}}
{{- $cfg := .config | default dict -}}
{{- $policyType := list -}}
{{- if and (hasKey $cfg "ingress") (not (empty $cfg.ingress)) -}}
{{- $policyType = append $policyType "Ingress" -}}
{{- end -}}
{{- if and (hasKey $cfg "egress") (not (empty $cfg.egress)) -}}
{{- $policyType = append $policyType "Egress" -}}
{{- end -}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "armonik.fullname" $ctx }}-{{ $component }}
  namespace: {{ $cfg.namespace | default (include "armonik.namespace" $ctx) | quote }}
  labels:
    app.kubernetes.io/component: {{ $component | quote }}
    {{- include "armonik.labels" $ctx | nindent 4 }}
spec:
  podSelector:
    {{- toYaml $cfg.podSelector | nindent 4 }}
  policyTypes:
    {{- $cfg.policyTypes | default $policyType | toYaml | nindent 4 }}
  {{- with $cfg.ingress }}
  ingress:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $cfg.egress }}
  egress:
    {{- toYaml . | nindent 4 }}
  {{- end }}
---
{{ end }}


{{/*
  Generic namespace selector: matches the current namespace of the subchart passed in context.
*/}}
{{- define "armonik.netpol.namespaceSelector" -}}
matchLabels:
  kubernetes.io/metadata.name: {{ include "armonik.namespace" . | quote }}
{{- end -}}


{{/*
  Namespace segment of an in-cluster service URL/host, shaped <name>.<namespace>.svc[.<domain>][:port]
  (the .<domain> suffix is absent when clusterDomain is unset, so "svc" isn't always followed by a dot).
  Empty when the URL is unset or not in that shape (e.g. an external URL) - callers skip their rule.
*/}}
{{- define "armonik.netpol.namespaceFromServiceUrl" -}}
  {{- $host := . | default "" | trimPrefix "http://" | trimPrefix "https://" -}}
  {{- if regexMatch "^[^./]+\\.[^./]+\\.svc([.:]|$)" $host -}}
    {{- regexReplaceAll "^[^./]+\\.([^./]+)\\.svc([.:].*)?$" $host "${1}" -}}
  {{- end -}}
{{- end -}}


{{/*
  Generic pod selector: matches by app.kubernetes.io/name of the subchart passed in context.
*/}}
{{- define "armonik.netpol.podSelector" -}}
matchLabels:
  app.kubernetes.io/name: {{ include "armonik.name" . | quote }}
{{- end -}}


{{/*
  A user-supplied podSelector override, or a literal app.kubernetes.io/name default. For pods
  created by an external operator (Prometheus, KEDA, the MongoDB operator) whose real label
  cannot be derived from any of our own charts, so every such override value shares this fallback.
  Args (list): [override, name]
*/}}
{{- define "armonik.netpol.podSelector.default" -}}
  {{- $override := index . 0 -}}
  {{- $name := index . 1 -}}
  {{- $override | default (dict "matchLabels" (dict "app.kubernetes.io/name" $name)) | toYaml -}}
{{- end -}}


{{/*
  Creates an ingress or egress rule for a pod in a namespace on a specific port.

  Usage:
    {{ include "armonik.netpol.rule.peerOnPort" (list
      $namespaceSelector
      $podSelector
      5000
      "from"
    ) }}

  Args:
    namespaceSelector: Namespace selector for the peer.
    podSelector: Pod selector for the peer.
    port: Port allowed by the rule.
    direction: "from" for ingress or "to" for egress.
*/}}
{{- define "armonik.netpol.rule.peerOnPort" -}}
{{- $namespaceSelector := index . 0 -}}
{{- $podSelector := index . 1 -}}
{{- $port := index . 2 -}}
{{- $direction := index . 3 -}}
{{ $direction }}:
  - namespaceSelector:
      {{- $namespaceSelector | nindent 6 }}
    podSelector:
      {{- $podSelector | nindent 6 }}
ports:
  - protocol: TCP
    port: {{ $port }}
{{- end -}}


{{/*
  Ingress from the shared Prometheus on the given port, from the namespace of
  global.armonik.monitoring.prometheusUrl, else of the operator where that URL does not derive (plane
  charts): being scraped must not require it. No rule when the operator is unavailable or its
  namespace unstated, nor for an out-of-cluster URL.
*/}}
{{- define "armonik.netpol.rule.prometheusIngress" -}}
{{- $ctx := index . 0 -}}
{{- $port := index . 1 -}}
{{- $podSelectorOverride := index . 2 -}}
{{- $ops := include "armonik.operators" $ctx | fromYaml -}}
{{- if and $ops.prometheusOperator.available $ops.prometheusOperator.namespace }}
{{- $raw := list $ctx.Values "global" "armonik" "monitoring" "prometheusUrl" | include "armonik.utils.index" -}}
{{- $url := tpl $raw $ctx -}}
{{- $ns := $url | empty | ternary $ops.prometheusOperator.namespace (include "armonik.netpol.namespaceFromServiceUrl" $url) -}}
{{- if $ns }}
from:
  - namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: {{ $ns | quote }}
    podSelector:
      {{- list $podSelectorOverride "prometheus" | include "armonik.netpol.podSelector.default" | nindent 6 }}
ports:
  - protocol: TCP
    port: {{ $port }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
  Egress rule: DNS resolution via kube-dns in kube-system.
*/}}
{{- define "armonik.netpol.dnsRule" -}}
to:
  - namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: kube-system
    podSelector:
      matchLabels:
        k8s-app: kube-dns
ports:
  - protocol: UDP
    port: 53
  - protocol: TCP
    port: 53
{{- end -}}


{{/*
  Egress ports rule: the Kubernetes API server (443 in-cluster, 6443 common external port).
*/}}
{{- define "armonik.netpol.kubeApiRule" -}}
ports:
  - protocol: TCP
    port: 443
  - protocol: TCP
    port: 6443
{{- end -}}

{{/*
  Merges a dict of named rules into one rule list: each entry maps a define name to its render
  context, included and parsed back from YAML, nil results dropped.
*/}}
{{- define "armonik.netpol.mergeRules" -}}
  {{- $rules := list -}}
  {{- range $name, $ctx := . -}}
    {{- $rules = include $name $ctx | fromYaml | append $rules -}}
  {{- end -}}
  {{- $rules | compact | toYaml -}}
{{- end -}}

{{/*
  Concatenates the chart's own rules with the user's extra rules, dropping nils.
  Args (dict): {rules, extra}
*/}}
{{- define "armonik.netpol.mergeExtra" -}}
  {{- $rules := .rules | default "" | fromYamlArray | default list -}}
  {{- $extra := .extra | default list -}}
  {{- concat $rules $extra | compact | toYaml -}}
{{- end -}}

{{- define "armonik.netpol.controlPlane.port" -}}
  {{- $root := index . 0 -}}
  {{- $pathSegments := index . 1 -}}
  {{- $portName := index . 2 -}}
  {{- $ports := concat (list $root.Values) $pathSegments | include "armonik.utils.index" | fromYamlArray | default list -}}
  {{- include "armonik.netpol.port" (dict "ports" $ports "name" $portName) | trim | default "1080" -}}
{{- end -}}
