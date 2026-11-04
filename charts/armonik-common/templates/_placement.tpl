{{/*
Node placement of a pod on the node classes of global.armonik.nodeProvisioner (charts/node-classes.md).
Takes a dict:
  root                  chart context, for .Values.global
  path                  values path of the component, for the error messages; empty at chart level
  nodeClass             class to run on; empty leaves the pod to the cluster default class
  nodeSelector          the component's own, kept as written
  tolerations           the component's own, kept as written
  podAnnotations        the component's own, kept as written
  disruptionProtection  keep the autoscaler from evicting the pod to remove its node
Returns {nodeSelector, tolerations, podAnnotations}, each key absent when empty.

gke: the class is a ComputeClass, selected by its node label. The node pools it creates carry the
matching taint, so the pod also gets its toleration (a no-op where GKE adds it itself). A nodeSelector
already naming another ComputeClass fails: the pod would follow neither.
Without a provider the inputs come back unchanged, and a nodeClass fails rather than being ignored.

  {{- $placement := dict "root" $ "path" "partitions.default" "nodeClass" $p.nodeClass ... | include "armonik.placement" | fromYaml }}
  {{- with $placement.nodeSelector }} ... {{- end }}
*/}}
{{- define "armonik.placement" -}}
  {{- $provider := list .root.Values "global" "armonik" "nodeProvisioner" | include "armonik.utils.index" -}}
  {{- $nodeClass := .nodeClass | default "" -}}
  {{- $where := .path | empty | ternary "nodeClass" (printf "%s.nodeClass" .path) -}}
  {{- $nodeSelector := .nodeSelector | default dict | deepCopy -}}
  {{- $tolerations := .tolerations | default list -}}
  {{- $podAnnotations := .podAnnotations | default dict | deepCopy -}}
  {{- if eq $provider "gke" -}}
    {{- $key := "cloud.google.com/compute-class" -}}
    {{- with $nodeClass -}}
      {{- $selected := get $nodeSelector $key -}}
      {{- if and $selected (ne $selected .) -}}
        {{- printf "%s %q conflicts with nodeSelector %s=%q: set one of them." $where . $key $selected | fail -}}
      {{- end -}}
      {{- $_ := set $nodeSelector $key . -}}
      {{- $toleration := dict "key" $key "operator" "Equal" "value" . "effect" "NoSchedule" -}}
      {{- if not (has $toleration $tolerations) -}}
        {{- $tolerations = append $tolerations $toleration -}}
      {{- end -}}
    {{- end -}}
    {{- if .disruptionProtection -}}
      {{- $annotation := "cluster-autoscaler.kubernetes.io/safe-to-evict" -}}
      {{- if not (hasKey $podAnnotations $annotation) -}}
        {{- $_ := set $podAnnotations $annotation "false" -}}
      {{- end -}}
    {{- end -}}
  {{- else if $provider -}}
    {{- printf "global.armonik.nodeProvisioner: unknown provider %q, expected \"gke\" or empty." $provider | fail -}}
  {{- else if $nodeClass -}}
    {{- printf "%s %q requires global.armonik.nodeProvisioner (\"gke\"): without it the class would be ignored." $where $nodeClass | fail -}}
  {{- end -}}
  {{- $placement := dict -}}
  {{- with $nodeSelector }}{{ $_ := set $placement "nodeSelector" . }}{{ end -}}
  {{- with $tolerations }}{{ $_ := set $placement "tolerations" . }}{{ end -}}
  {{- with $podAnnotations }}{{ $_ := set $placement "podAnnotations" . }}{{ end -}}
  {{- toYaml $placement -}}
{{- end -}}
