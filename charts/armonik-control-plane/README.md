# armonik-control-plane

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
| affinity | object | `{}` |  |
| annotations | object | `{}` |  |
| conf.env | object | `{}` |  |
| conf.envConfigmap | list | `[]` |  |
| conf.envFromConfigmap | object | `{}` |  |
| conf.envFromSecret | object | `{}` |  |
| conf.envSecret | list | `[]` |  |
| conf.mountConfigmap | object | `{}` |  |
| conf.mountSecret | object | `{}` |  |
| defaultPartition | string | `"default"` |  |
| extraPartitions | list | `[]` |  |
| image.name | string | `"armonik_control"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `nil` |  |
| image.repository | string | `"dockerhubaneo"` |  |
| image.tag | string | `nil` |  |
| imagePullSecrets | list | `[]` |  |
| init.affinity | string | `nil` |  |
| init.annotations | string | `nil` |  |
| init.conf | string | `nil` |  |
| init.enabled | bool | `true` |  |
| init.image.name | string | `nil` |  |
| init.image.pullPolicy | string | `nil` |  |
| init.image.registry | string | `nil` |  |
| init.image.repository | string | `nil` |  |
| init.image.tag | string | `nil` |  |
| init.imagePullSecrets | string | `nil` |  |
| init.name | string | `"init"` |  |
| init.nodeSelector | string | `nil` |  |
| init.resources | string | `nil` |  |
| init.tolerations | string | `nil` |  |
| livenessProbe.failureThreshold | int | `1` |  |
| livenessProbe.httpGet.path | string | `"/liveness"` |  |
| livenessProbe.httpGet.port | int | `1081` |  |
| livenessProbe.initialDelaySeconds | int | `15` |  |
| livenessProbe.periodSeconds | int | `5` |  |
| livenessProbe.successThreshold | int | `1` |  |
| livenessProbe.timeoutSeconds | int | `1` |  |
| maxErrorAllowed | int | `50` |  |
| metricsExporter.affinity | string | `nil` |  |
| metricsExporter.annotations | string | `nil` |  |
| metricsExporter.conf | string | `nil` |  |
| metricsExporter.enabled | bool | `true` |  |
| metricsExporter.image.name | string | `"armonik_control_metrics"` |  |
| metricsExporter.image.pullPolicy | string | `nil` |  |
| metricsExporter.image.registry | string | `nil` |  |
| metricsExporter.image.repository | string | `nil` |  |
| metricsExporter.image.tag | string | `nil` |  |
| metricsExporter.imagePullSecrets | string | `nil` |  |
| metricsExporter.livenessProbe.failureThreshold | int | `1` |  |
| metricsExporter.livenessProbe.httpGet.path | string | `"/liveness"` |  |
| metricsExporter.livenessProbe.httpGet.port | int | `1080` |  |
| metricsExporter.livenessProbe.initialDelaySeconds | int | `15` |  |
| metricsExporter.livenessProbe.periodSeconds | int | `5` |  |
| metricsExporter.livenessProbe.successThreshold | int | `1` |  |
| metricsExporter.livenessProbe.timeoutSeconds | int | `1` |  |
| metricsExporter.name | string | `"metrics-exporter"` |  |
| metricsExporter.nodeSelector | string | `nil` |  |
| metricsExporter.ports[0].containerPort | int | `1080` |  |
| metricsExporter.ports[0].name | string | `"metrics-port"` |  |
| metricsExporter.ports[0].protocol | string | `"TCP"` |  |
| metricsExporter.replicas | int | `1` |  |
| metricsExporter.resources | string | `nil` |  |
| metricsExporter.service.annotations | string | `nil` |  |
| metricsExporter.service.name | string | `"metrics-exporter"` |  |
| metricsExporter.service.ports[0].name | string | `"metrics-port"` |  |
| metricsExporter.service.ports[0].port | int | `9419` |  |
| metricsExporter.service.ports[0].targetPort | int | `1080` |  |
| metricsExporter.service.serviceType | string | `"ClusterIP"` |  |
| metricsExporter.startupProbe.failureThreshold | int | `20` |  |
| metricsExporter.startupProbe.httpGet.path | string | `"/startup"` |  |
| metricsExporter.startupProbe.httpGet.port | int | `1080` |  |
| metricsExporter.startupProbe.initialDelaySeconds | int | `15` |  |
| metricsExporter.startupProbe.periodSeconds | int | `3` |  |
| metricsExporter.startupProbe.successThreshold | int | `1` |  |
| metricsExporter.startupProbe.timeoutSeconds | int | `5` |  |
| metricsExporter.tolerations | string | `nil` |  |
| name | string | `"control-plane"` |  |
| nodeSelector | object | `{}` |  |
| ports[0].containerPort | int | `1080` |  |
| ports[0].name | string | `"control-port"` |  |
| ports[0].protocol | string | `"TCP"` |  |
| ports[1].containerPort | int | `1081` |  |
| ports[1].name | string | `"metrics-port"` |  |
| ports[1].protocol | string | `"TCP"` |  |
| replicas | int | `1` |  |
| resources.limits.cpu | int | `1` |  |
| resources.limits.memory | string | `"1Gi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"128Mi"` |  |
| service.annotations | string | `nil` |  |
| service.name | string | `"control-plane"` |  |
| service.ports[0].name | string | `"control-port"` |  |
| service.ports[0].port | int | `5001` |  |
| service.ports[0].targetPort | int | `1080` |  |
| service.serviceType | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `"control-plane"` |  |
| serviceAccount.secrets | list | `[]` |  |
| startupProbe.failureThreshold | int | `20` |  |
| startupProbe.httpGet.path | string | `"/startup"` |  |
| startupProbe.httpGet.port | int | `1081` |  |
| startupProbe.initialDelaySeconds | int | `15` |  |
| startupProbe.periodSeconds | int | `3` |  |
| startupProbe.successThreshold | int | `1` |  |
| startupProbe.timeoutSeconds | int | `5` |  |
| tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
