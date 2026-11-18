{{/*
Broker image, the armonik.utils.imageConf result: the single resolution behind the container, the
version label of every resource of this chart (all dedicated to the broker) and NOTES.txt, so they
cannot drift apart.
*/}}
{{- define "activemq.imageConf" -}}
{{- list . "image" .Values.image | include "armonik.utils.imageConf" }}
{{- end }}

{{/* Broker image reference, for NOTES.txt. */}}
{{- define "activemq.image" -}}
{{- include "activemq.imageConf" . | fromYaml | dig "fullname" "" }}
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
