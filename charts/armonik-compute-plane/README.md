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
| computePlane.partition.bench.envHardValue[0].name | string | `"Amqp__PartitionId"` |  |
| computePlane.partition.bench.envHardValue[0].value | string | `"bench"` |  |
| computePlane.partition.bench.envHardValue[1].name | string | `"PubSub__PartitionId"` |  |
| computePlane.partition.bench.envHardValue[1].value | string | `"bench"` |  |
| computePlane.partition.bench.envHardValue[2].name | string | `"SQS__PartitionId"` |  |
| computePlane.partition.bench.envHardValue[2].value | string | `"bench"` |  |
| computePlane.partition.bench.envHardValue[3].name | string | `"MongoDB__User"` |  |
| computePlane.partition.bench.envHardValue[3].value | string | `"root"` |  |
| computePlane.partition.bench.hpa.triggers[0].metadata.metricName | string | `"armonik_bench_tasks_queued"` |  |
| computePlane.partition.bench.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| computePlane.partition.bench.hpa.triggers[0].metadata.query | string | `"armonik_bench_tasks_queued{job=\"metrics-exporter\"}"` |  |
| computePlane.partition.bench.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| computePlane.partition.bench.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| computePlane.partition.bench.hpa.triggers[0].type | string | `"prometheus"` |  |
| computePlane.partition.bench.worker[0].image | string | `"armonik_core_bench_test_worker"` |  |
| computePlane.partition.bench.worker[0].imagePullPolicy | string | `"IfNotPresent"` |  |
| computePlane.partition.bench.worker[0].limits.cpu | string | `"1000m"` |  |
| computePlane.partition.bench.worker[0].limits.memory | string | `"1024Mi"` |  |
| computePlane.partition.bench.worker[0].name | string | `"worker"` |  |
| computePlane.partition.bench.worker[0].requests.cpu | string | `"500m"` |  |
| computePlane.partition.bench.worker[0].requests.memory | string | `"512Mi"` |  |
| computePlane.partition.bench.worker[0].tag | string | `"0.31.2"` |  |
| computePlane.partition.default.envHardValue[0].name | string | `"Amqp__PartitionId"` |  |
| computePlane.partition.default.envHardValue[0].value | string | `"default"` |  |
| computePlane.partition.default.envHardValue[1].name | string | `"PubSub__PartitionId"` |  |
| computePlane.partition.default.envHardValue[1].value | string | `"default"` |  |
| computePlane.partition.default.envHardValue[2].name | string | `"SQS__PartitionId"` |  |
| computePlane.partition.default.envHardValue[2].value | string | `"default"` |  |
| computePlane.partition.default.hpa.triggers[0].metadata.metricName | string | `"armonik_default_tasks_queued"` |  |
| computePlane.partition.default.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| computePlane.partition.default.hpa.triggers[0].metadata.query | string | `"armonik_default_tasks_queued{job=\"metrics-exporter\"}"` |  |
| computePlane.partition.default.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| computePlane.partition.default.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| computePlane.partition.default.hpa.triggers[0].type | string | `"prometheus"` |  |
| computePlane.partition.default.worker[0].image | string | `"armonik_worker_dll"` |  |
| computePlane.partition.default.worker[0].imagePullPolicy | string | `"IfNotPresent"` |  |
| computePlane.partition.default.worker[0].limits.cpu | string | `"1000m"` |  |
| computePlane.partition.default.worker[0].limits.memory | string | `"1024Mi"` |  |
| computePlane.partition.default.worker[0].name | string | `"worker"` |  |
| computePlane.partition.default.worker[0].requests.cpu | string | `"500m"` |  |
| computePlane.partition.default.worker[0].requests.memory | string | `"512Mi"` |  |
| computePlane.partition.default.worker[0].tag | string | `"0.18.0"` |  |
| computePlane.partition.htcmock.envCommon[0].name | string | `"ComputePlane__WorkerChannel__SocketType"` |  |
| computePlane.partition.htcmock.envCommon[0].value | string | `"tcp"` |  |
| computePlane.partition.htcmock.envCommon[1].name | string | `"ComputePlane__WorkerChannel__Address"` |  |
| computePlane.partition.htcmock.envCommon[1].value | string | `"http://localhost:6666"` |  |
| computePlane.partition.htcmock.envCommon[2].name | string | `"ComputePlane__AgentChannel__SocketType"` |  |
| computePlane.partition.htcmock.envCommon[2].value | string | `"tcp"` |  |
| computePlane.partition.htcmock.envCommon[3].name | string | `"ComputePlane__AgentChannel__Address"` |  |
| computePlane.partition.htcmock.envCommon[3].value | string | `"http://localhost:6667"` |  |
| computePlane.partition.htcmock.envHardValue[0].name | string | `"Amqp__PartitionId"` |  |
| computePlane.partition.htcmock.envHardValue[0].value | string | `"htcmock"` |  |
| computePlane.partition.htcmock.envHardValue[1].name | string | `"PubSub__PartitionId"` |  |
| computePlane.partition.htcmock.envHardValue[1].value | string | `"htcmock"` |  |
| computePlane.partition.htcmock.envHardValue[2].name | string | `"SQS__PartitionId"` |  |
| computePlane.partition.htcmock.envHardValue[2].value | string | `"htcmock"` |  |
| computePlane.partition.htcmock.envHardValue[3].name | string | `"MongoDB__User"` |  |
| computePlane.partition.htcmock.envHardValue[3].value | string | `"root"` |  |
| computePlane.partition.htcmock.hpa.triggers[0].metadata.metricName | string | `"armonik_htcmock_tasks_queued"` |  |
| computePlane.partition.htcmock.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| computePlane.partition.htcmock.hpa.triggers[0].metadata.query | string | `"armonik_htcmock_tasks_queued{job=\"metrics-exporter\"}"` |  |
| computePlane.partition.htcmock.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| computePlane.partition.htcmock.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| computePlane.partition.htcmock.hpa.triggers[0].type | string | `"prometheus"` |  |
| computePlane.partition.htcmock.worker[0].image | string | `"armonik_core_htcmock_test_worker"` |  |
| computePlane.partition.htcmock.worker[0].imagePullPolicy | string | `"IfNotPresent"` |  |
| computePlane.partition.htcmock.worker[0].limits.cpu | string | `"1000m"` |  |
| computePlane.partition.htcmock.worker[0].limits.memory | string | `"1024Mi"` |  |
| computePlane.partition.htcmock.worker[0].name | string | `"worker"` |  |
| computePlane.partition.htcmock.worker[0].requests.cpu | string | `"500m"` |  |
| computePlane.partition.htcmock.worker[0].requests.memory | string | `"512Mi"` |  |
| computePlane.partition.htcmock.worker[0].tag | string | `"0.31.2"` |  |
| computePlane.partition.stream.envHardValue[0].name | string | `"Amqp__PartitionId"` |  |
| computePlane.partition.stream.envHardValue[0].value | string | `"stream"` |  |
| computePlane.partition.stream.envHardValue[1].name | string | `"PubSub__PartitionId"` |  |
| computePlane.partition.stream.envHardValue[1].value | string | `"stream"` |  |
| computePlane.partition.stream.envHardValue[2].name | string | `"SQS__PartitionId"` |  |
| computePlane.partition.stream.envHardValue[2].value | string | `"stream"` |  |
| computePlane.partition.stream.envHardValue[3].name | string | `"MongoDB__User"` |  |
| computePlane.partition.stream.envHardValue[3].value | string | `"root"` |  |
| computePlane.partition.stream.hpa.triggers[0].metadata.metricName | string | `"armonik_stream_tasks_queued"` |  |
| computePlane.partition.stream.hpa.triggers[0].metadata.namespace | string | `"armonik"` |  |
| computePlane.partition.stream.hpa.triggers[0].metadata.query | string | `"armonik_stream_tasks_queued{job=\"metrics-exporter\"}"` |  |
| computePlane.partition.stream.hpa.triggers[0].metadata.serverAddress | string | `"http://prometheus-prometheus:9090"` |  |
| computePlane.partition.stream.hpa.triggers[0].metadata.threshold | string | `"2"` |  |
| computePlane.partition.stream.hpa.triggers[0].type | string | `"prometheus"` |  |
| computePlane.partition.stream.worker[0].image | string | `"armonik_core_stream_test_worker"` |  |
| computePlane.partition.stream.worker[0].imagePullPolicy | string | `"IfNotPresent"` |  |
| computePlane.partition.stream.worker[0].limits.cpu | string | `"1000m"` |  |
| computePlane.partition.stream.worker[0].limits.memory | string | `"1024Mi"` |  |
| computePlane.partition.stream.worker[0].name | string | `"worker"` |  |
| computePlane.partition.stream.worker[0].requests.cpu | string | `"500m"` |  |
| computePlane.partition.stream.worker[0].requests.memory | string | `"512Mi"` |  |
| computePlane.partition.stream.worker[0].tag | string | `"0.31.2"` |  |
| computePlane.partitionCommon.annotations | object | `{}` |  |
| computePlane.partitionCommon.envCommon | list | `[]` |  |
| computePlane.partitionCommon.envHardValue | list | `[]` |  |
| computePlane.partitionCommon.hpa.behavior.period_seconds | int | `15` |  |
| computePlane.partitionCommon.hpa.behavior.restore_to_original_replica_count | bool | `true` |  |
| computePlane.partitionCommon.hpa.behavior.stabilization_window_seconds | int | `300` |  |
| computePlane.partitionCommon.hpa.behavior.type | string | `"Percent"` |  |
| computePlane.partitionCommon.hpa.behavior.value | int | `100` |  |
| computePlane.partitionCommon.hpa.cooldown_period | int | `300` |  |
| computePlane.partitionCommon.hpa.max_replica_count | int | `5` |  |
| computePlane.partitionCommon.hpa.min_replica_count | int | `0` |  |
| computePlane.partitionCommon.hpa.polling_interval | int | `15` |  |
| computePlane.partitionCommon.hpa.triggers | list | `[]` |  |
| computePlane.partitionCommon.hpa.type | string | `"prometheus"` |  |
| computePlane.partitionCommon.livenessProbe.failureThreshold | int | `3` |  |
| computePlane.partitionCommon.livenessProbe.httpGet.path | string | `"/liveness"` |  |
| computePlane.partitionCommon.livenessProbe.httpGet.port | int | `1080` |  |
| computePlane.partitionCommon.livenessProbe.httpGet.scheme | string | `"HTTP"` |  |
| computePlane.partitionCommon.livenessProbe.initialDelaySeconds | int | `15` |  |
| computePlane.partitionCommon.livenessProbe.periodSeconds | int | `10` |  |
| computePlane.partitionCommon.livenessProbe.successThreshold | int | `1` |  |
| computePlane.partitionCommon.livenessProbe.timeoutSeconds | int | `10` |  |
| computePlane.partitionCommon.nodeSelector | object | `{}` |  |
| computePlane.partitionCommon.pollingAgent.enableServiceLinks | bool | `true` |  |
| computePlane.partitionCommon.pollingAgent.image | string | `"armonik_pollingagent"` |  |
| computePlane.partitionCommon.pollingAgent.imagePullPolicy | string | `"IfNotPresent"` |  |
| computePlane.partitionCommon.pollingAgent.limits.cpu | string | `"1000m"` |  |
| computePlane.partitionCommon.pollingAgent.limits.memory | string | `"1024Mi"` |  |
| computePlane.partitionCommon.pollingAgent.requests.cpu | string | `"500m"` |  |
| computePlane.partitionCommon.pollingAgent.requests.memory | string | `"256Mi"` |  |
| computePlane.partitionCommon.pollingAgent.securityContext.allowPrivilegeEscalation | bool | `true` |  |
| computePlane.partitionCommon.pollingAgent.securityContext.capabilities.drop[0] | string | `"SYS_PTRACE"` |  |
| computePlane.partitionCommon.pollingAgent.securityContext.privileged | bool | `false` |  |
| computePlane.partitionCommon.pollingAgent.securityContext.readOnlyRootFilesystem | bool | `false` |  |
| computePlane.partitionCommon.pollingAgent.securityContext.runAsNonRoot | bool | `false` |  |
| computePlane.partitionCommon.pollingAgent.tag | string | `"0.31.2"` |  |
| computePlane.partitionCommon.readinessProbe | object | `{}` |  |
| computePlane.partitionCommon.replicas | int | `1` |  |
| computePlane.partitionCommon.startupProbe.failureThreshold | int | `20` |  |
| computePlane.partitionCommon.startupProbe.httpGet.path | string | `"/startup"` |  |
| computePlane.partitionCommon.startupProbe.httpGet.port | int | `1080` |  |
| computePlane.partitionCommon.startupProbe.httpGet.scheme | string | `"HTTP"` |  |
| computePlane.partitionCommon.startupProbe.initialDelaySeconds | int | `1` |  |
| computePlane.partitionCommon.startupProbe.periodSeconds | int | `3` |  |
| computePlane.partitionCommon.startupProbe.successThreshold | int | `1` |  |
| computePlane.partitionCommon.startupProbe.timeoutSeconds | int | `1` |  |
| computePlane.partitionCommon.terminationGracePeriodSeconds | int | `30` |  |
| computePlane.partitionCommon.tolerations | list | `[]` |  |
| computePlane.partitionCommon.worker | list | `[]` |  |
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
