{{/*
Create the name of the service account to use
*/}}
{{- define "activemq.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "armonik.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
The image to use, resolved exactly as the container resolves it so NOTES.txt cannot drift from the pod.
*/}}
{{- define "activemq.image" -}}
{{- list . "image" .Values.image | include "armonik.utils.imageConf" | fromYaml | dig "fullname" "" }}
{{- end }}

{{/*
ConfigMap name of addon resizer
*/}}
{{- define "activemq.addonResizer.configMap" -}}
{{- printf "%s-%s" (include "armonik.fullname" .) "nanny-config" }}
{{- end }}

{{/*
Role name of addon resizer
*/}}
{{- define "activemq.addonResizer.role" -}}
{{ printf "system:%s-nanny" (include "armonik.fullname" .) }}
{{- end }}
