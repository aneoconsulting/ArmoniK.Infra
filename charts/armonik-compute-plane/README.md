# armonik-compute-plane

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.35.0](https://img.shields.io/badge/AppVersion-0.35.0-informational?style=flat-square)

A Helm chart for Armonik

**Homepage:** <https://github.com/aneoconsulting/ArmoniK>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Aneo | <armonik@aneo.fr> | <armonik.fr> |

## Source Code

* <https://aneoconsulting.github.io/>

## Requirements

Kubernetes: `>=v1.23.0-0`

| Repository | Name | Version |
|------------|------|---------|
| file://../armonik-common | armonik-common | 0.1.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fluentBit.configMapRef | string | `"fluent-bit-config"` |  |
| fluentBit.image | string | `"fluent-bit"` |  |
| fluentBit.imagePullPolicy | string | `"IfNotPresent"` |  |
| fluentBit.isDaemonSet | bool | `true` |  |
| fluentBit.name | string | `"fluent-bit"` |  |
| fluentBit.repository | string | `"fluent"` |  |
| fluentBit.tag | string | `"2.0.9"` |  |
| global."dependencies.keda" | bool | `false` |  |
| global.imageRegistry | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| nameOverride | string | `""` |  |
| partitionCommon.annotations | object | `{}` |  |
| partitionCommon.conf | string | `nil` |  |
| partitionCommon.hpa.behavior | object | `{"periodSeconds":15,"restoreToOriginalReplicaCount":false,"stabilizationWindowSeconds":300,"type":"Percent","value":100}` | Advanced options to manage the behavior of the HPA |
| partitionCommon.hpa.behavior.periodSeconds | int | `15` | Period in seconds |
| partitionCommon.hpa.behavior.restoreToOriginalReplicaCount | bool | `false` | Restore to the original replicas count |
| partitionCommon.hpa.behavior.stabilizationWindowSeconds | int | `300` | Stabilization window in seconds |
| partitionCommon.hpa.behavior.type | string | `"Percent"` | Type of the target |
| partitionCommon.hpa.behavior.value | int | `100` | Value of the target |
| partitionCommon.hpa.cooldownPeriod | int | `300` | Cooldown period in seconds |
| partitionCommon.hpa.idleReplicaCount | int | `0` | Count of idle replicas |
| partitionCommon.hpa.maxReplicaCount | int | `5` | Maximum count of replicas |
| partitionCommon.hpa.minReplicaCount | int | `0` | Minimum count of replicas |
| partitionCommon.hpa.pollingInterval | int | `15` | Polling interval in seconds |
| partitionCommon.hpa.triggers | list | `[]` |  |
| partitionCommon.hpa.type | string | `"prometheus"` |  |
| partitionCommon.labels.app | string | `"armonik"` |  |
| partitionCommon.labels.service | string | `"compute-plane"` |  |
| partitionCommon.nodeSelector | object | `{}` |  |
| partitionCommon.pollingAgent.conf | string | `nil` |  |
| partitionCommon.pollingAgent.enableServiceLinks | bool | `true` |  |
| partitionCommon.pollingAgent.graceDelay | string | `"00:00:15"` |  |
| partitionCommon.pollingAgent.image | string | `"armonik_pollingagent"` |  |
| partitionCommon.pollingAgent.imagePullPolicy | string | `"IfNotPresent"` |  |
| partitionCommon.pollingAgent.limits.cpu | string | `"1000m"` |  |
| partitionCommon.pollingAgent.limits.memory | string | `"1024Mi"` |  |
| partitionCommon.pollingAgent.livenessProbe.failureThreshold | int | `3` |  |
| partitionCommon.pollingAgent.livenessProbe.httpGet.path | string | `"/liveness"` |  |
| partitionCommon.pollingAgent.livenessProbe.httpGet.port | int | `1080` |  |
| partitionCommon.pollingAgent.livenessProbe.httpGet.scheme | string | `"HTTP"` |  |
| partitionCommon.pollingAgent.livenessProbe.initialDelaySeconds | int | `15` |  |
| partitionCommon.pollingAgent.livenessProbe.periodSeconds | int | `10` |  |
| partitionCommon.pollingAgent.livenessProbe.successThreshold | int | `1` |  |
| partitionCommon.pollingAgent.livenessProbe.timeoutSeconds | int | `10` |  |
| partitionCommon.pollingAgent.messageBatchSize | int | `1` |  |
| partitionCommon.pollingAgent.name | string | `"polling-agent"` |  |
| partitionCommon.pollingAgent.ports.containerPort | int | `1080` |  |
| partitionCommon.pollingAgent.ports.name | string | `"poll-agent-port"` |  |
| partitionCommon.pollingAgent.readinessProbe | object | `{}` |  |
| partitionCommon.pollingAgent.requests.cpu | string | `"500m"` |  |
| partitionCommon.pollingAgent.requests.memory | string | `"256Mi"` |  |
| partitionCommon.pollingAgent.securityContext.allowPrivilegeEscalation | bool | `true` |  |
| partitionCommon.pollingAgent.securityContext.capabilities.drop[0] | string | `"SYS_PTRACE"` |  |
| partitionCommon.pollingAgent.securityContext.privileged | bool | `false` |  |
| partitionCommon.pollingAgent.securityContext.readOnlyRootFilesystem | bool | `false` |  |
| partitionCommon.pollingAgent.securityContext.runAsNonRoot | bool | `false` |  |
| partitionCommon.pollingAgent.startupProbe.failureThreshold | int | `20` |  |
| partitionCommon.pollingAgent.startupProbe.httpGet.path | string | `"/startup"` |  |
| partitionCommon.pollingAgent.startupProbe.httpGet.port | int | `1080` |  |
| partitionCommon.pollingAgent.startupProbe.httpGet.scheme | string | `"HTTP"` |  |
| partitionCommon.pollingAgent.startupProbe.initialDelaySeconds | int | `1` |  |
| partitionCommon.pollingAgent.startupProbe.periodSeconds | int | `3` |  |
| partitionCommon.pollingAgent.startupProbe.successThreshold | int | `1` |  |
| partitionCommon.pollingAgent.startupProbe.timeoutSeconds | int | `1` |  |
| partitionCommon.replicas | int | `1` |  |
| partitionCommon.socketType | string | `"unixdomainsocket"` |  |
| partitionCommon.terminationGracePeriodSeconds | int | `30` |  |
| partitionCommon.tolerations | list | `[]` |  |
| partitionCommon.worker.checkDelay | string | `"00:00:10"` |  |
| partitionCommon.worker.checkRetries | int | `10` |  |
| partitionCommon.worker.conf | string | `nil` |  |
| partitionCommon.worker.imagePullPolicy | string | `"IfNotPresent"` |  |
| partitionCommon.worker.limits.cpu | string | `"1000m"` |  |
| partitionCommon.worker.limits.memory | string | `"1024Mi"` |  |
| partitionCommon.worker.livenessProbe.failureThreshold | int | `3` |  |
| partitionCommon.worker.livenessProbe.httpGet.path | string | `"/liveness"` |  |
| partitionCommon.worker.livenessProbe.httpGet.port | int | `1080` |  |
| partitionCommon.worker.livenessProbe.httpGet.scheme | string | `"HTTP"` |  |
| partitionCommon.worker.livenessProbe.initialDelaySeconds | int | `15` |  |
| partitionCommon.worker.livenessProbe.periodSeconds | int | `10` |  |
| partitionCommon.worker.livenessProbe.successThreshold | int | `1` |  |
| partitionCommon.worker.livenessProbe.timeoutSeconds | int | `10` |  |
| partitionCommon.worker.name | string | `"worker"` |  |
| partitionCommon.worker.ports.containerPort | int | `1081` |  |
| partitionCommon.worker.ports.name | string | `"worker-port"` |  |
| partitionCommon.worker.requests.cpu | string | `"500m"` |  |
| partitionCommon.worker.requests.memory | string | `"512Mi"` |  |
| partitionCommon.worker.startupProbe.failureThreshold | int | `20` |  |
| partitionCommon.worker.startupProbe.httpGet.path | string | `"/startup"` |  |
| partitionCommon.worker.startupProbe.httpGet.port | int | `1080` |  |
| partitionCommon.worker.startupProbe.httpGet.scheme | string | `"HTTP"` |  |
| partitionCommon.worker.startupProbe.initialDelaySeconds | int | `1` |  |
| partitionCommon.worker.startupProbe.periodSeconds | int | `3` |  |
| partitionCommon.worker.startupProbe.successThreshold | int | `1` |  |
| partitionCommon.worker.startupProbe.timeoutSeconds | int | `1` |  |
| partitionCommon.worker.terminationMessagePath | string | `"/dev/termination-log"` |  |
| partitionCommon.worker.terminationMessagePolicy | string | `"File"` |  |
| partitions.bench.hpa.triggers[0].metadata.metricName | string | `"armonik_bench_tasks_queued"` |  |
| partitions.bench.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| partitions.bench.hpa.triggers[0].metadata.query | string | `"armonik_bench_tasks_queued{job=\"metrics-exporter\"}"` |  |
| partitions.bench.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| partitions.bench.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| partitions.bench.hpa.triggers[0].type | string | `"prometheus"` |  |
| partitions.bench.worker.image | string | `"armonik_core_bench_test_worker"` |  |
| partitions.default.hpa.triggers[0].metadata.metricName | string | `"armonik_default_tasks_queued"` |  |
| partitions.default.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| partitions.default.hpa.triggers[0].metadata.query | string | `"armonik_default_tasks_queued{job=\"metrics-exporter\"}"` |  |
| partitions.default.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| partitions.default.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| partitions.default.hpa.triggers[0].type | string | `"prometheus"` |  |
| partitions.default.worker.image | string | `"armonik_worker_dll"` |  |
| partitions.default.worker.tag | string | `"0.19.1"` |  |
| partitions.htcmock.hpa.triggers[0].metadata.metricName | string | `"armonik_htcmock_tasks_queued"` |  |
| partitions.htcmock.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| partitions.htcmock.hpa.triggers[0].metadata.query | string | `"armonik_htcmock_tasks_queued{job=\"metrics-exporter\"}"` |  |
| partitions.htcmock.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| partitions.htcmock.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| partitions.htcmock.hpa.triggers[0].type | string | `"prometheus"` |  |
| partitions.htcmock.socketType | string | `"tcp"` |  |
| partitions.htcmock.worker.image | string | `"armonik_core_htcmock_test_worker"` |  |
| partitions.stream.hpa.triggers[0].metadata.metricName | string | `"armonik_stream_tasks_queued"` |  |
| partitions.stream.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| partitions.stream.hpa.triggers[0].metadata.query | string | `"armonik_stream_tasks_queued{job=\"metrics-exporter\"}"` |  |
| partitions.stream.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| partitions.stream.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| partitions.stream.hpa.triggers[0].type | string | `"prometheus"` |  |
| partitions.stream.worker.image | string | `"armonik_core_stream_test_worker"` |  |
| podDisruptionBudget.enabled | bool | `false` |  |
| podDisruptionBudget.maxUnavailable | string | `nil` |  |
| podDisruptionBudget.minAvailable | string | `nil` |  |
| preStopWaitScript | string | `"<<EOF while test -e /cache/armonik_agent.sock ; do   sleep 1 done EOF"` |  |
| rbac.create | bool | `true` |  |
| rbac.pspEnabled | bool | `false` |  |
| registry | string | `""` |  |
| replicaCount | int | `1` |  |
| repository | string | `"dockerhubaneo"` |  |
| restartPolicy | string | `"Always"` |  |
| service | object | `{}` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `"compute-plane"` |  |
| serviceAccount.secrets | list | `[]` |  |
| shareProcessNamespace | bool | `false` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
