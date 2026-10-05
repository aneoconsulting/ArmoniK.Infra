{{/*
  PodDisruptionBudget over the pods of one component.
  Takes dict "root" $ "component" <app.kubernetes.io/component> "values" <podDisruptionBudget block>:
  {enabled, minAvailable, maxUnavailable, labels, annotations}, at most one bound set (0 counts as set);
  maxUnavailable 1 otherwise.
*/}}
{{- define "armonik.pdb" -}}
  {{- $root := .root -}}
  {{- $v := .values | default dict -}}
  {{- if $v.enabled -}}
    {{- $min := $v.minAvailable -}}
    {{- $max := $v.maxUnavailable -}}
    {{- $hasMin := and (not (kindIs "invalid" $min)) (ne (toString $min) "") -}}
    {{- $hasMax := and (not (kindIs "invalid" $max)) (ne (toString $max) "") -}}
    {{- if and $hasMin $hasMax -}}
      {{- printf "%s podDisruptionBudget: set at most one of minAvailable and maxUnavailable" .component | fail -}}
    {{- end }}
apiVersion: {{ include "armonik.pdb.apiVersion" $root }}
kind: PodDisruptionBudget
metadata:
  name: {{ include "armonik.fullname" $root | quote }}
  namespace: {{ include "armonik.namespace" $root | quote }}
  {{- with $v.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    app.kubernetes.io/component: {{ .component | quote }}
    {{- include "armonik.labels" $root | nindent 4 }}
    {{- with $v.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if $hasMin }}
  minAvailable: {{ $min }}
  {{- else }}
  maxUnavailable: {{ $hasMax | ternary $max 1 }}
  {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/component: {{ .component | quote }}
      {{- include "armonik.selectorLabels" $root | nindent 6 }}
  {{- end -}}
{{- end -}}
