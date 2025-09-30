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
| fluentBit.image.name | string | `"fluent-bit"` |  |
| fluentBit.image.pullPolicy | string | `"IfNotPresent"` |  |
| fluentBit.image.registry | string | `nil` |  |
| fluentBit.image.repository | string | `"fluent"` |  |
| fluentBit.image.tag | string | `"2.0.9"` |  |
| fluentBit.isDaemonSet | bool | `true` |  |
| fullnameOverride | string | `""` |  |
| global."dependencies.keda" | bool | `false` |  |
| global.imageRegistry | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| nameOverride | string | `""` |  |
| partitionCommon.agent.conf | string | `nil` |  |
| partitionCommon.agent.enableServiceLinks | bool | `true` |  |
| partitionCommon.agent.graceDelay | string | `"00:00:15"` |  |
| partitionCommon.agent.image.name | string | `"armonik_pollingagent"` |  |
| partitionCommon.agent.image.pullPolicy | string | `"IfNotPresent"` |  |
| partitionCommon.agent.image.registry | string | `nil` |  |
| partitionCommon.agent.image.repository | string | `"dockerhubaneo"` |  |
| partitionCommon.agent.image.tag | string | `nil` |  |
| partitionCommon.agent.limits.cpu | string | `"1000m"` |  |
| partitionCommon.agent.limits.memory | string | `"1024Mi"` |  |
| partitionCommon.agent.livenessProbe.failureThreshold | int | `3` |  |
| partitionCommon.agent.livenessProbe.httpGet.path | string | `"/liveness"` |  |
| partitionCommon.agent.livenessProbe.httpGet.port | int | `1080` |  |
| partitionCommon.agent.livenessProbe.httpGet.scheme | string | `"HTTP"` |  |
| partitionCommon.agent.livenessProbe.initialDelaySeconds | int | `15` |  |
| partitionCommon.agent.livenessProbe.periodSeconds | int | `10` |  |
| partitionCommon.agent.livenessProbe.successThreshold | int | `1` |  |
| partitionCommon.agent.livenessProbe.timeoutSeconds | int | `10` |  |
| partitionCommon.agent.messageBatchSize | int | `1` |  |
| partitionCommon.agent.name | string | `"polling-agent"` |  |
| partitionCommon.agent.ports.containerPort | int | `1080` |  |
| partitionCommon.agent.ports.name | string | `"poll-agent-port"` |  |
| partitionCommon.agent.readinessProbe | object | `{}` |  |
| partitionCommon.agent.requests.cpu | string | `"500m"` |  |
| partitionCommon.agent.requests.memory | string | `"256Mi"` |  |
| partitionCommon.agent.securityContext.allowPrivilegeEscalation | bool | `true` |  |
| partitionCommon.agent.securityContext.capabilities.drop[0] | string | `"SYS_PTRACE"` |  |
| partitionCommon.agent.securityContext.privileged | bool | `false` |  |
| partitionCommon.agent.securityContext.readOnlyRootFilesystem | bool | `false` |  |
| partitionCommon.agent.securityContext.runAsNonRoot | bool | `false` |  |
| partitionCommon.agent.startupProbe.failureThreshold | int | `20` |  |
| partitionCommon.agent.startupProbe.httpGet.path | string | `"/startup"` |  |
| partitionCommon.agent.startupProbe.httpGet.port | int | `1080` |  |
| partitionCommon.agent.startupProbe.httpGet.scheme | string | `"HTTP"` |  |
| partitionCommon.agent.startupProbe.initialDelaySeconds | int | `1` |  |
| partitionCommon.agent.startupProbe.periodSeconds | int | `3` |  |
| partitionCommon.agent.startupProbe.successThreshold | int | `1` |  |
| partitionCommon.agent.startupProbe.timeoutSeconds | int | `1` |  |
| partitionCommon.annotations | object | `{}` |  |
| partitionCommon.conf | string | `nil` |  |
| partitionCommon.hpa.behavior | object | `{"periodSeconds":15,"restoreToOriginalReplicaCount":false,"stabilizationWindowSeconds":300,"type":"Percent","value":100}` | Advanced options to manage the behavior of the HPA |
| partitionCommon.hpa.behavior.periodSeconds | int | `15` | Period in seconds |
| partitionCommon.hpa.behavior.restoreToOriginalReplicaCount | bool | `false` | Restore to the original replicas count |
| partitionCommon.hpa.behavior.stabilizationWindowSeconds | int | `300` | Stabilization window in seconds |
| partitionCommon.hpa.behavior.type | string | `"Percent"` | Type of the target |
| partitionCommon.hpa.behavior.value | int | `100` | Value of the target |
| partitionCommon.hpa.cooldownPeriod | int | `300` | Cooldown period in seconds |
| partitionCommon.hpa.idleReplicaCount | int | `1` | Count of idle replicas |
| partitionCommon.hpa.maxReplicaCount | int | `5` | Maximum count of replicas |
| partitionCommon.hpa.minReplicaCount | int | `1` | Minimum count of replicas |
| partitionCommon.hpa.pollingInterval | int | `15` | Polling interval in seconds |
| partitionCommon.hpa.triggers[0].metadata.metricName | string | `"armonik_{{ .Values.partitionName }}_tasks_queued"` |  |
| partitionCommon.hpa.triggers[0].metadata.namespace | string | `"{{ .Release.Namespace }}"` |  |
| partitionCommon.hpa.triggers[0].metadata.query | string | `"armonik_{{ .Values.partitionName }}_tasks_queued{job=\"metrics-exporter\"}"` |  |
| partitionCommon.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| partitionCommon.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| partitionCommon.hpa.triggers[0].type | string | `"prometheus"` |  |
| partitionCommon.hpa.type | string | `"prometheus"` |  |
| partitionCommon.labels.app | string | `"armonik"` |  |
| partitionCommon.labels.service | string | `"compute-plane"` |  |
| partitionCommon.nodeSelector | object | `{}` |  |
| partitionCommon.replicas | int | `1` |  |
| partitionCommon.socketType | string | `"unixdomainsocket"` |  |
| partitionCommon.terminationGracePeriodSeconds | int | `30` |  |
| partitionCommon.tolerations | list | `[]` |  |
| partitionCommon.worker.checkDelay | string | `"00:00:10"` |  |
| partitionCommon.worker.checkRetries | int | `10` |  |
| partitionCommon.worker.conf | string | `nil` |  |
| partitionCommon.worker.image.name | string | `nil` |  |
| partitionCommon.worker.image.pullPolicy | string | `"IfNotPresent"` |  |
| partitionCommon.worker.image.registry | string | `nil` |  |
| partitionCommon.worker.image.repository | string | `"dockerhubaneo"` |  |
| partitionCommon.worker.image.tag | string | `nil` |  |
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
| partitions.bench.worker.image.name | string | `"armonik_core_bench_test_worker"` |  |
| partitions.default.worker.image.name | string | `"armonik_worker_dll"` |  |
| partitions.default.worker.image.tag | string | `"0.19.1"` |  |
| partitions.htcmock.socketType | string | `"tcp"` |  |
| partitions.htcmock.worker.image.name | string | `"armonik_core_htcmock_test_worker"` |  |
| partitions.stream.worker.image.name | string | `"armonik_core_stream_test_worker"` |  |
| podDisruptionBudget.enabled | bool | `false` |  |
| podDisruptionBudget.maxUnavailable | string | `nil` |  |
| podDisruptionBudget.minAvailable | string | `nil` |  |
| preStopWaitScript | string | `"<<EOF while test -e /cache/armonik_agent.sock ; do   sleep 1 done EOF"` |  |
| rbac.create | bool | `true` |  |
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
