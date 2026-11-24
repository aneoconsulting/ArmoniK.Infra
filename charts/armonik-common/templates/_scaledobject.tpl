{{/*
  KEDA ScaledObject scaling the Deployment of the same name. Takes dict "root" $ "name" <name>
  "labels" <extra labels> "hpa" <block>: `annotations`, plus ScaledObject spec fields passed through as
  written; `enabled` and null fields are dropped, and so is an idleReplicaCount not below minReplicaCount
  (KEDA rejects it), which keeps that many pods when idle. Hooked only when this release installs the KEDA CRDs.
  An optional "image" (the scaled Deployment's armonik.utils.imageConf result) sets the version label,
  see armonik.labels.
*/}}
{{- define "armonik.scaledObject" -}}
  {{- $root := .root -}}
  {{- $ops := include "armonik.operators" $root | fromYaml -}}
  {{- $annotations := .hpa.annotations | default dict -}}
  {{- if $ops.keda.deploy -}}
    {{- $annotations = merge (dict "helm.sh/hook" "post-install,post-upgrade" "helm.sh/hook-weight" "10") $annotations -}}
  {{- end -}}
  {{- $spec := dict "scaleTargetRef" (dict "apiVersion" "apps/v1" "kind" "Deployment" "name" .name) -}}
  {{- range $key, $value := omit .hpa "enabled" "annotations" -}}
    {{- if not (kindIs "invalid" $value) -}}
      {{- $_ := set $spec $key $value -}}
    {{- end -}}
  {{- end -}}
  {{- if and (hasKey $spec "idleReplicaCount") (ge ($spec.idleReplicaCount | int) ($spec.minReplicaCount | default 0 | int)) -}}
    {{- $_ := unset $spec "idleReplicaCount" -}}
  {{- end }}
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: {{ .name | quote }}
  namespace: {{ include "armonik.namespace" $root | quote }}
  {{- with $annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- with .labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- include "armonik.labels" (.image | empty | ternary $root (list $root .image)) | nindent 4 }}
spec:
  {{- toYaml $spec | nindent 2 }}
{{- end -}}
