{{/*
  Control-plane's control-port container port.
*/}}
{{- define "armonik.netpol.controlPlane.controlPort" -}}
{{- list . (list "control-plane" "ports") "control-port" | include "armonik.netpol.controlPlane.port" -}}
{{- end -}}


{{/*
  Control-plane's metrics-exporter deployment's metrics-port container port.
*/}}
{{- define "armonik.netpol.controlPlane.metricsExporterPort" -}}
{{- list . (list "control-plane" "metricsExporter" "ports") "metrics-port" | include "armonik.netpol.controlPlane.port" -}}
{{- end -}}


{{/*
  podSelector override for a dependency labelled by its operator, not its own chart.
  Args (list): [root, key, name]
*/}}
{{- define "armonik.netpol.podSelector.override" -}}
{{- $root := index . 0 -}}
{{- $key := index . 1 -}}
{{- $name := index . 2 -}}
{{- list (index $root.Values.networkPolicy $key) $name | include "armonik.netpol.podSelector.default" -}}
{{- end -}}


{{/*
  MongoDB's pod selector.
*/}}
{{- define "armonik.netpol.podSelector.mongodb" -}}
{{- list . "mongodbPodSelector" "percona-server-mongodb" | include "armonik.netpol.podSelector.override" -}}
{{- end -}}


{{/*
  KEDA operator's pod selector.
*/}}
{{- define "armonik.netpol.podSelector.keda" -}}
{{- list . "kedaPodSelector" "keda-operator" | include "armonik.netpol.podSelector.override" -}}
{{- end -}}


{{/*
  Generic ingress "from" rule: source namespace + given podSelector.
  Args (list): [root, podSelector]
*/}}
{{- define "armonik.netpol.rule.componentFrom" -}}
{{- $root := index . 0 -}}
{{- $podSelector := index . 1 -}}
from:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" $root | nindent 6 }}
    podSelector:
      {{- toYaml $podSelector | nindent 6 }}
{{- end -}}


{{/*
  Allows the control-plane submitter and init job as a source.
*/}}
{{- define "armonik.netpol.rule.controlPlaneFrom" -}}
{{- $podSelector := dict "matchExpressions" (list
      (dict "key" "app.kubernetes.io/component" "operator" "In" "values" (list "control-plane" "init"))
    ) -}}
{{- list . $podSelector | include "armonik.netpol.rule.componentFrom" -}}
{{- end -}}


{{/*
  Allows the metrics-exporter as a source.
*/}}
{{- define "armonik.netpol.rule.metricsExporterFrom" -}}
{{- $podSelector := dict "matchLabels" (dict "app.kubernetes.io/component" "metrics-exporter") -}}
{{- list . $podSelector | include "armonik.netpol.rule.componentFrom" -}}
{{- end -}}


{{/*
  Allows the compute-plane as a source.
*/}}
{{- define "armonik.netpol.rule.computePlaneFrom" -}}
{{- $podSelector := dict "matchLabels" (dict "app.kubernetes.io/part-of" "compute-plane") -}}
{{- list . $podSelector | include "armonik.netpol.rule.componentFrom" -}}
{{- end -}}

{{/*
  Generic egress rule to a dependency subchart: its namespace + podSelector (override or chart default) 
  + port from portHelper.
  Args (list): [root, dependency name, podSelector override, port helper name]
*/}}
{{- define "armonik.netpol.rule.dependencyTo" -}}
{{- $root := index . 0 -}}
{{- $dep := index . 1 -}}
{{- $podSelector := index . 2 -}}
{{- $portHelper := index . 3 -}}
{{- with index $root.Subcharts.dependencies.Subcharts $dep -}}
to:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      {{- ($podSelector | default (include "armonik.netpol.podSelector" .)) | nindent 6 }}
ports:
  - protocol: TCP
    port: {{ include $portHelper . | trim | int }}
{{- end -}}
{{- end -}}


{{/*
  Egress to MongoDB.
*/}}
{{- define "armonik.netpol.rule.mongodb" -}}
{{- list . "mongodb" (include "armonik.netpol.podSelector.mongodb" .) "armonik.mongodb.port" | include "armonik.netpol.rule.dependencyTo" -}}
{{- end -}}


{{/*
  Egress to RabbitMQ.
*/}}
{{- define "armonik.netpol.rule.rabbitmq" -}}
{{- list . "rabbitmq" "" "armonik.rabbitmq.port" | include "armonik.netpol.rule.dependencyTo" -}}
{{- end -}}


{{/*
  Egress to ActiveMQ.
*/}}
{{- define "armonik.netpol.rule.activemq" -}}
{{- list . "activemq" "" "armonik.activemq.port" | include "armonik.netpol.rule.dependencyTo" -}}
{{- end -}}


{{/*
  Egress to Redis.
*/}}
{{- define "armonik.netpol.rule.redis" -}}
{{- list . "redis" "" "armonik.redis.port" | include "armonik.netpol.rule.dependencyTo" -}}
{{- end -}}


{{/*
  Egress to Seq on the given port.
*/}}
{{- define "armonik.netpol.rule.seqTo" -}}
{{- $root := index . 0 -}}
{{- $port := index . 1 -}}
{{- with $root.Subcharts.dependencies.Subcharts.seq -}}
{{- $ns := include "armonik.netpol.namespaceSelector" . -}}
{{- $podSelector := dict "matchLabels" (dict "app" (include "armonik.name" .)) | toYaml -}}
{{- list $ns $podSelector $port "to" | include "armonik.netpol.rule.peerOnPort" -}}
{{- end -}}
{{- end -}}


{{/*
  Egress to Seq's ingest port (used by fluent-bit).
*/}}
{{- define "armonik.netpol.rule.seq" -}}
{{- list . 5341 | include "armonik.netpol.rule.seqTo" -}}
{{- end -}}


{{/*
  Egress rule: nginx -> control-plane control port.
*/}}
{{- define "armonik.netpol.rule.ingressToControlPlane" -}}
{{- with index .Subcharts "control-plane" -}}
{{- $ns := include "armonik.netpol.namespaceSelector" . -}}
{{- $podSelector := dict "matchLabels" (dict "app.kubernetes.io/component" "control-plane") | toYaml -}}
{{- $controlPort := include "armonik.netpol.port" (dict "ports" .Values.ports "name" "control-port") | int -}}
{{- list $ns $podSelector $controlPort "to" | include "armonik.netpol.rule.peerOnPort" -}}
{{- end -}}
{{- end -}}


{{/*
  Egress rule: nginx -> Grafana.
*/}}
{{- define "armonik.netpol.rule.ingressToGrafana" -}}
{{- with .Subcharts.dependencies.Subcharts.grafana -}}
{{- $ns := include "armonik.netpol.namespaceSelector" . -}}
{{- $podSelector := dict "matchLabels" (dict "app.kubernetes.io/name" "grafana") | toYaml -}}
{{- $port := .Values.service.targetPort | default 3000 -}}
{{- list $ns $podSelector $port "to" | include "armonik.netpol.rule.peerOnPort" -}}
{{- end -}}
{{- end -}}


{{/*
  Egress rule: nginx -> Seq UI port.
*/}}
{{- define "armonik.netpol.rule.ingressToSeq" -}}
{{- list . "ui" | include "armonik.netpol.rule.seqTo" -}}
{{- end -}}


{{/*
  Ingress (nginx) NetworkPolicy: egress-only, to control-plane + Grafana + Seq.
*/}}
{{- define "armonik.netpol.ingressEgress" -}}
{{- with .Subcharts.ingress -}}
namespace: {{ include "armonik.namespace" . | quote }}
podSelector:
  matchLabels:
    app.kubernetes.io/component: ingress
    {{- include "armonik.selectorLabels" . | nindent 4 }}
egress:
  {{- list
        (list "armonik.netpol.rule.ingressToControlPlane" $)
        (list "armonik.netpol.rule.ingressToGrafana" $)
        (list "armonik.netpol.rule.ingressToSeq" $)
    | include "armonik.netpol.mergeRules"
    | nindent 2
  }}
{{- end -}}
{{- end -}}


{{/*
  Operator ingress: from the MongoDB server.
*/}}
{{- define "armonik.netpol.rule.mongodbOperatorFrom" -}}
{{- $root := . -}}
{{- with $root.Subcharts.dependencies.Subcharts.mongodb -}}
from:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      {{- include "armonik.netpol.podSelector.mongodb" $root | nindent 6 }}
{{- end -}}
{{- end -}}


{{/*
  Operator egress: to the MongoDB server and to cert-manager.
*/}}
{{- define "armonik.netpol.rule.mongodbOperatorTo" -}}
{{- $root := . -}}
to:
{{- with $root.Subcharts.dependencies.Subcharts.mongodb }}
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      {{- include "armonik.netpol.podSelector.mongodb" $root | nindent 6 }}
{{- end }}
{{- with index $root.Subcharts.operators.Subcharts "cert-manager" }}
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      {{- include "armonik.netpol.podSelector" . | nindent 6 }}
{{- end }}
ports:
  - protocol: TCP
    port: {{ include "armonik.mongodb.port" . | trim | int }}
{{- end -}}


{{/*
  Shared MongoDB operator<->server rule; direction ("from"/"to") passed as arg.
*/}}
{{- define "armonik.netpol.rule.mongodbServerOperator" -}}
{{- $root := index . 0 -}}
{{- $direction := index . 1 -}}
{{- with $root.Subcharts.dependencies.Subcharts.mongodb -}}
{{- with index $root.Subcharts.operators.Subcharts "mongodb-operator" -}}
{{ $direction }}:
  - namespaceSelector:
      {{- include "armonik.netpol.namespaceSelector" . | nindent 6 }}
    podSelector:
      {{- include "armonik.netpol.podSelector" . | nindent 6 }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
  Server ingress: from the MongoDB operator.
*/}}
{{- define "armonik.netpol.rule.mongodbServerFromOperator" -}}
{{- list . "from" | include "armonik.netpol.rule.mongodbServerOperator" -}}
{{- end -}}


{{/*
  Server egress: to the MongoDB operator.
*/}}
{{- define "armonik.netpol.rule.mongodbServerToOperator" -}}
{{- list . "to" | include "armonik.netpol.rule.mongodbServerOperator" -}}
{{- end -}}


{{/*
  Egress to mongo, rabbitmq, activemq, redis + DNS. Shared by control-plane and compute-plane.
*/}}
{{- define "armonik.netpol.dependencyRules" -}}
{{- $rules := list
  (list "armonik.netpol.rule.mongodb" .)
  (list "armonik.netpol.rule.rabbitmq" .)
  (list "armonik.netpol.rule.activemq" .)
  (list "armonik.netpol.rule.redis" .)
  (list "armonik.netpol.dnsRule" dict)
-}}
{{- $rules | include "armonik.netpol.mergeRules" -}}
{{- end -}}

{{/*
  Allows nginx as a source on the control-plane's control port.
*/}}
{{- define "armonik.netpol.rule.ingressFrom" -}}
{{- with .Subcharts.ingress -}}
{{- $controlPort := include "armonik.netpol.controlPlane.controlPort" $ | int -}}
{{- $ns := include "armonik.netpol.namespaceSelector" . -}}
{{- $podSelector := dict "matchLabels" (dict "app.kubernetes.io/component" "ingress") | toYaml -}}
{{- list $ns $podSelector $controlPort "from" | include "armonik.netpol.rule.peerOnPort" -}}
{{- end -}}
{{- end -}}


{{/*
  Submitter ingress: from compute-plane and nginx (grpc/http).
  Prometheus scraping (/metrics) is handled separately, in control-plane's own chart-local policy.
*/}}
{{- define "armonik.netpol.rule.submitterIngress" -}}
{{- list
      (list "armonik.netpol.rule.computePlaneFrom" .)
      (list "armonik.netpol.rule.ingressFrom" .)
    | include "armonik.netpol.mergeRules"
-}}
{{- end -}}


{{/*
  Control-plane submitter + init job: same egress needs, init has no ingress of
  its own, so they share one policy.
*/}}
{{- define "armonik.netpol.controlPlaneSubmitter" -}}
podSelector:
  matchExpressions:
    - key: app.kubernetes.io/component
      operator: In
      values:
        - control-plane
        - init
ingress:
  {{- include "armonik.netpol.rule.submitterIngress" . | nindent 2 }}
egress:
  {{- include "armonik.netpol.dependencyRules" . | nindent 2 }}
{{- end -}}


{{/*
  Allows KEDA to scrape the control plane's metrics endpoint (needed for HPA scaling decisions).
  KEDA's namespace is resolved via armonik.operators since KEDA can be deployed either in this
  release or in a separate operators release.
*/}}
{{- define "armonik.netpol.rule.controlPlaneMetricsExporterIngress" -}}
{{- $root := . -}}
{{- $ops := include "armonik.operators" $root | fromYaml -}}
{{- if and $ops.keda.available $ops.keda.namespace }}
{{- $metricsPort := include "armonik.netpol.controlPlane.metricsExporterPort" $root | int -}}
- from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: {{ $ops.keda.namespace | quote }}
      podSelector:
        {{- include "armonik.netpol.podSelector.keda" $root | nindent 8 }}
  ports:
    - protocol: TCP
      port: {{ $metricsPort }}
{{- end }}
{{- end -}}


{{/*
  Metrics-exporter: ingress from KEDA, egress to MongoDB + DNS.
*/}}
{{- define "armonik.netpol.controlPlaneMetricsExporter" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/component: metrics-exporter
ingress:
  {{- include "armonik.netpol.rule.controlPlaneMetricsExporterIngress" . | nindent 2 }}
egress:
  {{- list
        (list "armonik.netpol.rule.mongodb" .)
        (list "armonik.netpol.dnsRule" dict)
    | include "armonik.netpol.mergeRules"
    | nindent 2
  }}
{{- end -}}


{{/*
  Compute-plane: egress to dependencies + DNS.
*/}}
{{- define "armonik.netpol.computePlaneConnectivity" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/part-of: compute-plane
egress:
  {{- include "armonik.netpol.dependencyRules" . | nindent 2 }}
{{- end -}}


{{/*
  Fluent-bit: egress to DNS + kube-api + Seq.
*/}}
{{- define "armonik.netpol.fluentBitEgress" -}}
{{- $root := . -}}
{{- with index $root.Subcharts.dependencies.Subcharts "fluent-bit" -}}
namespace: {{ include "armonik.namespace" . | quote }}
podSelector:
  {{- include "armonik.netpol.podSelector" . | nindent 2 }}
egress:
  {{- list
        (list "armonik.netpol.dnsRule" dict)
        (list "armonik.netpol.kubeApiRule" dict)
        (list "armonik.netpol.rule.seq" $root)
    | include "armonik.netpol.mergeRules"
    | nindent 2
  }}
{{- end -}}
{{- end -}}


{{/*
  MongoDB operator: ingress from the server, egress to the server + cert-manager + DNS + kube-api.
*/}}
{{- define "armonik.netpol.mongodbOperator" -}}
{{- $root := . -}}
{{- with index $root.Subcharts.operators.Subcharts "mongodb-operator" -}}
namespace: {{ include "armonik.namespace" . | quote }}
podSelector:
  {{- include "armonik.netpol.podSelector" . | nindent 2 }}

ingress:
  {{- list (list "armonik.netpol.rule.mongodbOperatorFrom" $root) | include "armonik.netpol.mergeRules" | nindent 2 }}

egress:
  {{- list
        (list "armonik.netpol.rule.mongodbOperatorTo" $root)
        (list "armonik.netpol.dnsRule" dict)
        (list "armonik.netpol.kubeApiRule" dict)
    | include "armonik.netpol.mergeRules"
    | nindent 2
  }}
{{- end -}}
{{- end -}}


{{/*
  MongoDB server: ingress from the operator + control-plane + compute-plane,
  egress to the operator + DNS.
*/}}
{{- define "armonik.netpol.mongodbServer" -}}
{{- $root := . -}}
{{- with $root.Subcharts.dependencies.Subcharts.mongodb -}}
namespace: {{ include "armonik.namespace" . | quote }}
podSelector:
  {{- include "armonik.netpol.podSelector.mongodb" $root | nindent 2 }}

ingress:
  {{- list
        (list "armonik.netpol.rule.mongodbServerFromOperator" $root)
        (list "armonik.netpol.rule.controlPlaneFrom" $root)
        (list "armonik.netpol.rule.metricsExporterFrom" $root)
        (list "armonik.netpol.rule.computePlaneFrom" $root)
    | include "armonik.netpol.mergeRules"
    | nindent 2
  }}

egress:
  {{- list
        (list "armonik.netpol.rule.mongodbServerToOperator" $root)
        (list "armonik.netpol.dnsRule" dict)
    | include "armonik.netpol.mergeRules"
    | nindent 2
  }}
{{- end -}}
{{- end -}}


{{/*
  wait-cert-manager job: egress to DNS + kube-api only.
*/}}
{{- define "armonik.netpol.waitCertManagerEgress" -}}
podSelector:
  matchLabels:
    app.kubernetes.io/component: wait-cert-manager
    {{- include "armonik.selectorLabels" . | nindent 4 }}
egress:
  {{- list
        (list "armonik.netpol.dnsRule" dict)
        (list "armonik.netpol.kubeApiRule" dict)
    | include "armonik.netpol.mergeRules"
    | nindent 2
  }}
{{- end -}}


{{/*
  Redis/valkey server: ingress from control-plane/init + compute-plane.
*/}}
{{- define "armonik.netpol.redisServer" -}}
{{- $root := . -}}
{{- with $root.Subcharts.dependencies.Subcharts.redis -}}
namespace: {{ include "armonik.namespace" . | quote }}
podSelector:
  {{- include "armonik.netpol.podSelector" . | nindent 2 }}
ingress:
  {{- list
        (list "armonik.netpol.rule.controlPlaneFrom" $root)
        (list "armonik.netpol.rule.computePlaneFrom" $root)
    | include "armonik.netpol.mergeRules"
    | nindent 2
  }}
{{- end -}}
{{- end -}}


{{/*
  KEDA operator egress: to this release's control-plane metrics-exporter (target of the
  default metrics-api ScaledObject). KEDA's chart already grants DNS + Kubernetes API by
  default; this adds the ArmoniK-specific target without touching that third-party chart.
  Namespace resolved via armonik.operators.
*/}}
{{- define "armonik.netpol.kedaMetricsEgress" -}}
{{- $root := . -}}
{{- $ops := include "armonik.operators" $root | fromYaml -}}
{{- $metricsPort := include "armonik.netpol.controlPlane.metricsExporterPort" $root | int -}}
namespace: {{ $ops.keda.namespace | quote }}
podSelector:
  {{- include "armonik.netpol.podSelector.keda" $root | nindent 2 }}
egress:
  - to:
      - namespaceSelector:
          {{- include "armonik.netpol.namespaceSelector" $root | nindent 10 }}
        podSelector:
          matchLabels:
            app.kubernetes.io/component: metrics-exporter
    ports:
      - protocol: TCP
        port: {{ $metricsPort }}
{{- end -}}
