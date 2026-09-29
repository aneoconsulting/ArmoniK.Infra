{{/*
Control map of the install-once operators, from global.armonik.operators.<op>.{available,deploy,namespace}
(semantics and defaults in armonik-common/values.yaml). Absent flags read as false. namespace comes back
tpl-rendered, empty when nobody stated where an external operator runs.

  {{- $ops := include "armonik.operators" $ | fromYaml }}
  {{- if $ops.keda.available }} ...emit ScaledObject... {{- end }}
  {{- if $ops.keda.deploy }}    ...emit CRD-ordering hook... {{- end }}
  {{- $ops.prometheusOperator.namespace }}
*/}}
{{- define "armonik.operators" -}}
{{- range list "externalSecrets" "keda" "certManager" "mongodbOperator" "prometheusOperator" "googleCasIssuer" }}
{{ . }}:
  {{- $op := list $.Values "global" "armonik" "operators" . | include "armonik.utils.index" | fromYaml }}
  available: {{ $op.available | empty | not }}
  deploy:    {{ $op.deploy    | empty | not }}
  namespace: {{ tpl ($op.namespace | default "") $ | quote }}
{{- end }}
{{- end -}}
