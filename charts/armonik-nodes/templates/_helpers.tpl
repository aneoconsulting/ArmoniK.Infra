{{/* Labels of every object. No armonik-common: the classes are cluster-scoped and release-independent. */}}
{{- define "armonik.nodes.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote }}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/part-of: armonik
{{- end -}}

{{/*
ComputeClass spec of one class, from {root, name, spec}: the spec as written, plus what it leaves unset
among nodePoolAutoCreation.enabled, whenUnsatisfiable and, on a standard class, the gke.defaults.
*/}}
{{- define "armonik.nodes.gke.spec" -}}
  {{- $spec := deepCopy .spec -}}
  {{- $defaults := (.root.Values.gke | default dict).defaults | default dict -}}
  {{- if not (dig "autopilot" "enabled" false $spec) -}}
    {{- $autoCreation := $spec.nodePoolAutoCreation | default dict -}}
    {{- if not (hasKey $autoCreation "enabled") -}}
      {{- $_ := set $autoCreation "enabled" true -}}
    {{- end -}}
    {{- $_ := set $spec "nodePoolAutoCreation" $autoCreation -}}
    {{- with $defaults.serviceAccount -}}
      {{- $config := $spec.nodePoolConfig | default dict -}}
      {{- if not (hasKey $config "serviceAccount") -}}
        {{- $_ := set $config "serviceAccount" . -}}
      {{- end -}}
      {{- $_ := set $spec "nodePoolConfig" $config -}}
    {{- end -}}
    {{- with $defaults.bootDiskKMSKey -}}
      {{- $key := . -}}
      {{- range $spec.priorities -}}
        {{- if not (or (hasKey . "nodepools") (hasKey . "podFamily")) -}}
          {{- $storage := .storage | default dict -}}
          {{- if not (hasKey $storage "bootDiskKMSKey") -}}
            {{- $_ := set $storage "bootDiskKMSKey" $key -}}
          {{- end -}}
          {{- $_ := set . "storage" $storage -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- if not (hasKey $spec "whenUnsatisfiable") -}}
    {{- $_ := set $spec "whenUnsatisfiable" "DoNotScaleUp" -}}
  {{- end -}}
  {{- toYaml $spec -}}
{{- end -}}
