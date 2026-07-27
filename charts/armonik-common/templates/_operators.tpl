{{/*
Per-operator control map for the five install-once cluster operators, read from the cross-chart
global surface `global.armonik.operators.<op>.{available,deploy}`. Returned as YAML; consume with
`fromYaml` (same idiom as `armonik.dependencies`).

  available: the operator's CRDs are present (installed here OR by another release) -> gate CR emission.
  deploy:    THIS release installs the operator (== "managedHere") -> gate CRD-ordering hooks, and the
             `armonik-operators` Chart.yaml install condition (`global.armonik.operators.<op>.deploy`).

Both default to absent -> false here; each chart's values.yaml ships the real defaults
(umbrella: deploy+available true; planes: deploy false / available true).

# Usage

{{- $ops := include "armonik.operators" $ | fromYaml }}
{{- if $ops.keda.available }} ...emit ScaledObject... {{- end }}
{{- if $ops.keda.deploy }} ...emit ordering hook... {{- end }}
*/}}
{{- define "armonik.operators" -}}
externalSecrets:
  available: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "externalSecrets" "available") | empty | not }}
  deploy: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "externalSecrets" "deploy") | empty | not }}
keda:
  available: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "keda" "available") | empty | not }}
  deploy: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "keda" "deploy") | empty | not }}
certManager:
  available: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "certManager" "available") | empty | not }}
  deploy: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "certManager" "deploy") | empty | not }}
mongodbOperator:
  available: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "mongodbOperator" "available") | empty | not }}
  deploy: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "mongodbOperator" "deploy") | empty | not }}
prometheusOperator:
  available: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "prometheusOperator" "available") | empty | not }}
  deploy: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "prometheusOperator" "deploy") | empty | not }}
{{- end -}}
