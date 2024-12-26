# compute-plane

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.2.2](https://img.shields.io/badge/AppVersion-0.2.2-informational?style=flat-square)

A Helm chart for Armonik Compute Plane

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Aneo | <armonik-support@aneo.fr> | <armonik.fr> |

## Requirements

Kubernetes: `>=v1.23.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| FS.mountPath | string | `"/data"` |  |
| FS.name | string | `"shared-volume"` |  |
| certificates.activemq.mountPath | string | `"/amqp"` |  |
| certificates.activemq.name | string | `"activemq-secret-volume"` |  |
| certificates.activemq.secretName | string | `"activemq"` |  |
| certificates.mongodb.mountPath | string | `"/mongodb"` |  |
| certificates.mongodb.name | string | `"mongodb-secret-volume"` |  |
| certificates.mongodb.secretName | string | `"mongodb"` |  |
| certificates.redis.mountPath | string | `"/redis"` |  |
| certificates.redis.name | string | `"redis-secret-volume"` |  |
| certificates.redis.secretName | string | `"redis"` |  |
| checkFileStorageType | string | `"FS"` |  |
| computePlane.metadata.labels.app | string | `"armonik"` |  |
| computePlane.metadata.labels.service | string | `"compute-plane"` |  |
| computePlane.partition.bench.hpa.behavior.period_seconds | int | `15` |  |
| computePlane.partition.bench.hpa.behavior.restoreToOriginalReplicaCount | bool | `true` |  |
| computePlane.partition.bench.hpa.behavior.stabilizationWindowSeconds | int | `300` |  |
| computePlane.partition.bench.hpa.behavior.type | string | `"Percent"` |  |
| computePlane.partition.bench.hpa.behavior.value | int | `100` |  |
| computePlane.partition.bench.hpa.cooldownPeriod | int | `300` |  |
| computePlane.partition.bench.hpa.maxReplicaCount | int | `5` |  |
| computePlane.partition.bench.hpa.minReplicaCount | int | `0` |  |
| computePlane.partition.bench.hpa.pollingInterval | int | `15` |  |
| computePlane.partition.bench.hpa.triggers[0].threshold | int | `2` |  |
| computePlane.partition.bench.hpa.triggers[0].type | string | `"prometheus"` |  |
| computePlane.partition.bench.hpa.type | string | `"prometheus"` |  |
| computePlane.partition.bench.pollingAgent.image | string | `"dockerhubaneo/armonik_core_bench_test_client"` |  |
| computePlane.partition.bench.pollingAgent.limits.cpu | string | `"2000m"` |  |
| computePlane.partition.bench.pollingAgent.limits.memory | string | `"2048Mi"` |  |
| computePlane.partition.bench.pollingAgent.requests.cpu | string | `"50m"` |  |
| computePlane.partition.bench.pollingAgent.requests.memory | string | `"50Mi"` |  |
| computePlane.partition.bench.replicas | int | `0` |  |
| computePlane.partition.bench.worker[0].image | string | `"dockerhubaneo/armonik_core_bench_test_worker"` |  |
| computePlane.partition.bench.worker[0].limits.cpu | string | `"1000m"` |  |
| computePlane.partition.bench.worker[0].limits.memory | string | `"1024Mi"` |  |
| computePlane.partition.bench.worker[0].name | string | `"bench-worker"` |  |
| computePlane.partition.bench.worker[0].requests.cpu | string | `"50m"` |  |
| computePlane.partition.bench.worker[0].requests.memory | string | `"50Mi"` |  |
| computePlane.partition.default.hpa.behavior.period_seconds | int | `15` |  |
| computePlane.partition.default.hpa.behavior.restore_to_original_replica_count | bool | `true` |  |
| computePlane.partition.default.hpa.behavior.stabilization_window_seconds | int | `300` |  |
| computePlane.partition.default.hpa.behavior.type | string | `"Percent"` |  |
| computePlane.partition.default.hpa.behavior.value | int | `100` |  |
| computePlane.partition.default.hpa.cooldown_period | int | `300` |  |
| computePlane.partition.default.hpa.max_replica_count | int | `5` |  |
| computePlane.partition.default.hpa.min_replica_count | int | `0` |  |
| computePlane.partition.default.hpa.polling_interval | int | `15` |  |
| computePlane.partition.default.hpa.triggers[0].threshold | int | `2` |  |
| computePlane.partition.default.hpa.triggers[0].type | string | `"prometheus"` |  |
| computePlane.partition.default.hpa.type | string | `"prometheus"` |  |
| computePlane.partition.default.pollingAgent.image | string | `"dockerhubaneo/armonik_pollingagent"` |  |
| computePlane.partition.default.pollingAgent.limits.cpu | string | `"2000m"` |  |
| computePlane.partition.default.pollingAgent.limits.memory | string | `"2048Mi"` |  |
| computePlane.partition.default.pollingAgent.requests.cpu | string | `"50m"` |  |
| computePlane.partition.default.pollingAgent.requests.memory | string | `"50Mi"` |  |
| computePlane.partition.default.replicas | int | `0` |  |
| computePlane.partition.default.worker[0].image | string | `"dockerhubaneo/armonik_worker_dll"` |  |
| computePlane.partition.default.worker[0].imagePullPolicy | string | `"IfNotPresent"` |  |
| computePlane.partition.default.worker[0].limits.cpu | string | `"1000m"` |  |
| computePlane.partition.default.worker[0].limits.memory | string | `"1024Mi"` |  |
| computePlane.partition.default.worker[0].name | string | `"default-worker"` |  |
| computePlane.partition.default.worker[0].requests.cpu | string | `"50m"` |  |
| computePlane.partition.default.worker[0].requests.memory | string | `"50Mi"` |  |
| computePlane.partition.htcmock.hpa.behavior.periodSeconds | int | `15` |  |
| computePlane.partition.htcmock.hpa.behavior.restoreToOriginalReplicaCount | bool | `true` |  |
| computePlane.partition.htcmock.hpa.behavior.stabilizationWindowSeconds | int | `300` |  |
| computePlane.partition.htcmock.hpa.behavior.type | string | `"Percent"` |  |
| computePlane.partition.htcmock.hpa.behavior.value | int | `100` |  |
| computePlane.partition.htcmock.hpa.cooldownPeriod | int | `300` |  |
| computePlane.partition.htcmock.hpa.maxReplicaCount | int | `5` |  |
| computePlane.partition.htcmock.hpa.minReplicaCount | int | `0` |  |
| computePlane.partition.htcmock.hpa.pollingInterval | int | `15` |  |
| computePlane.partition.htcmock.hpa.triggers[0].threshold | int | `2` |  |
| computePlane.partition.htcmock.hpa.triggers[0].type | string | `"prometheus"` |  |
| computePlane.partition.htcmock.hpa.type | string | `"prometheus"` |  |
| computePlane.partition.htcmock.pollingAgent.image | string | `"dockerhubaneo/armonik_core_htcmock_test_client"` |  |
| computePlane.partition.htcmock.pollingAgent.limits.cpu | string | `"2000m"` |  |
| computePlane.partition.htcmock.pollingAgent.limits.memory | string | `"2048Mi"` |  |
| computePlane.partition.htcmock.pollingAgent.requests.cpu | string | `"50m"` |  |
| computePlane.partition.htcmock.pollingAgent.requests.memory | string | `"50Mi"` |  |
| computePlane.partition.htcmock.replicas | int | `0` |  |
| computePlane.partition.htcmock.worker[0].image | string | `"dockerhubaneo/armonik_core_htcmock_test_worker"` |  |
| computePlane.partition.htcmock.worker[0].limits.cpu | string | `"1000m"` |  |
| computePlane.partition.htcmock.worker[0].limits.memory | string | `"1024Mi"` |  |
| computePlane.partition.htcmock.worker[0].name | string | `"htcmock-worker"` |  |
| computePlane.partition.htcmock.worker[0].requests.cpu | string | `"50m"` |  |
| computePlane.partition.htcmock.worker[0].requests.memory | string | `"50Mi"` |  |
| computePlane.partition.stream.hpa.behavior.period_seconds | int | `15` |  |
| computePlane.partition.stream.hpa.behavior.restoreToOriginalReplicaCount | bool | `true` |  |
| computePlane.partition.stream.hpa.behavior.stabilizationWindowSeconds | int | `300` |  |
| computePlane.partition.stream.hpa.behavior.type | string | `"Percent"` |  |
| computePlane.partition.stream.hpa.behavior.value | int | `100` |  |
| computePlane.partition.stream.hpa.cooldown_period | int | `300` |  |
| computePlane.partition.stream.hpa.maxReplicaCount | int | `5` |  |
| computePlane.partition.stream.hpa.minReplicaCount | int | `0` |  |
| computePlane.partition.stream.hpa.polling_interval | int | `15` |  |
| computePlane.partition.stream.hpa.triggers[0].threshold | int | `2` |  |
| computePlane.partition.stream.hpa.triggers[0].type | string | `"prometheus"` |  |
| computePlane.partition.stream.hpa.type | string | `"prometheus"` |  |
| computePlane.partition.stream.pollingAgent.image | string | `"dockerhubaneo/armonik_core_stream_test_client"` |  |
| computePlane.partition.stream.pollingAgent.limits.cpu | string | `"2000m"` |  |
| computePlane.partition.stream.pollingAgent.limits.memory | string | `"2048Mi"` |  |
| computePlane.partition.stream.pollingAgent.requests.cpu | string | `"50m"` |  |
| computePlane.partition.stream.pollingAgent.requests.memory | string | `"50Mi"` |  |
| computePlane.partition.stream.replicas | int | `0` |  |
| computePlane.partition.stream.worker[0].image | string | `"dockerhubaneo/armonik_core_stream_test_worker"` |  |
| computePlane.partition.stream.worker[0].limits.cpu | string | `"1000m"` |  |
| computePlane.partition.stream.worker[0].limits.memory | string | `"1024Mi"` |  |
| computePlane.partition.stream.worker[0].name | string | `"stream-worker"` |  |
| computePlane.partition.stream.worker[0].requests.cpu | string | `"50m"` |  |
| computePlane.partition.stream.worker[0].requests.memory | string | `"50Mi"` |  |
| credentials.Amqp__Host.key | string | `"host"` |  |
| credentials.Amqp__Host.name | string | `"activemq"` |  |
| credentials.Amqp__Password.key | string | `"password"` |  |
| credentials.Amqp__Password.name | string | `"activemq"` |  |
| credentials.Amqp__Port.key | string | `"port"` |  |
| credentials.Amqp__Port.name | string | `"activemq"` |  |
| credentials.Amqp__User.key | string | `"username"` |  |
| credentials.Amqp__User.name | string | `"activemq"` |  |
| credentials.MongoDB__Host.key | string | `"host"` |  |
| credentials.MongoDB__Host.name | string | `"mongodb"` |  |
| credentials.MongoDB__Password.key | string | `"password"` |  |
| credentials.MongoDB__Password.name | string | `"mongodb"` |  |
| credentials.MongoDB__Port.key | string | `"port"` |  |
| credentials.MongoDB__Port.name | string | `"mongodb"` |  |
| credentials.MongoDB__User.key | string | `"username"` |  |
| credentials.MongoDB__User.name | string | `"mongodb"` |  |
| credentials.Redis__EndpointUrl.key | string | `"url"` |  |
| credentials.Redis__EndpointUrl.name | string | `"redis"` |  |
| credentials.Redis__Password.key | string | `"password"` |  |
| credentials.Redis__Password.name | string | `"redis"` |  |
| credentials.Redis__User.key | string | `"username"` |  |
| credentials.Redis__User.name | string | `"redis"` |  |
| extraConf.compute | object | `{}` |  |
| extraConf.control | object | `{}` |  |
| extraConf.core | object | `{}` |  |
| extraConf.log | object | `{}` |  |
| extraConf.polling | object | `{}` |  |
| extraConf.worker | object | `{}` |  |
| fileStorageEndpoints.s3Storage.AccessKeyId | object | `{}` |  |
| fileStorageEndpoints.s3Storage.BucketName | object | `{}` |  |
| fileStorageEndpoints.s3Storage.MustForcePathStyle | object | `{}` |  |
| fileStorageEndpoints.s3Storage.SecretAccessKey | object | `{}` |  |
| fileStorageEndpoints.s3Storage.ServiceURL | object | `{}` |  |
| fileStorageEndpoints.s3Storage.UseChecksum | object | `{}` |  |
| fileStorageEndpoints.s3Storage.UseChunkEncoding | object | `{}` |  |
| fileStorageType | string | `"nfs"` |  |
| hostPath.name | string | `"shared-volume"` |  |
| hostPath.path | string | `"/data"` |  |
| nameOverride | string | `"armonik-compute-plane"` |  |
| namespace | string | `"armonik"` | namespace is the namespace used for all resources |
| nfs.name | string | `"shared-volume"` |  |
| nfs.path | string | `"/data"` |  |
| nfs.server | string | `"test"` |  |
| pollingAgent.image | string | `nil` |  |
| pollingAgent.imagePullPolicy | string | `nil` |  |
| pollingAgent.livenessProbe.failureThreshold | int | `3` |  |
| pollingAgent.livenessProbe.httpGet.path | string | `"/liveness"` |  |
| pollingAgent.livenessProbe.httpGet.port | int | `1080` |  |
| pollingAgent.livenessProbe.initialDelaySeconds | int | `15` |  |
| pollingAgent.livenessProbe.periodSeconds | int | `10` |  |
| pollingAgent.livenessProbe.successThreshold | int | `1` |  |
| pollingAgent.livenessProbe.timeoutSeconds | int | `10` |  |
| pollingAgent.name | string | `"polling-agent"` |  |
| pollingAgent.ports.containerPort | int | `1080` |  |
| pollingAgent.ports.name | string | `"poll-agent-port"` |  |
| pollingAgent.startupProbe.failureThreshold | int | `20` |  |
| pollingAgent.startupProbe.httpGet.path | string | `"/startup"` |  |
| pollingAgent.startupProbe.httpGet.port | int | `1080` |  |
| pollingAgent.startupProbe.initialDelaySeconds | int | `1` |  |
| pollingAgent.startupProbe.periodSeconds | int | `3` |  |
| pollingAgent.startupProbe.successThreshold | int | `1` |  |
| pollingAgent.startupProbe.timeoutSeconds | int | `1` |  |
| pollingAgent.workerCheckDelay | string | `"00:00:10"` |  |
| pollingAgent.workerCheckRetries | string | `"10"` |  |
| pollingAgentConfigmaps[0] | string | `"log-configmap"` |  |
| pollingAgentConfigmaps[1] | string | `"polling-agent-configmap"` |  |
| pollingAgentConfigmaps[2] | string | `"core-configmap"` |  |
| pollingAgentConfigmaps[3] | string | `"compute-plane-configmap"` |  |
| preStopWaitScript | string | `"<<EOF while test -e /cache/armonik_agent.sock ; do   sleep 1 done EOF"` |  |
| replicaCount | int | `1` |  |
| restartPolicy | string | `"Always"` |  |
| shareProcessNamespace | bool | `false` |  |
| supportedQueues[0] | string | `"Amqp__PartitionId"` |  |
| supportedQueues[1] | string | `"PubSub__PartitionId"` |  |
| supportedQueues[2] | string | `"SQS__PartitionId"` |  |
| volumeMount.mountPath | string | `"/cache"` |  |
| volumeMount.name | string | `"cache-volume"` |  |
| workerConfigmaps[0] | string | `"worker-configmap"` |  |
| workerConfigmaps[1] | string | `"compute-plane-configmap"` |  |
| workerConfigmaps[2] | string | `"log-configmap"` |  |

