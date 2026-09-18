{{/* Pod-template fragments: armonik.utils.patch parses what it patches, so each is a define.
     Scheduling and sizing coalesce over the chart-level values; patches and extras do not. */}}

{{/* Load-balancer container: reads lb.yml and the cluster certs at startup only. */}}
{{- define "armonik.ingress.lb.container" -}}
{{- $v := .root.Values -}}
{{- $lb := $v.loadBalancer -}}
name: load-balancer
image: {{ .image.fullname | quote }}
imagePullPolicy: {{ .image.pullPolicy | quote }}
args: ["-c", "/conf/lb.yml"]
ports:
  - name: grpc
    containerPort: {{ $lb.conf.listenPort }}
    protocol: TCP
terminationMessagePath: /dev/termination-log
terminationMessagePolicy: File
{{- with coalesce $lb.resources $v.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $lb.livenessProbe }}
livenessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $lb.startupProbe }}
startupProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $lb.readinessProbe }}
readinessProbe:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $lb.extraEnv }}
env:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $lb.extraEnvFrom }}
envFrom:
  {{- toYaml . | nindent 2 }}
{{- end }}
volumeMounts:
  - name: cluster-certs
    mountPath: /cluster-certs
    mountPropagation: None
    readOnly: true
  - name: lb-conf
    mountPath: /conf
    mountPropagation: None
    readOnly: true
  {{- with $lb.extraVolumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}


{{/* Load-balancer pod spec: the patched container plus its conf and cluster-cert volumes. */}}
{{- define "armonik.ingress.lb.podSpec" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $lb := $v.loadBalancer -}}
{{- $global := $v.global | default dict -}}
{{- $container := list (include "armonik.ingress.lb.container" .) $lb.containerPatch "loadBalancer.containerPatch" | include "armonik.utils.patch" | fromYaml -}}
{{- $containers := $lb.extraContainers | default list | concat (list $container) -}}
automountServiceAccountToken: true
{{- with concat ($lb.imagePullSecrets | default list) ($v.imagePullSecrets | default list) ($global.imagePullSecrets | default list) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $lb.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- $containers | toYaml | nindent 2 }}
dnsPolicy: ClusterFirst
shareProcessNamespace: false
{{- with coalesce $lb.nodeSelector $v.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $lb.affinity $v.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $lb.tolerations $v.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with coalesce $lb.priorityClassName $v.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
enableServiceLinks: true
volumes:
  - name: cluster-certs
    secret:
      secretName: {{ include "armonik.fullname" $root | printf "%s-lb-cluster-certs" | trunc 63 | trimSuffix "-" | quote }}
      defaultMode: 420
      optional: false
  - name: lb-conf
    configMap:
      name: {{ include "armonik.fullname" $root | printf "%s-load-balancer-conf" | trunc 63 | trimSuffix "-" | quote }}
      defaultMode: 420
      optional: false
  {{- with $lb.extraVolumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}
