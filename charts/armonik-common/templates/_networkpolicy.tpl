{{/*
  NetworkPolicy <fullname>-<component>, followed by a document separator.

  Usage:
    {{ include "armonik.netpol.render" (dict
      "context" .
      "component" "control-plane"
      "config" $config
    ) }}

  Args:
    context: Helm context.
    component: component name, in the policy name and labels.
    config: podSelector, ingress, egress, optional namespace and policyTypes. policyTypes
            defaults to the non-empty ones of ingress and egress.
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
  namespaceSelector matching the namespace of the chart passed as context.
*/}}
{{- define "armonik.netpol.namespaceSelector" -}}
matchLabels:
  kubernetes.io/metadata.name: {{ include "armonik.namespace" . | quote }}
{{- end -}}


{{/*
  Namespace segment of an in-cluster service URL or host, <name>.<namespace>.svc[.<domain>][:port].
  Empty when the URL is unset or has another shape (an external URL, for one); callers then skip
  their rule.
*/}}
{{- define "armonik.netpol.namespaceFromServiceUrl" -}}
  {{- $host := . | default "" | trimPrefix "http://" | trimPrefix "https://" -}}
  {{- if regexMatch "^[^./]+\\.[^./]+\\.svc([.:]|$)" $host -}}
    {{- regexReplaceAll "^[^./]+\\.([^./]+)\\.svc([.:].*)?$" $host "${1}" -}}
  {{- end -}}
{{- end -}}


{{/*
  podSelector matching app.kubernetes.io/name of the chart passed as context.
*/}}
{{- define "armonik.netpol.podSelector" -}}
matchLabels:
  app.kubernetes.io/name: {{ include "armonik.name" . | quote }}
{{- end -}}


{{/*
  The user's podSelector override, else a literal app.kubernetes.io/name selector. For pods of an
  external operator (Prometheus, KEDA, the MongoDB operator), whose labels our charts cannot derive.
  Args (list): [override, name]
*/}}
{{- define "armonik.netpol.podSelector.default" -}}
  {{- $override := index . 0 -}}
  {{- $name := index . 1 -}}
  {{- $override | default (dict "matchLabels" (dict "app.kubernetes.io/name" $name)) | toYaml -}}
{{- end -}}


{{/*
  Ingress or egress rule for a peer (namespace + pod selector) on one TCP port.

  Usage:
    {{ include "armonik.netpol.rule.peerOnPort" (list
      $namespaceSelector
      $podSelector
      5000
      "from"
    ) }}

  Args:
    namespaceSelector: peer namespace selector, pre-rendered YAML.
    podSelector: peer pod selector, pre-rendered YAML.
    port: allowed port.
    direction: "from" for ingress, "to" for egress.
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
  Ingress from the shared Prometheus on the given port. Peer namespace: that of
  global.armonik.monitoring.prometheusUrl, else the operator's (plane charts, where the URL does not
  derive: being scraped must not require it). No rule when the operator is unavailable or its
  namespace unstated, nor for an out-of-cluster URL.
  Args (list): [context, port, podSelector override]
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
  Egress rule to kube-dns in kube-system.
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
  Egress rule to the Kubernetes API server by port only: 443 in-cluster, 6443 the usual external port.
*/}}
{{- define "armonik.netpol.kubeApiRule" -}}
ports:
  - protocol: TCP
    port: 443
  - protocol: TCP
    port: 6443
{{- end -}}

{{/*
  Rule list from a dict mapping a define name to its render context. Empty results are dropped.
*/}}
{{- define "armonik.netpol.mergeRules" -}}
  {{- $rules := list -}}
  {{- range $name, $ctx := . -}}
    {{- $rules = include $name $ctx | fromYaml | append $rules -}}
  {{- end -}}
  {{- $rules | compact | toYaml -}}
{{- end -}}

{{/*
  The chart's own rules (YAML list) followed by the user's extra rules, empty entries dropped.
  Args (dict): {rules, extra}
*/}}
{{- define "armonik.netpol.mergeExtra" -}}
  {{- $rules := .rules | default "" | fromYamlArray | default list -}}
  {{- $extra := .extra | default list -}}
  {{- concat $rules $extra | compact | toYaml -}}
{{- end -}}

{{/*
  containerPort named <port name> in the ports list at <values path>, else 1080.
  Args (list): [root, values path segments (list), port name]
*/}}
{{- define "armonik.netpol.controlPlane.port" -}}
  {{- $root := index . 0 -}}
  {{- $pathSegments := index . 1 -}}
  {{- $portName := index . 2 -}}
  {{- $ports := concat (list $root.Values) $pathSegments | include "armonik.utils.index" | fromYamlArray | default list -}}
  {{- include "armonik.netpol.port" (dict "ports" $ports "name" $portName) | trim | default "1080" -}}
{{- end -}}
