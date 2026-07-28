# armonik

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.37.1](https://img.shields.io/badge/AppVersion-0.37.1-informational?style=flat-square)

A Helm chart for Armonik

**Homepage:** <https://github.com/aneoconsulting/ArmoniK>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Aneo | <armonik@aneo.fr> | <armonik.fr> |

## Source Code

* <https://aneoconsulting.github.io/>

## Requirements

Kubernetes: `>=v1.25.0-0`

| Repository | Name | Version |
|------------|------|---------|
| file://../armonik-common | armonik-common | 0.1.x |
| file://../armonik-compute-plane | compute-plane(armonik-compute-plane) | 0.1.x |
| file://../armonik-control-plane | control-plane(armonik-control-plane) | 0.1.x |
| file://../armonik-dependencies | dependencies(armonik-dependencies) | 0.1.x |
| file://../armonik-ingress | ingress(armonik-ingress) | 0.1.x |
| file://../armonik-operators | operators(armonik-operators) | 0.1.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| certManagerWait.image.pullPolicy | string | `"IfNotPresent"` |  |
| certManagerWait.image.repository | string | `"alpine/k8s"` |  |
| certManagerWait.image.tag | string | `"1.31.0"` |  |
| certManagerWait.timeout | string | `"300s"` |  |
| compute-plane.conf.source | string | `"{{ .Release.Name }}"` |  |
| compute-plane.enabled | bool | `true` |  |
| compute-plane.partitions.default.worker.image.name | string | `"armonik-dynamic-dotnet-worker"` |  |
| compute-plane.partitions.default.worker.image.tag | string | `"0.21.2"` |  |
| compute-plane.partitions.htcmock.socketType | string | `"tcp"` |  |
| compute-plane.partitions.htcmock.worker.image.name | string | `"armonik_core_htcmock_test_worker"` |  |
| compute-plane.partitions.stream.worker.image.name | string | `"armonik_core_stream_test_worker"` |  |
| compute-plane.serviceAccount.create | bool | `true` |  |
| conf.log.minimumLevel | string | `"Information"` |  |
| conf.source | string | `"{{ .Release.Name }}"` |  |
| control-plane.conf.source | string | `"{{ .Release.Name }}"` |  |
| control-plane.defaultPartition | string | `"default"` |  |
| control-plane.enabled | bool | `true` |  |
| control-plane.extraPartitions | string | `nil` |  |
| control-plane.init.enabled | bool | `true` |  |
| control-plane.rbac.createBuiltInRoles | bool | `true` |  |
| dependencies.activemq.enabled | bool | `true` |  |
| dependencies.activemq.fullnameOverride | string | `"activemq"` |  |
| dependencies.activemq.image.registry | string | `"docker.io"` |  |
| dependencies.activemq.replicas | int | `1` |  |
| dependencies.fluent-bit.config.customParsers | string | `"[PARSER]\n    Name   json\n    Format json\n    Time_Key time\n    Time_Format %Y-%m-%dT%H:%M:%S.%L%z\n[PARSER]\n    Name cri\n    Format regex\n    Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<log>.*)$\n    Time_Key time\n    Time_Format %Y-%m-%dT%H:%M:%S.%L%z\n    Time_Keep On\n"` |  |
| dependencies.fluent-bit.config.filters | string | `"[FILTER]\n    Name                kubernetes\n    Match               *\n    Kube_URL            https://kubernetes.default.svc:443\n    Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n    Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token\n    Kube_Tag_Prefix     kube.var.log.containers.\n    Merge_Log           On\n    Merge_Log_Trim      On\n    Merge_Parser        json\n    Keep_Log            Off\n    Annotations         On\n    Labels              On\n    K8S-Logging.Parser  On\n    K8S-Logging.Exclude Off\n    Buffer_Size         0\n[FILTER]\n    Name                    nest\n    Match                   *\n    Operation               lift\n    Nested_under            kubernetes\n    Add_prefix              kubernetes_\n[FILTER]\n    Name                    modify\n    Match                   *\n    Condition               Key_exists log\n    Rename                  log @m\n    Add                     sourcetype renamelog\n"` |  |
| dependencies.fluent-bit.config.inputs | string | `"[INPUT]\n    Name               tail\n    Tag                kube.*\n    Path               /var/log/containers/*control-plane*.log, /var/log/containers/*compute-plane*.log\n    Parser             cri\n    Docker_Mode        On\n    Buffer_Chunk_Size  512KB\n    Buffer_Max_Size    5M\n    Rotate_Wait        30\n    Mem_Buf_Limit      30MB\n    Skip_Long_Lines    Off\n    Refresh_Interval   10\n    Read_from_Head     On\n[INPUT]\n    Name               tail\n    Tag                application.*\n    Path               /var/log/containers/*control-plane*.log, /var/log/containers/*compute-plane*.log, /var/log/containers/*ingress*.log, /var/log/containers/mongodb*.log, /var/log/containers/keda*.log\n    Parser             cri\n    Buffer_Chunk_Size  512KB\n    Buffer_Max_Size    5M\n    Rotate_Wait        30\n    Mem_Buf_Limit      30MB\n    Skip_Long_Lines    Off\n    Refresh_Interval   10\n    Read_from_Head     On\n"` |  |
| dependencies.fluent-bit.config.outputs | string | `"[OUTPUT]\n    Name                    http\n    Match                   kube.*\n    Host                    seq\n    Port                    5341\n    URI                     /api/events/raw?clef\n    Header                  Content-Type application/vnd.serilog.clef\n    Format                  json_lines\n    json_date_key           @t\n    json_date_format        iso8601\n[OUTPUT]\n    Name                    stdout\n    Match                   kube.*\n"` |  |
| dependencies.fluent-bit.config.service | string | `"[SERVICE]\n    Daemon        Off\n    Flush         1\n    Log_Level     info\n    Parsers_File  /fluent-bit/etc/conf/custom_parsers.conf\n    HTTP_Server   On\n    HTTP_Listen   0.0.0.0\n    HTTP_Port     2020\n    Health_Check  On\n"` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[0].mountPath | string | `"/run/log/journal"` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[0].name | string | `"runlogjournal"` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[0].readOnly | bool | `true` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[1].mountPath | string | `"/var/log/dmesg"` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[1].name | string | `"dmesg"` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[1].readOnly | bool | `true` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[2].mountPath | string | `"/var/log"` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[2].name | string | `"varlog"` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[2].readOnly | bool | `true` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[3].mountPath | string | `"/var/lib/docker/containers"` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[3].name | string | `"varlibdockercontainers"` |  |
| dependencies.fluent-bit.daemonSetVolumeMounts[3].readOnly | bool | `true` |  |
| dependencies.fluent-bit.daemonSetVolumes[0].hostPath.path | string | `"/run/log/journal"` |  |
| dependencies.fluent-bit.daemonSetVolumes[0].hostPath.type | string | `""` |  |
| dependencies.fluent-bit.daemonSetVolumes[0].name | string | `"runlogjournal"` |  |
| dependencies.fluent-bit.daemonSetVolumes[1].hostPath.path | string | `"/var/log/dmesg"` |  |
| dependencies.fluent-bit.daemonSetVolumes[1].hostPath.type | string | `""` |  |
| dependencies.fluent-bit.daemonSetVolumes[1].name | string | `"dmesg"` |  |
| dependencies.fluent-bit.daemonSetVolumes[2].hostPath.path | string | `"/var/log"` |  |
| dependencies.fluent-bit.daemonSetVolumes[2].hostPath.type | string | `""` |  |
| dependencies.fluent-bit.daemonSetVolumes[2].name | string | `"varlog"` |  |
| dependencies.fluent-bit.daemonSetVolumes[3].hostPath.path | string | `"/var/lib/docker/containers"` |  |
| dependencies.fluent-bit.daemonSetVolumes[3].hostPath.type | string | `""` |  |
| dependencies.fluent-bit.daemonSetVolumes[3].name | string | `"varlibdockercontainers"` |  |
| dependencies.fluent-bit.enabled | bool | `true` |  |
| dependencies.fluent-bit.fullnameOverride | string | `"fluent-bit"` |  |
| dependencies.grafana."grafana.ini"."auth.anonymous".enabled | bool | `true` |  |
| dependencies.grafana."grafana.ini".server.domain | string | `"grafana.local"` |  |
| dependencies.grafana."grafana.ini".server.root_url | string | `"http://grafana"` |  |
| dependencies.grafana."grafana.ini".server.serve_from_sub_path | bool | `false` |  |
| dependencies.grafana.enabled | bool | `true` |  |
| dependencies.grafana.fullnameOverride | string | `"grafana"` |  |
| dependencies.grafana.image.registry | string | `"docker.io"` |  |
| dependencies.grafana.serviceMonitor.enabled | bool | `true` |  |
| dependencies.grafana.sidecar.dashboards.enabled | bool | `true` |  |
| dependencies.grafana.sidecar.dashboards.folderAnnotation | string | `"grafana_dashboard_folder"` |  |
| dependencies.grafana.sidecar.dashboards.label | string | `"grafana_dashboard"` |  |
| dependencies.grafana.sidecar.datasources.enabled | bool | `true` |  |
| dependencies.mongodb.backup.enabled | bool | `false` |  |
| dependencies.mongodb.enabled | bool | `true` |  |
| dependencies.mongodb.finalizers | list | `[]` |  |
| dependencies.mongodb.replsets.rs0.size | int | `1` |  |
| dependencies.mongodb.sharding.enabled | bool | `false` |  |
| dependencies.mongodb.tls.allowInvalidCertificates | bool | `true` |  |
| dependencies.mongodb.tls.mode | string | `"preferTLS"` |  |
| dependencies.mongodb.unsafeFlags.replsetSize | bool | `true` |  |
| dependencies.mongodb.unsafeFlags.tls | bool | `true` |  |
| dependencies.rabbitmq.auth.password | string | `"admin"` |  |
| dependencies.rabbitmq.auth.username | string | `"admin"` |  |
| dependencies.rabbitmq.enabled | bool | `false` |  |
| dependencies.rabbitmq.fullnameOverride | string | `"rabbitmq"` |  |
| dependencies.rabbitmq.image.registry | string | `"bitnamilegacy"` |  |
| dependencies.rabbitmq.image.repository | string | `"rabbitmq"` |  |
| dependencies.rabbitmq.image.tag | string | `"4.1.3"` |  |
| dependencies.rabbitmq.metrics.enabled | bool | `true` |  |
| dependencies.rabbitmq.metrics.image.registry | string | `"public.ecr.aws"` |  |
| dependencies.rabbitmq.metrics.serviceMonitor.enabled | bool | `true` |  |
| dependencies.rabbitmq.persistence.enabled | bool | `false` |  |
| dependencies.redis.auth.aclUsers.default.permissions | string | `"~* &* +@all"` |  |
| dependencies.redis.auth.enabled | bool | `true` |  |
| dependencies.redis.auth.usersExistingSecret | string | `"redis-users"` |  |
| dependencies.redis.enabled | bool | `true` |  |
| dependencies.redis.image.registry | string | `"public.ecr.aws"` |  |
| dependencies.redis.metrics.enabled | bool | `true` |  |
| dependencies.redis.metrics.image.registry | string | `"public.ecr.aws"` |  |
| dependencies.redis.metrics.serviceMonitor.enabled | bool | `true` |  |
| dependencies.redis.metrics.serviceMonitor.port | string | `"http-metrics"` |  |
| dependencies.redis.replica.enabled | bool | `false` |  |
| dependencies.redis.tls.caPublicKey | string | `""` |  |
| dependencies.redis.tls.enabled | bool | `false` |  |
| dependencies.redis.tls.existingSecret | string | `""` |  |
| dependencies.redis.tls.serverKey | string | `""` |  |
| dependencies.redis.tls.serverPublicKey | string | `""` |  |
| dependencies.seq.enabled | bool | `true` |  |
| dependencies.seq.env.SEQ_API_LISTENURI | string | `"http://+:5341"` |  |
| dependencies.seq.fullnameOverride | string | `"seq"` |  |
| dependencies.seq.image.pullPolicy | string | `"IfNotPresent"` |  |
| dependencies.seq.persistence.enabled | bool | `false` |  |
| global.armonik.clusterDomain | string | `""` |  |
| global.armonik.monitoring.metricsExporterUrl | string | `""` |  |
| global.armonik.monitoring.prometheusUrl | string | `""` |  |
| global.armonik.mountPath | string | `"/mounts"` |  |
| global.armonik.operators.certManager.available | bool | `true` |  |
| global.armonik.operators.certManager.deploy | bool | `true` |  |
| global.armonik.operators.externalSecrets.available | bool | `true` |  |
| global.armonik.operators.externalSecrets.deploy | bool | `true` |  |
| global.armonik.operators.keda.available | bool | `true` |  |
| global.armonik.operators.keda.deploy | bool | `true` |  |
| global.armonik.operators.mongodbOperator.available | bool | `true` |  |
| global.armonik.operators.mongodbOperator.deploy | bool | `true` |  |
| global.armonik.operators.prometheusOperator.available | bool | `true` |  |
| global.armonik.operators.prometheusOperator.deploy | bool | `true` |  |
| global.clusterDomain | string | `""` |  |
| global.environment.description | string | `"Armonik environment"` |  |
| global.environment.name | string | `"local"` |  |
| global.image.pullPolicy | string | `"IfNotPresent"` |  |
| global.image.registry | string | `""` |  |
| global.imageRegistry | string | `""` |  |
| global.security.allowInsecureImages | bool | `true` |  |
| global.version.armonikCore | string | `"0.37.1"` |  |
| ingress.enabled | bool | `true` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
