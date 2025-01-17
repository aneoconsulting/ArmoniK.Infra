# control-plane

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.2.2](https://img.shields.io/badge/AppVersion-0.2.2-informational?style=flat-square)

A Helm chart for ArmoniK Control Plane

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Aneo | <armonik-support@aneo.fr> | <armonik.fr> |

## Requirements

Kubernetes: `>=v1.23.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations | object | `{"key1":"val1"}` | control plane annotations |
| certificates.activemq.mountPath | string | `"/amqp"` |  |
| certificates.activemq.name | string | `"activemq-secret-volume"` |  |
| certificates.activemq.secretName | string | `"activemq"` |  |
| certificates.mongodb.mountPath | string | `"/mongodb"` |  |
| certificates.mongodb.name | string | `"mongodb-secret-volume"` |  |
| certificates.mongodb.secretName | string | `"mongodb"` |  |
| certificates.redis.mountPath | string | `"/redis"` |  |
| certificates.redis.name | string | `"redis-secret-volume"` |  |
| certificates.redis.secretName | string | `"redis"` |  |
| configmaps[0] | string | `"control-plane-configmap"` |  |
| configmaps[1] | string | `"log-configmap"` |  |
| configmaps[2] | string | `"core-configmap"` |  |
| containerPort | int | `1080` |  |
| controlPlanConfigmap.enabled | bool | `true` |  |
| controlPlaneSelector | list | `[]` |  |
| coreConfigmap.data.Amqp__CaPath | string | `"/amqp/chain.pem"` |  |
| coreConfigmap.data.Amqp__Scheme | string | `"AMQPS"` |  |
| coreConfigmap.data.Authenticator__RequireAuthentication | bool | `false` |  |
| coreConfigmap.data.Authenticator__RequireAuthorization | bool | `false` |  |
| coreConfigmap.data.Components__ObjectStorage | string | `"Redis"` |  |
| coreConfigmap.data.Components__QueueAdaptorSettings__AdapterAbsolutePath | string | `"/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll"` |  |
| coreConfigmap.data.Components__QueueAdaptorSettings__ClassName | string | `"ArmoniK.Core.Adapters.Amqp.QueueBuilder"` |  |
| coreConfigmap.data.Components__QueueStorage | string | `"Amqp"` |  |
| coreConfigmap.data.Components__TableStorage | string | `"MongoDB"` |  |
| coreConfigmap.data.MongoDB__CAFile | string | `"/mongodb/chain.pem"` |  |
| coreConfigmap.data.MongoDB__DatabaseName | string | `"database"` |  |
| coreConfigmap.data.MongoDB__DirectConnection | string | `"false"` |  |
| coreConfigmap.data.MongoDB__ReplicaSet | string | `"rs0"` |  |
| coreConfigmap.data.MongoDB__Tls | string | `"true"` |  |
| coreConfigmap.data.Redis__CaPath | string | `"/redis/chain.pem"` |  |
| coreConfigmap.data.Redis__ClientName | string | `"ArmoniK.Core"` |  |
| coreConfigmap.data.Redis__InstanceName | string | `"ArmoniKRedis"` |  |
| coreConfigmap.data.Redis__Ssl | string | `"true"` |  |
| coreConfigmap.enabled | bool | `true` |  |
| coreConfigmap.metadata.name | string | `"core-configmap-helm"` |  |
| credentials.Amqp__Host.key | string | `"host"` |  |
| credentials.Amqp__Host.name | string | `"activemq"` |  |
| credentials.Amqp__Password.key | string | `"password"` |  |
| credentials.Amqp__Password.name | string | `"activemq"` |  |
| credentials.Amqp__Port.key | string | `"port"` |  |
| credentials.Amqp__Port.name | string | `"activemq"` |  |
| credentials.Amqp__User | object | `{"key":"username","name":"activemq"}` | activemq |
| credentials.MongoDB__Host.key | string | `"host"` |  |
| credentials.MongoDB__Host.name | string | `"mongodb"` |  |
| credentials.MongoDB__Password.key | string | `"password"` |  |
| credentials.MongoDB__Password.name | string | `"mongodb"` |  |
| credentials.MongoDB__Port.key | string | `"port"` |  |
| credentials.MongoDB__Port.name | string | `"mongodb"` |  |
| credentials.MongoDB__User | object | `{"key":"username","name":"mongodb"}` | mongodb |
| credentials.Redis__EndpointUrl.key | string | `"url"` |  |
| credentials.Redis__EndpointUrl.name | string | `"redis"` |  |
| credentials.Redis__Password.key | string | `"password"` |  |
| credentials.Redis__Password.name | string | `"redis"` |  |
| credentials.Redis__User | object | `{"key":"username","name":"redis"}` | redis   |
| defaultPartition | string | `"default"` |  |
| extraConf.control.Submitter__MaxErrorAllowed | string | `"50"` |  |
| extraConf.core.Amqp__AllowHostMismatch | bool | `true` |  |
| extraConf.core.Amqp__MaxPriority | string | `"10"` |  |
| extraConf.core.Amqp__MaxRetries | string | `"5"` |  |
| extraConf.core.Amqp__QueueStorage__LockRefreshExtension | string | `"00:02:00"` |  |
| extraConf.core.Amqp__QueueStorage__LockRefreshPeriodicity | string | `"00:00:45"` |  |
| extraConf.core.Amqp__QueueStorage__PollPeriodicity | string | `"00:00:10"` |  |
| extraConf.core.MongoDB__AllowInsecureTls | bool | `true` |  |
| extraConf.core.MongoDB__DataRetention | string | `"1.00:00:00"` |  |
| extraConf.core.MongoDB__TableStorage__PollingDelay | string | `"00:00:01"` |  |
| extraConf.core.MongoDB__TableStorage__PollingDelayMax | string | `"00:00:10"` |  |
| extraConf.core.MongoDB__TableStorage__PollingDelayMin | string | `"00:00:01"` |  |
| extraConf.core.Redis__SslHost | string | `"127.0.0.1"` |  |
| extraConf.core.Redis__Timeout | int | `30000` |  |
| extraConf.core.Redis__TtlTimeSpan | string | `"1.00:00:00"` |  |
| image | string | `"dockerhubaneo/armonik_control:0.19.3"` | image is the armonik control plane image and the tag image:tag |
| imageInfo | object | `{"pullPolicy":"IfNotPresent","pullSecrets":"","registry":"docker.io","repository":"dockerhubaneo/armonik_control","tag":"0.19.3"}` | image  |
| labelsApp | string | `"armonik"` |  |
| labelsService | string | `"control-plane-helm"` |  |
| livenessProbe.failureThreshold | int | `1` |  |
| livenessProbe.httpGet.path | string | `"/liveness"` |  |
| livenessProbe.httpGet.port | int | `1081` |  |
| livenessProbe.initialDelaySeconds | int | `15` |  |
| livenessProbe.periodSeconds | int | `5` |  |
| livenessProbe.successThreshold | int | `1` |  |
| livenessProbe.timeoutSeconds | int | `1` |  |
| logConfigmap.data.loggingLevel | string | `"Information"` |  |
| logConfigmap.enabled | bool | `true` |  |
| logConfigmap.metadata.name | string | `"log-configmap-helm"` |  |
| logConfigmap.metadata.namespace | string | `"armonik"` |  |
| name | string | `"control-plane-helm"` | controlPlane contains all the values of the control plane deployment |
| nameOverride | string | `""` |  |
| namePort | string | `"http"` | deployment port name and containerPort |
| namespace | string | `"armonik"` | namespace is the namespace used for all resources |
| nodeSelector | list | `[]` | control plane node selector |
| partitionNames[0] | string | `"default"` |  |
| partitionNames[1] | string | `"monitoring"` |  |
| port | int | `5001` |  |
| protocol | string | `"TCP"` |  |
| replicaCount | int | `1` | replicaCount is the number of replicas |
| resources.limits.cpu | string | `"1000m"` |  |
| resources.limits.memory | string | `"2048Mi"` |  |
| resources.requests.cpu | string | `"50m"` |  |
| resources.requests.memory | string | `"50Mi"` |  |
| restartPolicy | string | `"Always"` | restart policy |
| secrets.activemq.caFileName | string | `"/amqp/chain.pem"` |  |
| secrets.activemq.name | string | `"activemq"` |  |
| secrets.deployedObjectStorageSecret | string | `"deployed-object-storage-helm"` |  |
| secrets.deployedQueueStorageSecret | string | `"deployed-queue-storage-helm"` |  |
| secrets.deployedTableStorageSecret | string | `"deployed-table-storage-helm"` |  |
| secrets.fluentBit | string | `"fluent-bit"` |  |
| secrets.grafana | string | `"grafana"` |  |
| secrets.metricsExporter | string | `"metrics-exporter"` |  |
| secrets.mongodb.caFileName | string | `"/mongodb/chain.pem"` |  |
| secrets.mongodb.name | string | `"mongodb"` |  |
| secrets.partitionMetrics_exporter | string | `"partition-metrics-exporter"` |  |
| secrets.prometheus | string | `"prometheus"` |  |
| secrets.redis.caFileName | string | `"/redis/chain.pem"` |  |
| secrets.redis.name | string | `"redis"` |  |
| secrets.s3 | string | `"s3"` |  |
| secrets.seq | string | `"seq"` |  |
| secrets.sharedStorage.fileServerIp | string | `""` |  |
| secrets.sharedStorage.fileStorageType | string | `"HostPath"` |  |
| secrets.sharedStorage.hostPath | string | `"data"` |  |
| secrets.sharedStorage.name | string | `"shared-storage-helm"` |  |
| secrets.storageEndpointUrl.deployedObjectStorages[0] | string | `"Redis"` |  |
| secrets.storageEndpointUrl.deployedQueueStorages[0] | string | `"Amqp"` |  |
| secrets.storageEndpointUrl.deployedTableStorages[0] | string | `"MongoDB"` |  |
| secrets.storageEndpointUrl.objectStorageAdapter | string | `"Redis"` |  |
| secrets.storageEndpointUrl.queueStorageAdapter | string | `"Amqp"` |  |
| secrets.storageEndpointUrl.tableStorageAdapter | string | `"MongoDB"` |  |
| serviceAccountName | string | `""` |  |
| serviceType | string | `"ClusterIP"` | service type and port and protocol |
| startupProbe.failureThreshold | int | `20` |  |
| startupProbe.httpGet.path | string | `"/startup"` |  |
| startupProbe.httpGet.port | int | `1081` |  |
| startupProbe.initialDelaySeconds | int | `1` |  |
| startupProbe.periodSeconds | int | `3` |  |
| startupProbe.successThreshold | int | `1` |  |
| startupProbe.timeoutSeconds | int | `1` |  |

