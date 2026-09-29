{{/*
Broker image reference, resolved as the container resolves it so NOTES.txt matches the pod.
*/}}
{{- define "activemq.image" -}}
{{- list . "image" .Values.image | include "armonik.utils.imageConf" | fromYaml | dig "fullname" "" }}
{{- end }}

{{/*
Name of the ConfigMap holding activemq.xml and log4j2.properties.
*/}}
{{- define "activemq.configsName" -}}
{{- include "armonik.fullname" . }}-configs
{{- end }}

{{/*
Name of the ConfigMap holding jolokia-access.xml.
*/}}
{{- define "activemq.jolokiaConfigsName" -}}
{{- include "armonik.fullname" . }}-jolokia-configs
{{- end }}
