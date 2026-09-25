{{/*
The image to use, resolved exactly as the container resolves it so NOTES.txt cannot drift from the pod.
*/}}
{{- define "activemq.image" -}}
{{- list . "image" .Values.image | include "armonik.utils.imageConf" | fromYaml | dig "fullname" "" }}
{{- end }}
