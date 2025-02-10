# control-plane

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.2.2](https://img.shields.io/badge/AppVersion-0.2.2-informational?style=flat-square)

A Helm chart for Armonik

**Homepage:** <https://github.com/aneoconsulting/ArmoniK>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Aneo | <armonik-support@aneo.fr> | <armonik.fr> |

## Source Code

* <https://aneoconsulting.github.io/>

## Requirements

Kubernetes: `>=v1.23.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations | object | `{}` |  |
| certificates.enable | bool | `false` |  |
| config.computePlane.partitions.bench | object | `{}` |  |
| config.computePlane.partitions.default | object | `{}` |  |
| config.computePlane.partitions.htcmock | object | `{}` |  |
| config.computePlane.partitions.stream | object | `{}` |  |
| config.controlPlane.data.Submitter__MaxErrorAllowed | string | `"50"` |  |
| config.controlPlane.defaultPartition | string | `"default"` |  |
| config.controlPlane.name | string | `"control-plane-configmap"` |  |
| config.core.data.Amqp__Host | string | `"activemq"` |  |
| config.core.data.Amqp__MaxPriority | string | `"10"` |  |
| config.core.data.Amqp__Password | string | `"admin"` |  |
| config.core.data.Amqp__Port | string | `"5672"` |  |
| config.core.data.Amqp__QueueStorage__LockRefreshExtension | string | `"00:02:00"` |  |
| config.core.data.Amqp__QueueStorage__LockRefreshPeriodicity | string | `"00:00:45"` |  |
| config.core.data.Amqp__QueueStorage__PollPeriodicity | string | `"00:00:10"` |  |
| config.core.data.Amqp__Scheme | string | `"AMQP"` |  |
| config.core.data.Amqp__User | string | `"admin"` |  |
| config.core.data.Authenticator__RequireAuthentication | string | `"false"` |  |
| config.core.data.Authenticator__RequireAuthorization | string | `"false"` |  |
| config.core.data.Components__ObjectStorage | string | `"ArmoniK.Adapters.Redis.ObjectStorage"` |  |
| config.core.data.Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath | string | `"/adapters/object/redis/ArmoniK.Core.Adapters.Redis.dll"` |  |
| config.core.data.Components__ObjectStorageAdaptorSettings__ClassName | string | `"ArmoniK.Core.Adapters.Redis.ObjectBuilder"` |  |
| config.core.data.Components__QueueAdaptorSettings__AdapterAbsolutePath | string | `"/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll"` |  |
| config.core.data.Components__QueueAdaptorSettings__ClassName | string | `"ArmoniK.Core.Adapters.Amqp.QueueBuilder"` |  |
| config.core.data.Components__TableStorage | string | `"ArmoniK.Adapters.MongoDB.TableStorage"` |  |
| config.core.data.MongoDB__AllowInsecureTls | string | `"true"` |  |
| config.core.data.MongoDB__AuthSource | string | `"admin"` |  |
| config.core.data.MongoDB__DataRetention | string | `"1.00:00:00"` |  |
| config.core.data.MongoDB__DatabaseName | string | `"database"` |  |
| config.core.data.MongoDB__DirectConnection | string | `"true"` |  |
| config.core.data.MongoDB__Host | string | `"mongodb-headless"` |  |
| config.core.data.MongoDB__Port | string | `"27017"` |  |
| config.core.data.MongoDB__ReplicaSet | string | `"rs0"` |  |
| config.core.data.MongoDB__TableStorage__PollingDelay | string | `"00:00:01"` |  |
| config.core.data.MongoDB__TableStorage__PollingDelayMax | string | `"00:00:10"` |  |
| config.core.data.MongoDB__TableStorage__PollingDelayMin | string | `"00:00:01"` |  |
| config.core.data.MongoDB__Tls | string | `"false"` |  |
| config.core.data.MongoDB__User | string | `"root"` |  |
| config.core.data.Redis__ClientName | string | `"ArmoniK.Core"` |  |
| config.core.data.Redis__EndpointUrl | string | `"redis-master:6379"` |  |
| config.core.data.Redis__InstanceName | string | `"ArmoniKRedis"` |  |
| config.core.data.Redis__Ssl | string | `"false"` |  |
| config.core.data.Redis__Timeout | string | `"30000"` |  |
| config.core.data.Redis__TtlTimeSpan | string | `"1.00:00:00"` |  |
| config.core.data.Redis__User | string | `""` |  |
| config.core.name | string | `"core-configmap"` |  |
| config.log.data.minimumLevel | string | `"Information"` |  |
| config.log.data.overrides."ArmoniK.Core.Common.Auth.Authentication.Authenticator" | string | `"Warning"` |  |
| config.log.data.overrides."Grpc.AspNetCore.Server.ServerCallHandler" | string | `"Warning"` |  |
| config.log.data.overrides."Microsoft.AspNetCore.Authorization" | string | `"Warning"` |  |
| config.log.data.overrides."Microsoft.AspNetCore.Hosting.Diagnostics" | string | `"Warning"` |  |
| config.log.data.overrides."Microsoft.AspNetCore.Routing" | string | `"Warning"` |  |
| config.log.data.overrides."Microsoft.AspNetCore.Routing.EndpointMiddleware" | string | `"Warning"` |  |
| config.log.data.overrides."Microsoft.AspNetCore.Server.Kestrel" | string | `"Warning"` |  |
| config.log.data.overrides."Microsoft.Extensions.Diagnostics.HealthChecks" | string | `"Warning"` |  |
| config.log.data.overrides."Microsoft.Extensions.Http.DefaultHttpClientFactory" | string | `"Warning"` |  |
| config.log.data.overrides."Serilog.AspNetCore.RequestLoggingMiddleware" | string | `"Warning"` |  |
| config.log.name | string | `"log-configmap"` |  |
| envFrom.configMapRef[0] | string | `"control-plane-configmap"` |  |
| envFrom.configMapRef[1] | string | `"core-configmap"` |  |
| envFrom.configMapRef[2] | string | `"log-configmap"` |  |
| envFrom.secretRef[0] | string | `"redis"` |  |
| env[0].name | string | `"MongoDB__Password"` |  |
| env[0].valueFrom.secretKeyRef.key | string | `"mongodb-root-password"` |  |
| env[0].valueFrom.secretKeyRef.name | string | `"mongodb"` |  |
| env[1].name | string | `"Redis__Password"` |  |
| env[1].valueFrom.secretKeyRef.key | string | `"redis-password"` |  |
| env[1].valueFrom.secretKeyRef.name | string | `"redis"` |  |
| grafanaDashboard.enable | bool | `true` |  |
| image.name | string | `"armonik_control"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"dockerhubaneo"` |  |
| image.tag | string | `"0.31.2"` |  |
| imageCron.name | string | `"seqcli"` |  |
| imageCron.repository | string | `"datalust"` |  |
| imageCron.tag | string | `"2024.3"` |  |
| imageJob.name | string | `"mongosh"` |  |
| imageJob.repository | string | `"rtsp"` |  |
| imageJob.tag | string | `"2.3.8"` |  |
| livenessProbe.failureThreshold | int | `1` |  |
| livenessProbe.httpGet.path | string | `"/liveness"` |  |
| livenessProbe.httpGet.port | int | `1081` |  |
| livenessProbe.initialDelaySeconds | int | `15` |  |
| livenessProbe.periodSeconds | int | `5` |  |
| livenessProbe.successThreshold | int | `1` |  |
| livenessProbe.timeoutSeconds | int | `1` |  |
| metricsExporter.enable | bool | `true` |  |
| name | string | `"control-plane"` |  |
| namespace | string | `"armonik"` |  |
| nodeSelector | object | `{}` |  |
| partitionMetricsExporter.enable | bool | `false` |  |
| ports[0].containerPort | int | `1080` |  |
| ports[0].name | string | `"control-port"` |  |
| ports[0].protocol | string | `"TCP"` |  |
| ports[1].containerPort | int | `1081` |  |
| ports[1].name | string | `"metrics-port"` |  |
| ports[1].protocol | string | `"TCP"` |  |
| replicaCount | int | `1` |  |
| resources.limits.cpu | int | `1` |  |
| resources.limits.memory | string | `"1Gi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"128Mi"` |  |
| service.name | string | `"control-plane"` |  |
| service.ports[0].name | string | `"control-port"` |  |
| service.ports[0].port | int | `5001` |  |
| service.ports[0].targetPort | int | `1080` |  |
| service.selector.app | string | `"armonik"` |  |
| service.selector.service | string | `"control-plane"` |  |
| service.serviceType | string | `"ClusterIP"` |  |
| serviceAccount | string | `"armonikserviceaccount"` |  |
| startupProbe.failureThreshold | int | `20` |  |
| startupProbe.httpGet.path | string | `"/startup"` |  |
| startupProbe.httpGet.port | int | `1081` |  |
| startupProbe.initialDelaySeconds | int | `15` |  |
| startupProbe.periodSeconds | int | `3` |  |
| startupProbe.successThreshold | int | `1` |  |
| startupProbe.timeoutSeconds | int | `5` |  |
| tolerations | list | `[]` |  |
| volumes | string | `nil` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
