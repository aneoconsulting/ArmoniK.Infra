# armonik

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.31.2](https://img.shields.io/badge/AppVersion-0.31.2-informational?style=flat-square)

A Helm chart for Armonik

**Homepage:** <https://github.com/aneoconsulting/ArmoniK>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Aneo | <armonik-support@aneo.fr> | <armonik.fr> |

## Source Code

* <https://aneoconsulting.github.io/>

## Requirements

Kubernetes: `>=v1.25.0-0`

| Repository | Name | Version |
|------------|------|---------|
| file://charts/activemq | activemq | 1.x.x |
| file://charts/compute-plane | compute-plane | 0.1.x |
| file://charts/control-plane | control-plane | 0.1.x |
| file://charts/ingress | ingress | 0.1.x |
| https://charts.bitnami.com/bitnami | fluent-bit | 2.x.x |
| https://charts.bitnami.com/bitnami | kube-prometheus | 11.x.x |
| https://charts.bitnami.com/bitnami | mongodb | 16.x.x |
| https://charts.bitnami.com/bitnami | rabbitmq | 15.x.x |
| https://charts.bitnami.com/bitnami | redis | 20.x.x |
| https://charts.jetstack.io | cert-manager | 1.x.x |
| https://grafana.github.io/helm-charts | grafana | 8.x.x |
| https://helm.datalust.co | seq | 2024.x.x |
| https://kedacore.github.io/charts | keda | 2.x.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| activemq.fullnameOverride | string | `"activemq"` |  |
| activemq.replicas | int | `1` |  |
| cert-manager.fullnameOverride | string | `"cert-manager"` |  |
| cert-manager.installCRDs | bool | `true` |  |
| cert-manager.prometheus.servicemonitor.enabled | bool | `true` |  |
| fluent-bit.config.customParsers | string | `"[PARSER]\n    Name   apache\n    Format regex\n    Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \\[(?<time>[^\\]]*)\\] \"(?<method>\\S+)(?: +(?<path>[^\\\"]*?)(?: +\\S*)?)?\" (?<code>[^ ]*) (?<size>[^ ]*)(?: \"(?<referer>[^\\\"]*)\" \"(?<agent>[^\\\"]*)\")?$\n    Time_Key time\n    Time_Format %d/%b/%Y:%H:%M:%S %z\n[PARSER]\n    Name   apache2\n    Format regex\n    Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \\[(?<time>[^\\]]*)\\] \"(?<method>\\S+)(?: +(?<path>[^ ]*) +\\S*)?\" (?<code>[^ ]*) (?<size>[^ ]*)(?: \"(?<referer>[^\\\"]*)\" \"(?<agent>[^\\\"]*)\")?$\n    Time_Key time\n    Time_Format %d/%b/%Y:%H:%M:%S %z\n[PARSER]\n    Name   apache_error\n    Format regex\n    Regex  ^\\[[^ ]* (?<time>[^\\]]*)\\] \\[(?<level>[^\\]]*)\\](?: \\[pid (?<pid>[^\\]]*)\\])?( \\[client (?<client>[^\\]]*)\\])? (?<message>.*)$\n[PARSER]\n    Name   nginx\n    Format regex\n    Regex ^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \\[(?<time>[^\\]]*)\\] \"(?<method>\\S+)(?: +(?<path>[^\\\"]*?)(?: +\\S*)?)?\" (?<code>[^ ]*) (?<size>[^ ]*)(?: \"(?<referer>[^\\\"]*)\" \"(?<agent>[^\\\"]*)\")?$\n    Time_Key time\n    Time_Format %d/%b/%Y:%H:%M:%S %z\n[PARSER]\n    Name   json\n    Format json\n    Time_Key time\n    Time_Format %d/%b/%Y:%H:%M:%S %z\n[PARSER]\n    Name        docker\n    Format      json\n    Time_Key    time\n    Time_Format %Y-%m-%dT%H:%M:%S.%L\n    Time_Keep   On\n[PARSER]\n    Name cri\n    Format regex\n    Regex ^(?:(?<time>[^\\s]+)\\s+(?<stream>\\w+)\\s+(?<logtag>\\w+)\\s+)?(?<message>\\{.*\\})$\n    Time_Key time\n    Time_Format %Y-%m-%dT%H:%M:%S.%L\n    Time_Keep On\n[PARSER]\n    Name        syslog\n    Format      regex\n    Regex       ^\\<(?<pri>[0-9]+)\\>(?<time>[^ ]* {1,2}[^ ]* [^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\\/\\.\\-]*)(?:\\[(?<pid>[0-9]+)\\])?(?:[^\\:]*\\:)? *(?<message>.*)$\n    Time_Key    time\n    Time_Format %b %d %H:%M:%S\n"` |  |
| fluent-bit.config.filters | string | `"[FILTER]\n    Name                kubernetes\n    Match               *\n    Kube_URL            https://kubernetes.default.svc:443\n    Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n    Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token\n    Kube_Tag_Prefix     kube.var.log.containers.\n    Merge_Log           On\n    Merge_Log_Key       log\n    Merge_Log_Trim      On\n    Merge_Parser        json\n    Keep_Log            Off\n    Annotations         On\n    Labels              On\n    K8S-Logging.Parser  On\n    K8S-Logging.Exclude Off\n    Buffer_Size         0\n[FILTER]\n    Name                    parser\n    Match                   *\n    key_name                message\n    Parser                  json\n[FILTER]\n    Name                    nest\n    Match                   *\n    Operation               lift\n    Nested_under            kubernetes\n    Add_prefix              kubernetes_\n[FILTER]\n    Name                    nest\n    Match                   *\n    Operation               lift\n    Nested_under            message\n[FILTER]\n    Name                    modify\n    Match                   *\n    Condition               Key_exists message\n    Rename                  message @m\n    Add                     sourcetype renamelog\n"` |  |
| fluent-bit.config.inputs | string | `"[INPUT]\n    Name               tail\n    Tag                kube.*\n    Path               /var/log/containers/control-plane*.log, /var/log/containers/compute-plane*.log\n    Parser             cri\n    Docker_Mode        On\n    Buffer_Chunk_Size  512KB\n    Buffer_Max_Size    5M\n    Rotate_Wait        30\n    Mem_Buf_Limit      30MB\n    Skip_Long_Lines    Off\n    Refresh_Interval   10\n    READ_FROM_HEAD     On\n[INPUT]\n    Name               tail\n    Tag                application.*\n    Path               /var/log/containers/control-plane*.log, /var/log/containers/compute-plane*.log, /var/log/containers/ingress*.log, /var/log/containers/mongodb*.log, /var/log/containers/keda*.log\n    Parser             cri\n    Docker_Mode        On\n    Buffer_Chunk_Size  512KB\n    Buffer_Max_Size    5M\n    Rotate_Wait        30\n    Mem_Buf_Limit      30MB\n    Skip_Long_Lines    Off\n    Refresh_Interval   10\n    READ_FROM_HEAD     On\n[INPUT]\n    Name               tail\n    Tag                s3-application.*\n    Path               /var/log/containers/control-plane*.log, /var/log/containers/compute-plane*.log, /var/log/containers/ingress*.log, /var/log/containers/mongodb*.log, /var/log/containers/keda*.log\n    Parser             cri\n    Docker_Mode        On\n    Buffer_Chunk_Size  512KB\n    Buffer_Max_Size    5M\n    Rotate_Wait        30\n    Mem_Buf_Limit      30MB\n    Skip_Long_Lines    Off\n    Refresh_Interval   10\n    READ_FROM_HEAD     On\n"` |  |
| fluent-bit.config.outputs | string | `"[OUTPUT]\n    Name                    http\n    Match                   kube.*\n    Host                    seq.armonik.svc.cluster.local\n    Port                    5341\n    URI                     /api/events/raw?clef\n    Header                  ContentType application/vnd.serilog.clef\n    Format                  json_lines\n    json_date_key           @t\n    json_date_format        iso8601\n"` |  |
| fluent-bit.daemonset.enabled | bool | `true` |  |
| fluent-bit.extraVolumeMounts | string | `"- name: runlogjournal\n  readOnly: true\n  mountPath: /run/log/journal\n  mountPropagation: None\n- name: dmesg\n  readOnly: true\n  mountPath: /var/log/dmesg\n  mountPropagation: None\n"` |  |
| fluent-bit.extraVolumes | string | `"- name: runlogjournal\n  hostPath:\n    path: /run/log/journal\n    type: ''\n- name: dmesg\n  hostPath:\n    path: /var/log/dmesg\n    type: ''\n"` |  |
| fluent-bit.fullnameOverride | string | `"fluent-bit"` |  |
| fluent-bit.metrics.enabled | bool | `true` |  |
| fluent-bit.metrics.serviceMonitor.enabled | bool | `true` |  |
| global.dependencies.activemq | bool | `false` |  |
| global.dependencies.certManager | bool | `true` |  |
| global.dependencies.computePlane | bool | `true` |  |
| global.dependencies.controlPlane | bool | `true` |  |
| global.dependencies.fluentBit | bool | `true` |  |
| global.dependencies.grafana | bool | `true` |  |
| global.dependencies.ingress | bool | `true` |  |
| global.dependencies.keda | bool | `false` |  |
| global.dependencies.kubePrometheus | bool | `true` |  |
| global.dependencies.mongodb | bool | `true` |  |
| global.dependencies.rabbitmq | bool | `true` |  |
| global.dependencies.redis | bool | `true` |  |
| global.dependencies.seq | bool | `true` |  |
| global.environment.description | string | `"Armonik environment"` |  |
| global.environment.name | string | `"local"` |  |
| global.image.pullPolicy | string | `"IfNotPresent"` |  |
| global.image.registry | string | `""` |  |
| global.imageRegistry | string | `""` |  |
| grafana."grafana.ini"."auth.anonymous".enabled | bool | `true` |  |
| grafana."grafana.ini".anonymous.enabled | bool | `true` |  |
| grafana."grafana.ini".server.domain | string | `"grafana.local"` |  |
| grafana."grafana.ini".server.root_url | string | `"http://grafana.{{ .Release.Namespace }}.svc.cluster.local"` |  |
| grafana."grafana.ini".server.serve_from_sub_path | bool | `true` |  |
| grafana.fullnameOverride | string | `"grafana"` |  |
| grafana.serviceMonitor.enabled | bool | `true` |  |
| grafana.sidecar.dashboards.enabled | bool | `true` |  |
| grafana.sidecar.dashboards.folderAnnotation | string | `"grafana_dashboard_folder"` |  |
| grafana.sidecar.dashboards.label | string | `"grafana_dashboard"` |  |
| grafana.sidecar.dashboards.searchNamespace | string | `"armonik"` |  |
| grafana.sidecar.datasources.enabled | bool | `true` |  |
| ingress.ingress.type | string | `"LoadBalancer"` |  |
| keda.certificates.certManager.enabled | bool | `false` |  |
| keda.certificates.certManager.issuer.generate | bool | `false` |  |
| keda.certificates.certManager.issuer.group | string | `"cert-manager.io"` |  |
| keda.certificates.certManager.issuer.kind | string | `"ClusterIssuer"` |  |
| keda.certificates.certManager.issuer.name | string | `"armonik-selfsigned-issuer"` |  |
| keda.crds.install | bool | `true` |  |
| keda.image.pullPolicy | string | `"IfNotPresent"` |  |
| keda.prometheus.metricServer.enabled | bool | `true` |  |
| keda.prometheus.metricServer.serviceMonitor.enabled | bool | `true` |  |
| kube-prometheus."operator.image.registry" | string | `""` |  |
| kube-prometheus.alertmanager.enabled | bool | `false` |  |
| kube-prometheus.blackboxExporter.enabled | bool | `false` |  |
| kube-prometheus.fullnameOverride | string | `"prometheus"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.enabled | bool | `true` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.external.key | string | `"prometheus-additional.yaml"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.external.name | string | `"additional-scrape-configs"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.type | string | `"external"` |  |
| kube-prometheus.prometheus.evaluationInterval | string | `"30s"` |  |
| kube-prometheus.prometheus.scrapeInterval | string | `"10s"` |  |
| mongodb.architecture | string | `"replicaset"` |  |
| mongodb.fullnameOverride | string | `"mongodb"` |  |
| mongodb.metrics.enabled | bool | `true` |  |
| mongodb.metrics.serviceMonitor.enabled | bool | `true` |  |
| mongodb.persistence.enabled | bool | `false` |  |
| mongodb.replicaCount | int | `1` |  |
| mongodb.replicas | int | `2` |  |
| mongodb.tls.autoGenerated | bool | `true` |  |
| mongodb.tls.enabled | bool | `false` |  |
| mongodb.tls.mode | string | `"allowTLS"` |  |
| mongodb.tls.replicaset.existingSecret | string | `"mongodb-crt"` |  |
| mongodb.useStatefulSet | bool | `true` |  |
| rabbitmq.auth.password | string | `"admin"` |  |
| rabbitmq.auth.username | string | `"admin"` |  |
| rabbitmq.fullnameOverride | string | `"rabbitmq"` |  |
| rabbitmq.metrics.enabled | bool | `true` |  |
| rabbitmq.metrics.serviceMonitor.enabled | bool | `true` |  |
| rabbitmq.persistence.enabled | bool | `false` |  |
| redis.fullnameOverride | string | `"redis"` |  |
| redis.master.containerPorts.redis | int | `6379` |  |
| redis.master.persistence.enabled | bool | `false` |  |
| redis.master.resourcesPreset | string | `"nano"` |  |
| redis.metrics.enabled | bool | `true` |  |
| redis.metrics.serviceMonitor.enabled | bool | `true` |  |
| redis.replica.autoscaling.enabled | bool | `false` |  |
| redis.replica.autoscaling.targetCPU | string | `"80"` |  |
| redis.replica.autoscaling.targetMemory | string | `"80"` |  |
| redis.replica.persistence.enabled | bool | `false` |  |
| redis.replica.replicaCount | int | `1` |  |
| redis.tls.authClients | bool | `false` |  |
| redis.tls.autoGenerated | bool | `false` |  |
| redis.tls.enabled | bool | `false` |  |
| redis.useStatefulSet | bool | `true` |  |
| redis.usernames.admin | string | `"admin"` |  |
| seq.fullnameOverride | string | `"seq"` |  |
| seq.image.pullPolicy | string | `"IfNotPresent"` |  |
| seq.persistence.enabled | bool | `false` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
