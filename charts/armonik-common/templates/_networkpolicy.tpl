{{/*
  A component's NetworkPolicy. `component` names the policy and its labels; `config` carries
  podSelector, ingress, egress, namespace and optionally policyTypes, which is otherwise inferred
  from whichever of ingress/egress is non-empty.

  {{ include "armonik.netpol.render" (dict "context" . "component" "control-plane" "config" $config) }}
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


{{/* Generic namespace selector: matches the current namespace of the subchart passed in context. */}}
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


{{/* Generic pod selector: matches by app.kubernetes.io/name of the subchart passed in context. */}}
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
  One ingress or egress rule admitting a peer pod on a port. Direction is "from" (ingress) or
  "to" (egress).

  {{ include "armonik.netpol.rule.peerOnPort" (list $nsSelector $podSelector 5000 "from") }}
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
  Ingress from the cluster's shared Prometheus (global.armonik.monitoring.prometheusUrl), on the
  given port. Resolves the same whether the calling chart is standalone or installed through the
  umbrella, since the URL is a global value. No rule when the operator is unavailable or its
  namespace is unstated.
*/}}
{{- define "armonik.netpol.rule.prometheusIngress" -}}
{{- $ctx := index . 0 -}}
{{- $port := index . 1 -}}
{{- $podSelectorOverride := index . 2 -}}
{{- $ops := include "armonik.operators" $ctx | fromYaml -}}
{{- if and $ops.prometheusOperator.available $ops.prometheusOperator.namespace }}
{{- $ns := include "armonik.monitoring.prometheusUrl" $ctx | include "armonik.netpol.namespaceFromServiceUrl" -}}
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


{{/* Egress rule: DNS resolution via kube-dns in kube-system. */}}
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


{{/* Egress ports rule: the Kubernetes API server (443 in-cluster, 6443 common external port). */}}
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

{{/*
Container port <name> at the given .Values path, falling back to 1080.
Usage: {{- list $ (list "control-plane" "ports") "control-port" | include "armonik.netpol.controlPlane.port" -}}
*/}}
{{- define "armonik.netpol.controlPlane.port" -}}
  {{- $root := index . 0 -}}
  {{- $pathSegments := index . 1 -}}
  {{- $portName := index . 2 -}}
  {{- $ports := concat (list $root.Values) $pathSegments | include "armonik.utils.index" | fromYamlArray | default list -}}
  {{- include "armonik.netpol.port" (dict "ports" $ports "name" $portName) | trim | default "1080" -}}
{{- end -}}
