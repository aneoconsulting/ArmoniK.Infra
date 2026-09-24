{{/*
Service this chart puts in front of seq's ingestion (services/seq-ingestion.yaml). Named from the
release name alone, so that a scope blind to seq's values (fluent-bit's tpl) still derives it exactly.
Takes the release name.
*/}}
{{- define "armonik.seq.ingestionService" -}}
  {{- printf "%s-seq-ingestion" . | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Port of that Service.
*/}}
{{- define "armonik.seq.ingestionPort" -}}
  {{- 5341 -}}
{{- end -}}
