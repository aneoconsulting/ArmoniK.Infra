{{/*
Name of the Service in front of seq's ingestion port (services/seq-ingestion.yaml). Takes the
release name only, so a scope blind to seq's values (fluent-bit's tpl) derives the same name.
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
