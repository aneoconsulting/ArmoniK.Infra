{{/* Pod-template fragments: armonik.utils.patch parses what it patches, so each is a define. */}}

{{/* ActiveMQ broker container: amqp and dashboard ports, JVM heap from activemqOptsMemory. */}}
{{- define "activemq.container" -}}
{{- $v := .root.Values -}}
{{- $image := list .root "image" $v.image | include "armonik.utils.imageConf" | fromYaml -}}
name: activemq
{{- with $v.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
image: {{ $image.fullname | quote }}
imagePullPolicy: {{ $image.pullPolicy | quote }}
ports:
  - containerPort: {{ $v.containerPort.amqp }}
    name: amqp
    protocol: TCP
  - containerPort: {{ $v.containerPort.dashboard }}
    name: dashboard
    protocol: TCP
env:
  - name: ACTIVEMQ_OPTS_MEMORY
    value: {{ $v.activemqOptsMemory }}
  {{- with $v.extraEnv }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with $v.extraEnvFrom }}
envFrom:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- /* Single-file overrides: mounting the whole conf/ directory would hide the rest of the image's
       own conf/ tree (jetty-spring.xml, conf/jetty/*.xml, login.config, ...), which it still needs. */}}
volumeMounts:
  - mountPath: /opt/apache-activemq/conf/activemq.xml
    subPath: activemq.xml
    mountPropagation: None
    name: activemq-conf-xml
    readOnly: true
  - mountPath: /opt/apache-activemq/conf/log4j2.properties
    subPath: log4j2.properties
    mountPropagation: None
    name: activemq-conf-xml
    readOnly: true
  - mountPath: /opt/apache-activemq/conf/jolokia-access.xml
    subPath: jolokia-access.xml
    mountPropagation: None
    name: activemq-jolokia-xml
    readOnly: true
  {{- with $v.extraVolumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}


{{/* Broker pod spec: the patched container plus scheduling and the extra* additions. */}}
{{- define "activemq.podSpec" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $container := list (include "activemq.container" .) $v.containerPatch "containerPatch" | include "armonik.utils.patch" | fromYaml -}}
{{- $containers := $v.extraContainers | default list | concat (list $container) -}}
{{- range $v.extraVolumes }}
  {{- if has .name (list "activemq-conf-xml" "activemq-jolokia-xml") }}
    {{- printf "extraVolumes.%s: the chart mounts that volume itself; drop it from extraVolumes (and its extraVolumeMounts)." .name | fail }}
  {{- end }}
{{- end }}
{{- with $v.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- $containers | toYaml | nindent 2 }}
{{- with concat ($v.image.imagePullSecrets | default list) ($v.global.imagePullSecrets | default list) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
volumes:
  - name: activemq-conf-xml
    configMap:
      name: {{ include "activemq.configsName" $root | quote }}
      defaultMode: 420
      optional: false
  - name: activemq-jolokia-xml
    configMap:
      name: {{ include "activemq.jolokiaConfigsName" $root | quote }}
      defaultMode: 420
      optional: false
  {{- with $v.extraVolumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with $v.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
{{- with tpl ($v.serviceAccountName | default "") $root }}
serviceAccountName: {{ . | quote }}
{{- end }}
{{- with $v.topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
