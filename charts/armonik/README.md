# armonik

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.2.2](https://img.shields.io/badge/AppVersion-0.2.2-informational?style=flat-square)

A Helm chart for Armonik

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Aneo | <armonik-support@aneo.fr> | <armonik.fr> |

## Requirements

Kubernetes: `>=v1.23.0-0`

| Repository | Name | Version |
|------------|------|---------|
|  | compute-plane |  |
|  | control-plane |  |
|  | ingress |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| computePlane.enabled | bool | `false` |  |
| controlPlanConfigmapEnabled | bool | `false` |  |
| controlPlanConfigmap[0] | string | `"control-plane-configmap"` |  |
| controlPlanConfigmap[1] | string | `"log-configmap"` |  |
| controlPlanConfigmap[2] | string | `"core-configmap"` |  |
| controlPlane.enabled | bool | `true` |  |
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
| coreConfigmap.enabled | bool | `false` |  |
| coreConfigmap.metadata.name | string | `"core-configmap-helm"` |  |
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
| fullnameOverride | string | `""` |  |
| global.namespace | string | `"armonik"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"nginx"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| logConfigmap.data.loggingLevel | string | `"Information"` |  |
| logConfigmap.enabled | bool | `false` |  |
| logConfigmap.metadata.name | string | `"log-configmap-helm"` |  |
| logConfigmap.metadata.namespace | string | `"armonik"` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| partitionNames[0] | string | `"default"` |  |
| partitionNames[1] | string | `"monitoring"` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| replicaCount | int | `1` |  |
| securityContext | object | `{}` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |
| volumeMounts | list | `[]` |  |
| volumes | list | `[]` |  |

