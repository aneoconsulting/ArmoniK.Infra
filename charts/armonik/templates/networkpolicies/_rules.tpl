
{{/*
  Generic namespace selector: matches the current namespace of the subchart
  passed in context
*/}}
{{- define "armonik.netpol.namespaceSelector" -}}
matchLabels:
  kubernetes.io/metadata.name: {{ include "armonik.namespace" . | quote }}
{{- end -}}


{{/*
  Pod selector for MongoDB (Percona server).
*/}}
{{- define "armonik.netpol.mongodbSelector" -}}
matchLabels:
  app.kubernetes.io/name: percona-server-mongodb
{{- end -}}


{{/*
  Pod selector for the MongoDB operator.
*/}}
{{- define "armonik.netpol.mongodbOperatorSelector" -}}
matchLabels:
  app.kubernetes.io/name: mongodb-operator
{{- end -}}


{{/*
  Allows the control-plane as a source
*/}}
{{- define "armonik.netpol.rule.controlPlaneFrom" -}}
{{- with index .Subcharts "control-plane" -}}
from:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      matchLabels:
        app.kubernetes.io/name: control-plane
{{- end -}}
{{- end -}}


{{/*
  Allows the compute-plane as a source
*/}}
{{- define "armonik.netpol.rule.computePlaneFrom" -}}
{{- with index .Subcharts "compute-plane" -}}
from:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      matchLabels:
        app.kubernetes.io/name: compute-plane
{{- end -}}
{{- end -}}


{{/*
  Egress to MongoDB.
*/}}
{{- define "armonik.netpol.rule.mongodb" -}}
{{- with .Subcharts.dependencies.Subcharts.mongodb -}}
to:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      {{- include "armonik.netpol.mongodbSelector" . | nindent 6 }}
ports:
  - protocol: TCP
    port: {{ include "armonik.mongodb.port" . | trim | int }}
{{- end -}}
{{- end -}}


{{/*
  Egress to RabbitMQ.
*/}}
{{- define "armonik.netpol.rule.rabbitmq" -}}
{{- with .Subcharts.dependencies.Subcharts.rabbitmq -}}
to:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      matchLabels:
        app.kubernetes.io/name: rabbitmq
ports:
  - protocol: TCP
    port: {{ include "armonik.rabbitmq.port" . | trim | int }}
{{- end -}}
{{- end -}}


{{/*
  Egress to ActiveMQ.
*/}}
{{- define "armonik.netpol.rule.activemq" -}}
{{- with .Subcharts.dependencies.Subcharts.activemq -}}
to:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      matchLabels:
        app.kubernetes.io/name: activemq
ports:
  - protocol: TCP
    port: {{ .Values.containerPort.amqp | int }}
{{- end -}}
{{- end -}}


{{/*
  Egress to Redis.
*/}}
{{- define "armonik.netpol.rule.redis" -}}
{{- with .Subcharts.dependencies.Subcharts.redis -}}
to:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      matchLabels:
        app.kubernetes.io/name: redis
ports:
  - protocol: TCP
    port: {{ include "armonik.redis.port" . | trim | int }}
{{- end -}}
{{- end -}}


{{/*
  Egress to Seq.
*/}}
{{- define "armonik.netpol.rule.seq" -}}
{{- with .Subcharts.dependencies.Subcharts.seq -}}
to:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      matchLabels:
        app: seq
ports:
  - protocol: TCP
    port: 5341
{{- end -}}
{{- end -}}


{{/*
  Operator ingress: from the MongoDB server.
*/}}
{{- define "armonik.netpol.rule.mongodbOperatorFrom" -}}
{{- with .Subcharts.dependencies.Subcharts.mongodb -}}
from:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      {{- include "armonik.netpol.mongodbSelector" . | nindent 6 }}
{{- end -}}
{{- end -}}


{{/*
  Operator egress: to the MongoDB server and to cert-manager.
*/}}
{{- define "armonik.netpol.rule.mongodbOperatorTo" -}}
{{- with .Subcharts.dependencies.Subcharts.mongodb -}}
to:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      {{- include "armonik.netpol.mongodbSelector" . | nindent 6 }}
{{- end }}

{{- with index .Subcharts.dependencies.Subcharts "cert-manager" -}}
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      matchLabels:
        app.kubernetes.io/name: cert-manager
{{- end }}
ports:
  - protocol: TCP
    port: {{ include "armonik.mongodb.port" . | trim | int }}
{{- end -}}


{{/*
  Server ingress: from the MongoDB operator.
*/}}
{{- define "armonik.netpol.rule.mongodbServerFromOperator" -}}
{{- with .Subcharts.dependencies.Subcharts.mongodb -}}
from:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      {{- include "armonik.netpol.mongodbOperatorSelector" . | nindent 6 }}
{{- end -}}
{{- end -}}


{{/*
  Server egress: to the MongoDB operator.
*/}}
{{- define "armonik.netpol.rule.mongodbServerToOperator" -}}
{{- with .Subcharts.dependencies.Subcharts.mongodb -}}
to:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      {{- include "armonik.netpol.mongodbOperatorSelector" . | nindent 6 }}
{{- end -}}
{{- end -}}


{{/*
  All egress rules towards dependencies (mongo, rabbitmq, activemq, redis).
  Used by both control-plane and compute-plane.
*/}}
{{- define "armonik.netpol.dependencyRules" -}}
{{- $rules := list
      (include "armonik.netpol.rule.mongodb" . | fromYaml)
      (include "armonik.netpol.rule.rabbitmq" . | fromYaml)
      (include "armonik.netpol.rule.activemq" . | fromYaml)
      (include "armonik.netpol.rule.redis" . | fromYaml)
-}}
{{- $rules | compact | toYaml -}}
{{- end -}}

{{/*
  Control-plane (submitter): egress to all dependencies.
*/}}
{{- define "armonik.netpol.controlPlaneSubmitterEgress" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: control-plane
policyTypes:
  - Egress
egress:
  rules:
    {{- include "armonik.netpol.dependencyRules" . | nindent 4 }}
  extraRules: []
{{- end -}}


{{/*
  Control-plane (metrics-exporter): egress to MongoDB only.
*/}}
{{- define "armonik.netpol.controlPlaneMetricsExporterEgress" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/component: metrics-exporter
policyTypes:
  - Egress
egress:
  rules:
    - {{- include "armonik.netpol.rule.mongodb" . | nindent 6 }}
  extraRules: []
{{- end -}}


{{/*
  Compute-plane: egress to all dependencies.
*/}}
{{- define "armonik.netpol.computePlaneEgress" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: compute-plane
policyTypes:
  - Egress
egress:
  rules:
    {{- include "armonik.netpol.dependencyRules" . | nindent 4 }}
  extraRules: []
{{- end -}}


{{/*
  Fluent-bit: egress to DNS + kube-api + Seq.
*/}}
{{- define "armonik.netpol.fluentBitEgress" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: fluent-bit
policyTypes:
  - Egress
egress:
  rules:
    {{- list
          (include "armonik.netpol.dnsRule" dict | fromYaml)
          (include "armonik.netpol.kubeApiRule" dict | fromYaml)
          (include "armonik.netpol.rule.seq" . | fromYaml)
        | toYaml
        | nindent 4
    }}
{{- end -}}


{{/*
  MongoDB operator: ingress from the server, egress to the server +
  cert-manager + DNS + kube-api.
*/}}
{{- define "armonik.netpol.mongodbOperator" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: mongodb-operator

policyTypes:
  - Ingress
  - Egress

ingress:
  rules:
    {{- list
          (include "armonik.netpol.rule.mongodbOperatorFrom" . | fromYaml)
        | compact
        | toYaml
        | nindent 4
    }}

egress:
  rules:
    {{- list
          (include "armonik.netpol.rule.mongodbOperatorTo" . | fromYaml)
          (include "armonik.netpol.dnsRule" dict | fromYaml)
          (include "armonik.netpol.kubeApiRule" dict | fromYaml)
        | compact
        | toYaml
        | nindent 4
    }}
{{- end -}}


{{/*
  MongoDB server: ingress from the operator + control-plane + compute-plane,
  egress to the operator + DNS.
*/}}
{{- define "armonik.netpol.mongodbServer" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/name: percona-server-mongodb

policyTypes:
  - Ingress
  - Egress

ingress:
  rules:
    {{- list
          (include "armonik.netpol.rule.mongodbServerFromOperator" . | fromYaml)
          (include "armonik.netpol.rule.controlPlaneFrom" . | fromYaml)
          (include "armonik.netpol.rule.computePlaneFrom" . | fromYaml)
        | compact
        | toYaml
        | nindent 4
    }}

egress:
  rules:
    {{- list
          (include "armonik.netpol.rule.mongodbServerToOperator" . | fromYaml)
          (include "armonik.netpol.dnsRule" dict | fromYaml)
        | compact
        | toYaml
        | nindent 4
    }}
{{- end -}}


{{/*
  wait-cert-manager job: egress to DNS + kube-api only.
*/}}
{{- define "armonik.netpol.waitCertManagerEgress" -}}
policyTypes:
  - Egress
egress:
  rules:
    {{- list
          (include "armonik.netpol.dnsRule" dict | fromYaml)
          (include "armonik.netpol.kubeApiRule" dict | fromYaml)
        | toYaml
        | nindent 4
    }}
{{- end -}}
