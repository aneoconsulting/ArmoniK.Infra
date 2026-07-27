# armonik-ingress

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.14.5](https://img.shields.io/badge/AppVersion-0.14.5-informational?style=flat-square)

A Helm chart for Ingress

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Aneo | <armonik@aneo.fr> | <armonik.fr> |

## Requirements

Kubernetes: `>=v1.25.0-0`

| Repository | Name | Version |
|------------|------|---------|
| file://../armonik-common | armonik-common | 0.1.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| annotations | object | `{}` |  |
| clusterDomain | string | `""` |  |
| gateway.allowedRoutes.namespaces.from | string | `"Same"` |  |
| gateway.enabled | bool | `false` |  |
| gateway.tls.enabled | bool | `false` |  |
| global.armonik.operators.certManager.available | bool | `true` |  |
| global.armonik.operators.certManager.deploy | bool | `false` |  |
| global.armonik.operators.externalSecrets.available | bool | `true` |  |
| global.armonik.operators.externalSecrets.deploy | bool | `false` |  |
| global.armonik.operators.keda.available | bool | `true` |  |
| global.armonik.operators.keda.deploy | bool | `false` |  |
| global.armonik.operators.mongodbOperator.available | bool | `true` |  |
| global.armonik.operators.mongodbOperator.deploy | bool | `false` |  |
| global.armonik.operators.prometheusOperator.available | bool | `true` |  |
| global.armonik.operators.prometheusOperator.deploy | bool | `false` |  |
| gui.affinity | object | `{}` |  |
| gui.annotations | object | `{}` |  |
| gui.image.name | string | `"armonik_admin_app"` |  |
| gui.image.pullPolicy | string | `"IfNotPresent"` |  |
| gui.image.registry | string | `nil` |  |
| gui.image.repository | string | `"dockerhubaneo"` |  |
| gui.image.tag | string | `nil` |  |
| gui.nodeSelector | object | `{}` |  |
| gui.ports[0].containerPort | int | `1080` |  |
| gui.ports[0].name | string | `"gui"` |  |
| gui.ports[0].servicePort | int | `1080` |  |
| gui.resources.limits.cpu | string | `"100m"` |  |
| gui.resources.limits.memory | string | `"128Mi"` |  |
| gui.resources.requests.cpu | string | `"100m"` |  |
| gui.resources.requests.memory | string | `"128Mi"` |  |
| gui.service.annotations | string | `nil` |  |
| gui.service.type | string | `"ClusterIP"` |  |
| gui.tolerations | list | `[]` |  |
| healthCheckPolicy.enabled | bool | `false` |  |
| httpRoute.enabled | bool | `false` |  |
| image.name | string | `"nginx-unprivileged"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `nil` |  |
| image.repository | string | `"nginxinc"` |  |
| image.tag | string | `"1.27.4-alpine-slim"` |  |
| imagePullSecrets | list | `[]` |  |
| loadBalancer.annotations | object | `{}` |  |
| loadBalancer.clusters | object | `{}` |  |
| loadBalancer.conf.listenPort | int | `8081` |  |
| loadBalancer.defaultCluster | string | `""` |  |
| loadBalancer.enabled | bool | `false` |  |
| loadBalancer.extraEnv | list | `[]` |  |
| loadBalancer.extraEnvFrom | list | `[]` |  |
| loadBalancer.image.name | string | `"armonik_load_balancer"` |  |
| loadBalancer.image.pullPolicy | string | `"IfNotPresent"` |  |
| loadBalancer.image.registry | string | `nil` |  |
| loadBalancer.image.repository | string | `"dockerhubaneo"` |  |
| loadBalancer.image.tag | string | `"0.3.1"` |  |
| loadBalancer.nodeSelector | object | `{}` |  |
| loadBalancer.replicas | int | `1` |  |
| loadBalancer.resources | object | `{}` |  |
| loadBalancer.service.annotations | object | `{}` |  |
| loadBalancer.service.port | int | `8080` |  |
| loadBalancer.service.type | string | `"HeadLess"` |  |
| loadBalancer.tolerations | list | `[]` |  |
| mtls.certificationAuthority.pem | string | `""` |  |
| mtls.enabled | bool | `false` |  |
| mtls.trustedCommonNames | list | `[]` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| ports[0].http2 | bool | `true` |  |
| ports[0].name | string | `"ingress-grpc"` |  |
| ports[0].protocol | string | `"grpc"` |  |
| ports[0].servicePort | int | `5001` |  |
| ports[1].name | string | `"ingress-http"` |  |
| ports[1].protocol | string | `"http"` |  |
| ports[1].servicePort | int | `5000` |  |
| replicas | int | `1` |  |
| resources.limits.cpu | int | `1` |  |
| resources.limits.memory | string | `"1Gi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"128Mi"` |  |
| service.annotations | object | `{}` |  |
| service.type | string | `"LoadBalancer"` |  |
| static."environment.json".color | string | `"#80ff80"` |  |
| static."environment.json".description | string | `"{{ .Values.global.environment.description }}"` |  |
| static."environment.json".name | string | `"{{ .Values.global.environment.name }}"` |  |
| static."environment.json".version | string | `"{{ .Chart.AppVersion }}"` |  |
| static.guiConfiguration | object | `{}` |  |
| tls.certManager.addInjectorAnnotations | bool | `true` |  |
| tls.certManager.annotations | object | `{}` |  |
| tls.certManager.duration | string | `""` |  |
| tls.certManager.enabled | bool | `true` |  |
| tls.certManager.existingIssuer.enabled | bool | `false` |  |
| tls.certManager.existingIssuer.kind | string | `"Issuer"` |  |
| tls.certManager.existingIssuer.name | string | `"my-issuer"` |  |
| tls.certManager.labels | object | `{}` |  |
| tls.certManager.renewBefore | string | `""` |  |
| tls.customCert.certPem | string | `""` |  |
| tls.customCert.keyPem | string | `""` |  |
| tls.enabled | bool | `false` |  |
| tls.ssl.certificatePath | string | `"/ingress/tls.crt"` |  |
| tls.ssl.cipherSuites | string | `"TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256"` |  |
| tls.ssl.ciphers | string | `"EECDH+AESGCM:EECDH+AES256"` |  |
| tls.ssl.keyPath | string | `"/ingress/tls.key"` |  |
| tls.ssl.protocols | string | `"TLSv1.2 TLSv1.3"` |  |
| tolerations | list | `[]` |  |
| volumes.mongodbSecret | string | `"mongodb"` |  |
| volumes.nginxConfigMap | string | `"armonik-ingress-conf"` |  |
| volumes.nginxStaticConfigMap | string | `"armonik-ingress-static"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
