{{/* Pod-template fragments: armonik.utils.patch parses what it patches, so each is a define.
     nginx reads the root-level values directly; gui and load-balancer coalesce over them. */}}

{{/* nginx container, the gRPC and HTTP entry point; TLS and mTLS each add a cert mount. */}}
{{- define "armonik.ingress.nginx.container" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
name: ingress
image: {{ .image.fullname | quote }}
imagePullPolicy: {{ .image.pullPolicy | quote }}
ports:
  {{- range $v.ports }}
  - name: {{ .name | quote }}
    containerPort: {{ include "armonik.ingress.containerPort" (dict "protocol" .protocol "root" $root) }}
    protocol: TCP
  {{- end }}
terminationMessagePath: /dev/termination-log
terminationMessagePolicy: File
{{- with $v.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.livenessProbe }}
livenessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.startupProbe }}
startupProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.readinessProbe }}
readinessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.extraEnv }}
env:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.extraEnvFrom }}
envFrom:
  {{- toYaml . | nindent 2 }}
{{- end }}
volumeMounts:
  {{- if list $v "tls" "enabled" | include "armonik.utils.index" }}
  - name: server-cert
    mountPath: /ingress
    mountPropagation: None
    readOnly: true
  {{- end }}
  {{- if list $v "mtls" "enabled" | include "armonik.utils.index" }}
  - name: client-cert
    mountPath: /ingressclient
    mountPropagation: None
    readOnly: true
  {{- end }}
  - mountPath: /etc/nginx/conf.d
    mountPropagation: None
    name: conf
    readOnly: true
  - mountPath: /static
    mountPropagation: None
    name: static
    readOnly: true
  {{- with $v.extraVolumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}


{{/* nginx pod spec: the patched container plus the conf, static and cert volumes. */}}
{{- define "armonik.ingress.nginx.podSpec" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $global := $v.global | default dict -}}
{{- $container := list (include "armonik.ingress.nginx.container" .) $v.containerPatch "containerPatch" | include "armonik.utils.patch" | fromYaml -}}
{{- $containers := $v.extraContainers | default list | concat (list $container) -}}
automountServiceAccountToken: true
{{- with $v.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- $containers | toYaml | nindent 2 }}
dnsPolicy: ClusterFirst
shareProcessNamespace: false
{{- with concat ($v.imagePullSecrets | default list) ($global.imagePullSecrets | default list) }}
imagePullSecrets:
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
{{- with $v.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
enableServiceLinks: true
volumes:
  {{- if list $v "tls" "enabled" | include "armonik.utils.index" }}
  - name: server-cert
    secret:
      defaultMode: 420
      optional: false
      secretName: {{ include "armonik.fullname" $root | printf "%s-tls" | quote }}
  {{- end }}
  {{- if list $v "mtls" "enabled" | include "armonik.utils.index" }}
  {{- $mtlsCa := $v.mtls.certificationAuthority | default dict }}
  - name: client-cert
    secret:
      defaultMode: 420
      optional: false
      secretName: {{ $mtlsCa.existingSecret | default (printf "%s-mtls-ca" (include "armonik.fullname" $root)) | quote }}
  {{- end }}
  - name: conf
    secret:
      secretName: {{ include "armonik.ingress.confName" $root | quote }}
      defaultMode: 420
      optional: false
  - name: static
    configMap:
      name: {{ include "armonik.fullname" $root }}-static
      defaultMode: 420
      optional: false
  {{- with $v.extraVolumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}
