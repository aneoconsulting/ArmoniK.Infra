{{- define "percona-mongodb.clusterReleaseName" -}}
{{ .Values.name }}-db-ps
{{- end }}

{{- define "percona-mongodb.mongodbDns" -}}
{{- if .Values.sharding }}
{{ include "percona-mongodb.clusterReleaseName" . }}-mongos.{{ .Values.namespace }}.svc.cluster.local
{{- else }}
{{ include "percona-mongodb.clusterReleaseName" . }}-rs0.{{ .Values.namespace }}.svc.cluster.local
{{- end }}
{{- end }}
