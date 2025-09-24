# armonik-compute-plane

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.31.2](https://img.shields.io/badge/AppVersion-0.31.2-informational?style=flat-square)

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
| computePlane.metadata.labels.app | string | `"armonik"` |  |
| computePlane.metadata.labels.service | string | `"compute-plane"` |  |
| computePlane.metadata.name | string | `"compute-plane"` |  |
| computePlaneConfigmaps.data.ComputePlane__AgentChannel__Address | string | `"/cache/armonik_agent.sock"` |  |
| computePlaneConfigmaps.data.ComputePlane__AgentChannel__SocketType | string | `"unixdomainsocket"` |  |
| computePlaneConfigmaps.data.ComputePlane__WorkerChannel__Address | string | `"/cache/armonik_worker.sock"` |  |
| computePlaneConfigmaps.data.ComputePlane__WorkerChannel__SocketType | string | `"unixdomainsocket"` |  |
| computePlaneConfigmaps.name | string | `"compute-plane-configmap"` |  |
| fluentBit.configMapRef | string | `"fluent-bit-config"` |  |
| fluentBit.fluentVolumes[0].mountPath | string | `"/var/fluent-bit/state"` |  |
| fluentBit.fluentVolumes[0].name | string | `"fluentbitstate"` |  |
| fluentBit.fluentVolumes[0].readOnly | bool | `false` |  |
| fluentBit.fluentVolumes[0].type | string | `"hostpath"` |  |
| fluentBit.fluentVolumes[1].mountPath | string | `"/var/log"` |  |
| fluentBit.fluentVolumes[1].name | string | `"varlog"` |  |
| fluentBit.fluentVolumes[1].readOnly | bool | `true` |  |
| fluentBit.fluentVolumes[1].type | string | `"hostpath"` |  |
| fluentBit.fluentVolumes[2].mountPath | string | `"/var/lib/docker/containers"` |  |
| fluentBit.fluentVolumes[2].name | string | `"varlibdockercontainers"` |  |
| fluentBit.fluentVolumes[2].readOnly | bool | `true` |  |
| fluentBit.fluentVolumes[2].type | string | `"hostpath"` |  |
| fluentBit.fluentVolumes[3].mountPath | string | `"/run/log/journal"` |  |
| fluentBit.fluentVolumes[3].name | string | `"runlogjournal"` |  |
| fluentBit.fluentVolumes[3].readOnly | bool | `true` |  |
| fluentBit.fluentVolumes[3].type | string | `"hostpath"` |  |
| fluentBit.fluentVolumes[4].mountPath | string | `"/var/log/dmesg"` |  |
| fluentBit.fluentVolumes[4].name | string | `"dmesg"` |  |
| fluentBit.fluentVolumes[4].readOnly | bool | `true` |  |
| fluentBit.fluentVolumes[4].type | string | `"hostpath"` |  |
| fluentBit.fluentVolumes[5].mountPath | string | `"/fluent-bit/etc"` |  |
| fluentBit.fluentVolumes[5].name | string | `"fluentbitconfig"` |  |
| fluentBit.fluentVolumes[5].readOnly | bool | `false` |  |
| fluentBit.fluentVolumes[5].type | string | `"hostpath"` |  |
| fluentBit.fluentVolumes[6].mountPath | string | `"/fluent-bit/etc"` |  |
| fluentBit.fluentVolumes[6].name | string | `"fluentbitconfig"` |  |
| fluentBit.fluentVolumes[6].readOnly | bool | `false` |  |
| fluentBit.fluentVolumes[6].type | string | `"configmap"` |  |
| fluentBit.image | string | `"fluent-bit"` |  |
| fluentBit.imagePullPolicy | string | `"IfNotPresent"` |  |
| fluentBit.isDaemonSet | bool | `true` |  |
| fluentBit.name | string | `"fluent-bit"` |  |
| fluentBit.repository | string | `"fluent"` |  |
| fluentBit.tag | string | `"2.0.9"` |  |
| fluentBit.volumeMounts[0].mountPath | string | `"/cache"` |  |
| fluentBit.volumeMounts[0].name | string | `"cache-volume"` |  |
| fluentBit.volumeMounts[0].readOnly | bool | `true` |  |
| global."dependencies.keda" | bool | `false` |  |
| global.imageRegistry | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| nameOverride | string | `""` |  |
| partitionCommon.annotations | object | `{}` |  |
| partitionCommon.conf | string | `nil` |  |
| partitionCommon.hpa.behavior.period_seconds | int | `15` |  |
| partitionCommon.hpa.behavior.restore_to_original_replica_count | bool | `true` |  |
| partitionCommon.hpa.behavior.stabilization_window_seconds | int | `300` |  |
| partitionCommon.hpa.behavior.type | string | `"Percent"` |  |
| partitionCommon.hpa.behavior.value | int | `100` |  |
| partitionCommon.hpa.cooldown_period | int | `300` |  |
| partitionCommon.hpa.max_replica_count | int | `5` |  |
| partitionCommon.hpa.min_replica_count | int | `0` |  |
| partitionCommon.hpa.polling_interval | int | `15` |  |
| partitionCommon.hpa.triggers | list | `[]` |  |
| partitionCommon.hpa.type | string | `"prometheus"` |  |
| partitionCommon.livenessProbe.failureThreshold | int | `3` |  |
| partitionCommon.livenessProbe.httpGet.path | string | `"/liveness"` |  |
| partitionCommon.livenessProbe.httpGet.port | int | `1080` |  |
| partitionCommon.livenessProbe.httpGet.scheme | string | `"HTTP"` |  |
| partitionCommon.livenessProbe.initialDelaySeconds | int | `15` |  |
| partitionCommon.livenessProbe.periodSeconds | int | `10` |  |
| partitionCommon.livenessProbe.successThreshold | int | `1` |  |
| partitionCommon.livenessProbe.timeoutSeconds | int | `10` |  |
| partitionCommon.nodeSelector | object | `{}` |  |
| partitionCommon.pollingAgent.conf | string | `nil` |  |
| partitionCommon.pollingAgent.enableServiceLinks | bool | `true` |  |
| partitionCommon.pollingAgent.graceDelay | string | `"00:00:15"` |  |
| partitionCommon.pollingAgent.image | string | `"armonik_pollingagent"` |  |
| partitionCommon.pollingAgent.imagePullPolicy | string | `"IfNotPresent"` |  |
| partitionCommon.pollingAgent.limits.cpu | string | `"1000m"` |  |
| partitionCommon.pollingAgent.limits.memory | string | `"1024Mi"` |  |
| partitionCommon.pollingAgent.messageBatchSize | int | `1` |  |
| partitionCommon.pollingAgent.requests.cpu | string | `"500m"` |  |
| partitionCommon.pollingAgent.requests.memory | string | `"256Mi"` |  |
| partitionCommon.pollingAgent.securityContext.allowPrivilegeEscalation | bool | `true` |  |
| partitionCommon.pollingAgent.securityContext.capabilities.drop[0] | string | `"SYS_PTRACE"` |  |
| partitionCommon.pollingAgent.securityContext.privileged | bool | `false` |  |
| partitionCommon.pollingAgent.securityContext.readOnlyRootFilesystem | bool | `false` |  |
| partitionCommon.pollingAgent.securityContext.runAsNonRoot | bool | `false` |  |
| partitionCommon.pollingAgent.tag | string | `"0.31.2"` |  |
| partitionCommon.readinessProbe | object | `{}` |  |
| partitionCommon.replicas | int | `1` |  |
| partitionCommon.socketType | string | `"unixdomainsocket"` |  |
| partitionCommon.startupProbe.failureThreshold | int | `20` |  |
| partitionCommon.startupProbe.httpGet.path | string | `"/startup"` |  |
| partitionCommon.startupProbe.httpGet.port | int | `1080` |  |
| partitionCommon.startupProbe.httpGet.scheme | string | `"HTTP"` |  |
| partitionCommon.startupProbe.initialDelaySeconds | int | `1` |  |
| partitionCommon.startupProbe.periodSeconds | int | `3` |  |
| partitionCommon.startupProbe.successThreshold | int | `1` |  |
| partitionCommon.startupProbe.timeoutSeconds | int | `1` |  |
| partitionCommon.terminationGracePeriodSeconds | int | `30` |  |
| partitionCommon.tolerations | list | `[]` |  |
| partitionCommon.worker.checkDelay | string | `"00:00:10"` |  |
| partitionCommon.worker.checkRetries | int | `10` |  |
| partitionCommon.worker.conf | string | `nil` |  |
| partitionCommon.worker.imagePullPolicy | string | `"IfNotPresent"` |  |
| partitionCommon.worker.limits.cpu | string | `"1000m"` |  |
| partitionCommon.worker.limits.memory | string | `"1024Mi"` |  |
| partitionCommon.worker.name | string | `"worker"` |  |
| partitionCommon.worker.requests.cpu | string | `"500m"` |  |
| partitionCommon.worker.requests.memory | string | `"512Mi"` |  |
| partitions.bench.hpa.triggers[0].metadata.metricName | string | `"armonik_bench_tasks_queued"` |  |
| partitions.bench.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| partitions.bench.hpa.triggers[0].metadata.query | string | `"armonik_bench_tasks_queued{job=\"metrics-exporter\"}"` |  |
| partitions.bench.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| partitions.bench.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| partitions.bench.hpa.triggers[0].type | string | `"prometheus"` |  |
| partitions.bench.worker.image | string | `"armonik_core_bench_test_worker"` |  |
| partitions.bench.worker.tag | string | `"0.31.2"` |  |
| partitions.default.hpa.triggers[0].metadata.metricName | string | `"armonik_default_tasks_queued"` |  |
| partitions.default.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| partitions.default.hpa.triggers[0].metadata.query | string | `"armonik_default_tasks_queued{job=\"metrics-exporter\"}"` |  |
| partitions.default.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| partitions.default.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| partitions.default.hpa.triggers[0].type | string | `"prometheus"` |  |
| partitions.default.worker.image | string | `"armonik_worker_dll"` |  |
| partitions.default.worker.tag | string | `"0.18.0"` |  |
| partitions.htcmock.hpa.triggers[0].metadata.metricName | string | `"armonik_htcmock_tasks_queued"` |  |
| partitions.htcmock.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| partitions.htcmock.hpa.triggers[0].metadata.query | string | `"armonik_htcmock_tasks_queued{job=\"metrics-exporter\"}"` |  |
| partitions.htcmock.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| partitions.htcmock.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| partitions.htcmock.hpa.triggers[0].type | string | `"prometheus"` |  |
| partitions.htcmock.socketType | string | `"tcp"` |  |
| partitions.htcmock.worker.image | string | `"armonik_core_htcmock_test_worker"` |  |
| partitions.htcmock.worker.tag | string | `"0.31.2"` |  |
| partitions.stream.hpa.triggers[0].metadata.metricName | string | `"armonik_stream_tasks_queued"` |  |
| partitions.stream.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| partitions.stream.hpa.triggers[0].metadata.query | string | `"armonik_stream_tasks_queued{job=\"metrics-exporter\"}"` |  |
| partitions.stream.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| partitions.stream.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| partitions.stream.hpa.triggers[0].type | string | `"prometheus"` |  |
| partitions.stream.worker.image | string | `"armonik_core_stream_test_worker"` |  |
| partitions.stream.worker.tag | string | `"0.31.2"` |  |
| podDisruptionBudget.enabled | bool | `false` |  |
| podDisruptionBudget.maxUnavailable | string | `nil` |  |
| podDisruptionBudget.minAvailable | string | `nil` |  |
| pollingAgent.envConfigValue | list | `[]` |  |
| pollingAgent.envFrom[0].configMapRef.name | string | `"compute-plane-configmap"` |  |
| pollingAgent.envFrom[0].configMapRef.optional | bool | `false` |  |
| pollingAgent.envFrom[1].configMapRef.name | string | `"core-configmap"` |  |
| pollingAgent.envFrom[1].configMapRef.optional | bool | `false` |  |
| pollingAgent.envFrom[2].configMapRef.name | string | `"log-configmap"` |  |
| pollingAgent.envFrom[2].configMapRef.optional | bool | `false` |  |
| pollingAgent.envFrom[3].configMapRef.name | string | `"polling-configmap"` |  |
| pollingAgent.envFrom[3].configMapRef.optional | bool | `false` |  |
| pollingAgent.envSecretValue[0].name | string | `"MongoDB__Password"` |  |
| pollingAgent.envSecretValue[0].valueFrom.secretKeyRef.key | string | `"mongodb-root-password"` |  |
| pollingAgent.envSecretValue[0].valueFrom.secretKeyRef.name | string | `"mongodb"` |  |
| pollingAgent.envSecretValue[0].valueFrom.secretKeyRef.optional | bool | `false` |  |
| pollingAgent.envSecretValue[1].name | string | `"Redis__Password"` |  |
| pollingAgent.envSecretValue[1].valueFrom.secretKeyRef.key | string | `"redis-password"` |  |
| pollingAgent.envSecretValue[1].valueFrom.secretKeyRef.name | string | `"redis"` |  |
| pollingAgent.name | string | `"polling-agent"` |  |
| pollingAgent.ports.containerPort | int | `1080` |  |
| pollingAgent.ports.name | string | `"poll-agent-port"` |  |
| pollingAgent.volumeMounts[0].mountPath | string | `"/cache"` |  |
| pollingAgent.volumeMounts[0].mountPropagation | string | `"None"` |  |
| pollingAgent.volumeMounts[0].name | string | `"cache-volume"` |  |
| pollingAgentConfigmaps.data.Amqp__LinkCredit | string | `"2"` |  |
| pollingAgentConfigmaps.data.ComputePlane__MessageBatchSize | string | `"1"` |  |
| pollingAgentConfigmaps.data.InitWorker__WorkerCheckDelay | string | `"00:00:10"` |  |
| pollingAgentConfigmaps.data.InitWorker__WorkerCheckRetries | string | `"10"` |  |
| pollingAgentConfigmaps.data.Pollster__GraceDelay | string | `"00:00:15"` |  |
| pollingAgentConfigmaps.name | string | `"polling-configmap"` |  |
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
| triggers.behavior | object | `{"periodSeconds":15,"restoreToOriginalReplicaCount":false,"stabilizationWindowSeconds":300,"type":"Percent","value":100}` | Advanced options to manage the behavior of the HPA |
| triggers.behavior.periodSeconds | int | `15` | Period in seconds |
| triggers.behavior.restoreToOriginalReplicaCount | bool | `false` | Restore to the original replicas count |
| triggers.behavior.stabilizationWindowSeconds | int | `300` | Stabilization window in seconds |
| triggers.behavior.type | string | `"Percent"` | Type of the target |
| triggers.behavior.value | int | `100` | Value of the target |
| triggers.cooldownPeriod | int | `300` | Cooldown period in seconds |
| triggers.fallback | object | `{"failureThreshold":3,"replicas":6}` | Fallback options |
| triggers.fallback.failureThreshold | int | `3` | Threshold of failures |
| triggers.fallback.replicas | int | `6` | Number of replicas |
| triggers.idleReplicaCount | int | `0` | Count of idle replicas |
| triggers.maxReplicaCount | int | `5` | Maximum count of replicas |
| triggers.minReplicaCount | int | `1` | Minimum count of replicas |
| triggers.pollingInterval | int | `30` | Polling interval in seconds |
| triggers.scaleTargetRef.apiVersion | string | `"apps/v1"` | Kubernetes API version to be used |
| triggers.scaleTargetRef.kind | string | `"Deployment"` | Kid of the Kubernetes resource to be scaled |
| triggers.scaleTargetRef.name | string | `"compute-plane"` | Name of the Kubernetes resource to be scaled |
| triggers.suffix | string | `"armonik-scaledobject"` |  |
| volumes[0].emptyDir | object | `{}` |  |
| volumes[0].name | string | `"cache-volume"` |  |
| volumes[1].hostPath.path | string | `"/var/log/dmesg"` |  |
| volumes[1].hostPath.type | string | `""` |  |
| volumes[1].name | string | `"dmesg"` |  |
| volumes[2].configMap.defaultMode | int | `420` |  |
| volumes[2].configMap.name | string | `"fluent-bit-configmap"` |  |
| volumes[2].configMap.optional | bool | `false` |  |
| volumes[2].name | string | `"fluentbitconfig"` |  |
| volumes[3].hostPath.path | string | `"/run/log/journal"` |  |
| volumes[3].hostPath.type | string | `""` |  |
| volumes[3].name | string | `"runlogjournal"` |  |
| volumes[4].hostPath.path | string | `"/var/lib/docker/containers"` |  |
| volumes[4].hostPath.type | string | `""` |  |
| volumes[4].name | string | `"varlibdockercontainers"` |  |
| volumes[5].hostPath.path | string | `"/var/log"` |  |
| volumes[5].hostPath.type | string | `""` |  |
| volumes[5].name | string | `"varlog"` |  |
| worker.envConfigValue | list | `[]` |  |
| worker.envFrom[0].configMapRef.name | string | `"compute-plane-configmap"` |  |
| worker.envFrom[0].configMapRef.optional | bool | `false` |  |
| worker.envFrom[1].configMapRef.name | string | `"log-configmap"` |  |
| worker.envFrom[1].configMapRef.optional | bool | `false` |  |
| worker.envFrom[2].configMapRef.name | string | `"worker-configmap"` |  |
| worker.envFrom[2].configMapRef.optional | bool | `false` |  |
| worker.envHardValue | list | `[]` |  |
| worker.envSecretValue | list | `[]` |  |
| worker.livenessProbe.failureThreshold | int | `3` |  |
| worker.livenessProbe.httpGet.path | string | `"/liveness"` |  |
| worker.livenessProbe.httpGet.port | int | `1080` |  |
| worker.livenessProbe.httpGet.scheme | string | `"HTTP"` |  |
| worker.livenessProbe.initialDelaySeconds | int | `15` |  |
| worker.livenessProbe.periodSeconds | int | `10` |  |
| worker.livenessProbe.successThreshold | int | `1` |  |
| worker.livenessProbe.timeoutSeconds | int | `10` |  |
| worker.name | string | `"worker"` |  |
| worker.ports.containerPort | int | `1081` |  |
| worker.ports.name | string | `"worker-port"` |  |
| worker.resource.limits.cpu | string | `"1000m"` |  |
| worker.resource.limits.memory | string | `"1024Mi"` |  |
| worker.resource.requests.cpu | string | `"500m"` |  |
| worker.resource.requests.memory | string | `"256Mi"` |  |
| worker.startupProbe.failureThreshold | int | `20` |  |
| worker.startupProbe.httpGet.path | string | `"/startup"` |  |
| worker.startupProbe.httpGet.port | int | `1080` |  |
| worker.startupProbe.httpGet.scheme | string | `"HTTP"` |  |
| worker.startupProbe.initialDelaySeconds | int | `1` |  |
| worker.startupProbe.periodSeconds | int | `3` |  |
| worker.startupProbe.successThreshold | int | `1` |  |
| worker.startupProbe.timeoutSeconds | int | `1` |  |
| worker.terminationMessagePath | string | `"/dev/termination-log"` |  |
| worker.terminationMessagePolicy | string | `"File"` |  |
| worker.volumeMounts[0].mountPath | string | `"/cache"` |  |
| worker.volumeMounts[0].mountPropagation | string | `"None"` |  |
| worker.volumeMounts[0].name | string | `"cache-volume"` |  |
| workerConfigmaps.data.FileStorageType | string | `"FS"` |  |
| workerConfigmaps.data.target_data_path | string | `"/data"` |  |
| workerConfigmaps.data.target_zip_path | string | `"/tmp"` |  |
| workerConfigmaps.name | string | `"worker-configmap"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
