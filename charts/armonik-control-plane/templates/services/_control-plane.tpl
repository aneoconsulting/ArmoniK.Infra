{{/*
Control-plane Service, shared by the main and the events Deployments. Takes dict "root" $ "component"
<app.kubernetes.io/component of the pods> "name" <Service name>.
*/}}
{{- define "armonik.control.service" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name | quote }}
  namespace: {{ include "armonik.namespace" $root }}
  labels:
    app.kubernetes.io/component: {{ .component | quote }}
    {{- include "armonik.labels" (include "armonik.control.imageConf" $root | fromYaml | list $root) | nindent 4 }}
    {{- with $v.service.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with coalesce $v.service.annotations $v.annotations}}
  annotations:
  {{- range $key, $value := . }}
    {{ $key }}: {{ $value }}
  {{- end }}
  {{- end }}
spec:
{{- if eq $v.service.serviceType "HeadLess" }}
  type: "ClusterIP"
  clusterIP: "None"
{{ else }}
  type: {{ $v.service.serviceType | quote}}
  clusterIP: null
{{- end }}
  selector:
    app.kubernetes.io/component: {{ .component | quote }}
    {{- include "armonik.selectorLabels" $root | nindent 4 }}
  ports:
    - name: {{ $v.service.name }}
    {{- if (eq $v.service.serviceType "HeadLess") -}}
      {{ $firstPort := index $v.ports 0 }}
      port: {{ $firstPort.containerPort }}
    {{ else }}
      {{- range $v.service.ports }}
      port: {{ .port }}
      targetPort: {{ .targetPort }}
      {{- end }}
      protocol: "TCP"
    {{- end }}
{{- end -}}
