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
| activemq.enabled | bool | `true` |  |
| activemq.fullnameOverride | string | `"activemq"` |  |
| activemq.replicas | int | `1` |  |
| cert-manager.cainjector.enabled | bool | `true` |  |
| cert-manager.enabled | bool | `false` |  |
| cert-manager.fullnameOverride | string | `"cert-manager"` |  |
| cert-manager.installCRDs | bool | `true` |  |
| compute-plane.enabled | bool | `true` |  |
| control-plane."config.core.data.Amqp__Host" | string | `"activemq"` |  |
| control-plane.enabled | bool | `true` |  |
| fluent-bit.config.customParsers | string | `"[PARSER]\n    Name   apache\n    Format regex\n    Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \\[(?<time>[^\\]]*)\\] \"(?<method>\\S+)(?: +(?<path>[^\\\"]*?)(?: +\\S*)?)?\" (?<code>[^ ]*) (?<size>[^ ]*)(?: \"(?<referer>[^\\\"]*)\" \"(?<agent>[^\\\"]*)\")?$\n    Time_Key time\n    Time_Format %d/%b/%Y:%H:%M:%S %z\n[PARSER]\n    Name   apache2\n    Format regex\n    Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \\[(?<time>[^\\]]*)\\] \"(?<method>\\S+)(?: +(?<path>[^ ]*) +\\S*)?\" (?<code>[^ ]*) (?<size>[^ ]*)(?: \"(?<referer>[^\\\"]*)\" \"(?<agent>[^\\\"]*)\")?$\n    Time_Key time\n    Time_Format %d/%b/%Y:%H:%M:%S %z\n[PARSER]\n    Name   apache_error\n    Format regex\n    Regex  ^\\[[^ ]* (?<time>[^\\]]*)\\] \\[(?<level>[^\\]]*)\\](?: \\[pid (?<pid>[^\\]]*)\\])?( \\[client (?<client>[^\\]]*)\\])? (?<message>.*)$\n[PARSER]\n    Name   nginx\n    Format regex\n    Regex ^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \\[(?<time>[^\\]]*)\\] \"(?<method>\\S+)(?: +(?<path>[^\\\"]*?)(?: +\\S*)?)?\" (?<code>[^ ]*) (?<size>[^ ]*)(?: \"(?<referer>[^\\\"]*)\" \"(?<agent>[^\\\"]*)\")?$\n    Time_Key time\n    Time_Format %d/%b/%Y:%H:%M:%S %z\n[PARSER]\n    Name   json\n    Format json\n    Time_Key time\n    Time_Format %d/%b/%Y:%H:%M:%S %z\n[PARSER]\n    Name        docker\n    Format      json\n    Time_Key    time\n    Time_Format %Y-%m-%dT%H:%M:%S.%L\n    Time_Keep   On\n[PARSER]\n    Name cri\n    Format regex\n    Regex ^(?:(?<time>[^\\s]+)\\s+(?<stream>\\w+)\\s+(?<logtag>\\w+)\\s+)?(?<message>\\{.*\\})$\n    Time_Key time\n    Time_Format %Y-%m-%dT%H:%M:%S.%L\n    Time_Keep On\n[PARSER]\n    Name        syslog\n    Format      regex\n    Regex       ^\\<(?<pri>[0-9]+)\\>(?<time>[^ ]* {1,2}[^ ]* [^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\\/\\.\\-]*)(?:\\[(?<pid>[0-9]+)\\])?(?:[^\\:]*\\:)? *(?<message>.*)$\n    Time_Key    time\n    Time_Format %b %d %H:%M:%S\n"` |  |
| fluent-bit.config.filters | string | `"[FILTER]\n    Name                kubernetes\n    Match               *\n    Kube_URL            https://kubernetes.default.svc:443\n    Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n    Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token\n    Kube_Tag_Prefix     kube.var.log.containers.\n    Merge_Log           On\n    Merge_Log_Key       log\n    Merge_Log_Trim      On\n    Merge_Parser        json\n    Keep_Log            Off\n    Annotations         On\n    Labels              On\n    K8S-Logging.Parser  On\n    K8S-Logging.Exclude Off\n    Buffer_Size         0\n[FILTER]\n    Name                    parser\n    Match                   *\n    key_name                message\n    Parser                  json\n[FILTER]\n    Name                    nest\n    Match                   *\n    Operation               lift\n    Nested_under            kubernetes\n    Add_prefix              kubernetes_\n[FILTER]\n    Name                    nest\n    Match                   *\n    Operation               lift\n    Nested_under            message\n[FILTER]\n    Name                    modify\n    Match                   *\n    Condition               Key_exists message\n    Rename                  message @m\n    Add                     sourcetype renamelog\n"` |  |
| fluent-bit.config.inputs | string | `"[INPUT]\n    Name               tail\n    Tag                kube.*\n    Path               /var/log/containers/control-plane*.log, /var/log/containers/compute-plane*.log\n    Parser             cri\n    Docker_Mode        On\n    Buffer_Chunk_Size  512KB\n    Buffer_Max_Size    5M\n    Rotate_Wait        30\n    Mem_Buf_Limit      30MB\n    Skip_Long_Lines    Off\n    Refresh_Interval   10\n    READ_FROM_HEAD     On\n[INPUT]\n    Name               tail\n    Tag                application.*\n    Path               /var/log/containers/control-plane*.log, /var/log/containers/compute-plane*.log, /var/log/containers/ingress*.log, /var/log/containers/mongodb*.log, /var/log/containers/keda*.log\n    Parser             cri\n    Docker_Mode        On\n    Buffer_Chunk_Size  512KB\n    Buffer_Max_Size    5M\n    Rotate_Wait        30\n    Mem_Buf_Limit      30MB\n    Skip_Long_Lines    Off\n    Refresh_Interval   10\n    READ_FROM_HEAD     On\n[INPUT]\n    Name               tail\n    Tag                s3-application.*\n    Path               /var/log/containers/control-plane*.log, /var/log/containers/compute-plane*.log, /var/log/containers/ingress*.log, /var/log/containers/mongodb*.log, /var/log/containers/keda*.log\n    Parser             cri\n    Docker_Mode        On\n    Buffer_Chunk_Size  512KB\n    Buffer_Max_Size    5M\n    Rotate_Wait        30\n    Mem_Buf_Limit      30MB\n    Skip_Long_Lines    Off\n    Refresh_Interval   10\n    READ_FROM_HEAD     On\n"` |  |
| fluent-bit.config.outputs | string | `"[OUTPUT]\n    Name                    http\n    Match                   kube.*\n    Host                    seq.armonik.svc.cluster.local\n    Port                    5341\n    URI                     /api/events/raw?clef\n    Header                  ContentType application/vnd.serilog.clef\n    Format                  json_lines\n    json_date_key           @t\n    json_date_format        iso8601\n"` |  |
| fluent-bit.daemonset.enabled | bool | `true` |  |
| fluent-bit.enabled | bool | `true` |  |
| fluent-bit.extraVolumeMounts | string | `"- name: runlogjournal\n  readOnly: true\n  mountPath: /run/log/journal\n  mountPropagation: None\n- name: dmesg\n  readOnly: true\n  mountPath: /var/log/dmesg\n  mountPropagation: None\n"` |  |
| fluent-bit.extraVolumes | string | `"- name: runlogjournal\n  hostPath:\n    path: /run/log/journal\n    type: ''\n- name: dmesg\n  hostPath:\n    path: /var/log/dmesg\n    type: ''\n"` |  |
| fluent-bit.fullnameOverride | string | `"fluent-bit"` |  |
| fluent-bit.ingress.enabled | bool | `true` |  |
| fluent-bit.ingress.selfSigned | bool | `true` |  |
| fluent-bit.ingress.tls | bool | `true` |  |
| fluent-bit.metrics.enabled | bool | `true` |  |
| fluent-bit.metrics.serviceMonitor.enabled | bool | `true` |  |
| global.image.pullPolicy | string | `"IfNotPresent"` |  |
| global.image.registry | string | `""` |  |
| global.imageRegistry | string | `""` |  |
| global.security.allowInsecureImages | bool | `true` |  |
| grafana."grafana.ini".anonymous.enabled | bool | `true` |  |
| grafana."grafana.ini".server.domain | string | `"grafana.local"` |  |
| grafana."grafana.ini".server.root_url | string | `"http://grafana.{{ .Release.Namespace }}.svc.cluster.local"` |  |
| grafana."grafana.ini".server.serve_from_sub_path | bool | `true` |  |
| grafana.dashboardProviders."dashboardproviders.yaml".apiVersion | int | `1` |  |
| grafana.dashboardProviders."dashboardproviders.yaml".providers[0].disableDeletion | bool | `false` |  |
| grafana.dashboardProviders."dashboardproviders.yaml".providers[0].editable | bool | `true` |  |
| grafana.dashboardProviders."dashboardproviders.yaml".providers[0].folder | string | `""` |  |
| grafana.dashboardProviders."dashboardproviders.yaml".providers[0].name | string | `"default"` |  |
| grafana.dashboardProviders."dashboardproviders.yaml".providers[0].options.path | string | `"/var/lib/grafana/dashboards/default"` |  |
| grafana.dashboardProviders."dashboardproviders.yaml".providers[0].orgId | int | `1` |  |
| grafana.dashboardProviders."dashboardproviders.yaml".providers[0].type | string | `"file"` |  |
| grafana.datasources."datasources.yaml".apiVersion | int | `1` |  |
| grafana.datasources."datasources.yaml".datasources[0].access | string | `"proxy"` |  |
| grafana.datasources."datasources.yaml".datasources[0].isDefault | bool | `true` |  |
| grafana.datasources."datasources.yaml".datasources[0].jsonData.tlsSkipVerify | bool | `true` |  |
| grafana.datasources."datasources.yaml".datasources[0].name | string | `"Prometheus"` |  |
| grafana.datasources."datasources.yaml".datasources[0].orgId | int | `1` |  |
| grafana.datasources."datasources.yaml".datasources[0].type | string | `"prometheus"` |  |
| grafana.datasources."datasources.yaml".datasources[0].url | string | `"http://prometheus-prometheus.{{ .Release.Namespace }}.svc.cluster.local:9090"` |  |
| grafana.datasources."datasources.yaml".datasources[0].version | int | `1` |  |
| grafana.enabled | bool | `true` |  |
| grafana.fullnameOverride | string | `"grafana"` |  |
| grafana.ingress.enabled | bool | `true` |  |
| grafana.ingress.hosts[0] | string | `"grafana.local"` |  |
| grafana.serviceMonitor.enabled | bool | `true` |  |
| grafana.sidecar.dashboards.enabled | bool | `true` |  |
| grafana.sidecar.dashboards.label | string | `"grafana_dashboard"` |  |
| grafana.sidecar.dashboards.searchNamespace | string | `"{{ .Release.Namespace }}"` |  |
| grafana.sidecar.datasources.enabled | bool | `true` |  |
| grafana.sidecar.datasources.searchNamespace | string | `"{{ .Release.Namespace }}"` |  |
| ingress.enabled | bool | `true` |  |
| ingress.ingress.type | string | `"LoadBalancer"` |  |
| keda.certificates.certManager.enabled | bool | `false` |  |
| keda.certificates.certManager.issuer.generate | bool | `false` |  |
| keda.certificates.certManager.issuer.group | string | `"cert-manager.io"` |  |
| keda.certificates.certManager.issuer.kind | string | `"ClusterIssuer"` |  |
| keda.certificates.certManager.issuer.name | string | `"armonik-selfsigned-issuer"` |  |
| keda.crds.install | bool | `true` |  |
| keda.enabled | bool | `true` |  |
| keda.image.pullPolicy | string | `"IfNotPresent"` |  |
| kube-prometheus."operator.image.registry" | string | `""` |  |
| kube-prometheus.alertmanager.enabled | bool | `false` |  |
| kube-prometheus.blackboxExporter.enabled | bool | `false` |  |
| kube-prometheus.enabled | bool | `true` |  |
| kube-prometheus.fullnameOverride | string | `"prometheus"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.enabled | bool | `true` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[0].job_name | string | `"metrics-exporter"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[0].static_configs[0].labels.namespace | string | `"armonik"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[0].static_configs[0].targets[0] | string | `"metrics-exporter.{{ .Release.Namespace }}.svc.cluster.local:9419"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[1].job_name | string | `"kube-state-metrics"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[1].static_configs[0].targets[0] | string | `"kube-state-metrics.{{ .Release.Namespace }}.svc.cluster.local:8080"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[2].job_name | string | `"mongodb-metrics-exporter"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[2].metrics_path | string | `"/metrics"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[2].scheme | string | `"http"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[2].static_configs[0].labels.namespace | string | `"armonik"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[2].static_configs[0].targets[0] | string | `"mongodb.{{ .Release.Namespace }}.svc.cluster.local:27017"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].bearer_token_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].job_name | string | `"kubernetes-apiservers"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].kubernetes_sd_configs[0].role | string | `"endpoints"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[0].action | string | `"keep"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[0].regex | string | `"default;kubernetes;https"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_namespace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[0].source_labels[1] | string | `"__meta_kubernetes_service_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[0].source_labels[2] | string | `"__meta_kubernetes_endpoint_port_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[1].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[1].source_labels[0] | string | `"__meta_kubernetes_pod_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[1].target_label | string | `"kubernetes_pod_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[2].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[2].source_labels[0] | string | `"__meta_kubernetes_pod_node_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].relabel_configs[2].target_label | string | `"kubernetes_pod_node_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].scheme | string | `"https"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[3].tls_config.ca_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].job_name | string | `"kubernetes-pods"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].kubernetes_sd_configs[0].role | string | `"pod"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[0].action | string | `"keep"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[0].regex | bool | `true` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_pod_annotation_prometheus_io_scrape"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[1].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[1].regex | string | `"(.+)"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[1].source_labels[0] | string | `"__meta_kubernetes_pod_annotation_prometheus_io_path"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[1].target_label | string | `"__metrics_path__"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[2].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[2].regex | string | `"([^:]+)(?::\\d+)?;(\\d+)"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[2].replacement | string | `"$1:$2"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[2].source_labels[0] | string | `"__address__"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[2].source_labels[1] | string | `"__meta_kubernetes_pod_annotation_prometheus_io_port"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[2].target_label | string | `"__address__"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[3].action | string | `"labelmap"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[3].regex | string | `"__meta_kubernetes_pod_label_(.+)"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[4].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[4].source_labels[0] | string | `"__meta_kubernetes_namespace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[4].target_label | string | `"kubernetes_namespace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[5].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[5].source_labels[0] | string | `"__meta_kubernetes_pod_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[5].target_label | string | `"kubernetes_pod_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[6].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[6].source_labels[0] | string | `"__meta_kubernetes_pod_node_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[4].relabel_configs[6].target_label | string | `"kubernetes_pod_node_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[5].bearer_token_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[5].job_name | string | `"kubernetes-cadvisor"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[5].kubernetes_sd_configs[0].role | string | `"node"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[5].metrics_path | string | `"/metrics/cadvisor"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[5].relabel_configs[0].action | string | `"labelmap"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[5].relabel_configs[0].regex | string | `"__meta_kubernetes_node_label_(.+)"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[5].scheme | string | `"https"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[5].tls_config.ca_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[6].bearer_token_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[6].job_name | string | `"kubernetes-resource"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[6].kubernetes_sd_configs[0].role | string | `"node"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[6].metrics_path | string | `"/metrics/resource"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[6].relabel_configs[0].action | string | `"labelmap"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[6].relabel_configs[0].regex | string | `"__meta_kubernetes_node_label_(.+)"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[6].scheme | string | `"https"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[6].tls_config.ca_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[7].bearer_token_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[7].job_name | string | `"kubernetes-probes"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[7].kubernetes_sd_configs[0].role | string | `"node"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[7].metrics_path | string | `"/metrics/probes"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[7].relabel_configs[0].action | string | `"labelmap"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[7].relabel_configs[0].regex | string | `"__meta_kubernetes_node_label_(.+)"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[7].scheme | string | `"https"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[7].tls_config.ca_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].job_name | string | `"metrics-control-plane"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].kubernetes_sd_configs[0].role | string | `"pod"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[0].action | string | `"keep"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[0].regex | string | `"1081"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_pod_container_port_number"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[1].action | string | `"keep"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[1].regex | string | `"armonik"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[1].source_labels[0] | string | `"__meta_kubernetes_pod_label_app"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[2].action | string | `"keep"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[2].regex | string | `"control-plane"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[2].source_labels[0] | string | `"__meta_kubernetes_pod_label_service"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[3].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[3].source_labels[0] | string | `"__meta_kubernetes_namespace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[3].target_label | string | `"kubernetes_namespace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[4].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[4].source_labels[0] | string | `"__meta_kubernetes_pod_node_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[4].target_label | string | `"kubernetes_pod_node_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[5].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[5].source_labels[0] | string | `"__meta_kubernetes_pod_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[8].relabel_configs[5].target_label | string | `"kubernetes_pod_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].job_name | string | `"metrics-polling-agent"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].kubernetes_sd_configs[0].role | string | `"pod"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[0].action | string | `"keep"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[0].regex | string | `"1080"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_pod_container_port_number"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[1].action | string | `"keep"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[1].regex | string | `"armonik"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[1].source_labels[0] | string | `"__meta_kubernetes_pod_label_app"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[2].action | string | `"keep"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[2].regex | string | `"compute-plane"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[2].source_labels[0] | string | `"__meta_kubernetes_pod_label_service"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[3].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[3].source_labels[0] | string | `"__meta_kubernetes_namespace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[3].target_label | string | `"kubernetes_namespace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[4].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[4].source_labels[0] | string | `"__meta_kubernetes_pod_node_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[4].target_label | string | `"kubernetes_pod_node_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[5].action | string | `"replace"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[5].source_labels[0] | string | `"__meta_kubernetes_pod_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.internal.jobList[9].relabel_configs[5].target_label | string | `"kubernetes_pod_name"` |  |
| kube-prometheus.prometheus.additionalScrapeConfigs.type | string | `"internal"` |  |
| kube-prometheus.prometheus.evaluationInterval | string | `"30s"` |  |
| kube-prometheus.prometheus.scrapeInterval | string | `"10s"` |  |
| mongodb.architecture | string | `"replicaset"` |  |
| mongodb.enabled | bool | `true` |  |
| mongodb.fullnameOverride | string | `"mongodb"` |  |
| mongodb.metrics.enabled | bool | `true` |  |
| mongodb.metrics.serviceMonitor.enabled | bool | `true` |  |
| mongodb.persistence.enabled | bool | `false` |  |
| mongodb.replicaCount | int | `1` |  |
| mongodb.tls.autoGenerated | bool | `true` |  |
| mongodb.tls.enabled | bool | `false` |  |
| mongodb.tls.mode | string | `"allowTLS"` |  |
| mongodb.tls.replicaset.existingSecret | string | `"mongodb-crt"` |  |
| mongodb.useStatefulSet | bool | `true` |  |
| rabbitmq.auth.password | string | `"admin"` |  |
| rabbitmq.auth.tls.autoGenerated | bool | `false` |  |
| rabbitmq.auth.tls.enabled | bool | `false` |  |
| rabbitmq.auth.username | string | `"admin"` |  |
| rabbitmq.enabled | bool | `false` |  |
| rabbitmq.fullnameOverride | string | `"rabbitmq"` |  |
| rabbitmq.metrics.enabled | bool | `true` |  |
| rabbitmq.metrics.serviceMonitor.enabled | bool | `true` |  |
| rabbitmq.metrics.serviceMonitor.namespace | string | `"armonik"` |  |
| rabbitmq.persistence.enabled | bool | `false` |  |
| redis.enabled | bool | `true` |  |
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
| seq.enabled | bool | `true` |  |
| seq.fullnameOverride | string | `"seq"` |  |
| seq.image.pullPolicy | string | `"IfNotPresent"` |  |
| seq.persistence.enabled | bool | `false` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
