# Best practices 

This document presents some of the most known best practices in writing
Helm charts. Most of the best practices are described in the [Helm docs](https://helm.sh/docs/) page. Other resources are also used ([boxunix](https://boxunix.com/2022/02/05/developers-guide-to-writing-a-good-helm-chart/), [Bitnami docs](https://docs.bitnami.com/tutorials/production-ready-charts/), [Argonaut](https://www.argonaut.dev/blog/helm-best-practices)
[Codefresh](https://codefresh.io/docs/docs/ci-cd-guides/helm-best-practices/)
[Itnext](https://itnext.io/helm-3-umbrella-charts-standalone-chart-image-tags-an-alternative-approach-78a218d74e2d)).

This guide will be used by [Aneo](https://www.aneo.eu/) to write Helm charts for the [Armonik plateform](https://www.armonik.fr/).

## Coding standart

### Conventions and constraints [argonaut](https://www.argonaut.dev/blog/helm-best-practices)

Here are some common conventions and constraints when it comes to naming Helm components.

|Component | Convention / Constraint |
|----------|-------------------------|
|Chart names | Chart names must be lowercase alphanumeric with dashes (-) used to separate words. Uppercase letters, underscores, and dots are not allowed. |
|Version numbers | Helm prefers SemVer 2 for version numbers, except for Docker image tags. When storing SemVer versions in Kubernetes labels, replace the "+" character with "_" since  labels do not allow "+". |
|YAML indentation | YAML files should use two spaces for indentation, not tabs. |
|Helm terminology | "Helm" refers to the project as a whole, while "helm" refers to the client-side command. |
|Chart terminology | "chart" does not need to be capitalized, except for "Chart.yaml" file which is case sensitive. |
|Variables | Variable names should start with a lowercase letter and use camel case to separate words. |
|YAML structure | While YAML allows nested values, it is recommended to prefer a flat structure for simplicity and ease of use. |
|Sharing templates | Parent charts and subcharts can share templates. Any defined block in any chart is available to other charts. |
|Block vs. Include | In Helm charts, it is recommended to use "include" instead of "block" for overriding default implementations, as multiple implementations of the same block can result in unpredictable behavior. |
| manifests | Do not put multiple resources in one manifest file. [boxunix](https://boxunix.com/2022/02/05/developers-guide-to-writing-a-good-helm-chart/) |
| Naming resources | Avoid stutter when naming your resources. (ex: kind: pod, name: armonik-pod) [boxunix](https://boxunix.com/2022/02/05/developers-guide-to-writing-a-good-helm-chart/) |

Flat or Nested Values ?? 
In most cases, flat should be favored over nested. The reason for this is that it is simpler for template developers and users. For every layer of nesting, an existence check must be done. But for flat configuration, such checks can be skipped, making the template easier to read and use.

### Variables

A variable is a named reference to another object. 
It follows the form $name. Variables are assigned with a special assignment operator `:=`.

~~~
{{- $relname := .Release.Name -}}
release: {{ $relname }}
~~~

### Using labels
Labels serve as a convenient way to quickly identify resources created by Helm releases.
To define labels, a common approach is to use the _helpers.tpl file:

~~~
{{/*
Common labels
*/}}
{{- define "common.labels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
~~~

Subsequently, labels can be included in resource templates using the "include" function:

~~~
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-queue
  labels:
{{ include "common.labels" . | indent 4 }}
...
~~~

use app.kubernetes.io/*


### Documenting charts
- Comments
- README
- NOTES.txt

### Securing secrets

the helm-secrets plugin can be utilized.
This plugin leverages Mozilla SOPS, 
which supports encryption using various 
key management services like AWS KMS, 
Google Cloud KMS, Azure Key Vault, and PGP.

### Reusable charts using template functions
- default
- required
- ..

### Resource policies to opt out of resource deletion
By employing resource-policy annotations, 
you can carefully manage the lifecycle of your resources 
and ensure that important data is not inadvertently 
lost during the uninstallation process. (Quotation marks are required)

## Umbrella charts

### Subcharts
Each subchart in Helm has to be a standalone chart. And thus, a subchart cannot be dependent on its parent chart. However, a parent chart can override values of the subchart.
~~~
armonik/
  ├── Chart.yaml
  ├── values.yaml
  ├── charts/
  │   ├── control-plane/
  │   │   ├── Chart.yaml
  │   │   ├── values.yaml
  │   │   └── templates/
  │   │       ├── control-plane-deployment.yaml
  │   │       ├── control-plane-service.yaml
  │   │       └── ...
  │   └── compute-plane/
  │       ├── Chart.yaml
  │       ├── values.yaml
  │       └── templates/
  │           ├── compute-plane-deployment.yaml
  │           ├── compute-plane-service.yaml
  │           └── ...
  └── templates/
      ├── armonik-deployment.yaml
      ├── armonik-service.yaml
      └── ...
~~~

You can override the values of subcharts in the parent chart with the values.yaml file.

### Using global values
Global values in Helm refer to the values that can be accessed by all charts in your chart directory. 
These are defined in the values.yaml file as global: parameters.
The Values data type has a reserved section called Values.global 
where global values can be set. 

Example:
~~~ umbrella-chart/values.yaml 
global:
  foo: bar
~~~

By specifying the global variable, sub-charts can now 
reference the global value in the parent’s values.yaml file as follows.

~~~ umbrella-chart/charts/subchart/templates/deployment.yaml 
{{- if .Values.global.foo }} # use the global value if it is set, ( if we want to deploy the sub-chart alone: {{- if .Values.global }} )
  key1: {{ .Values.global.foo }} 
{{- else }} # else use local value
  key1: {{ .Values.foo }}
{{- end }}
~~~

## Library charts


## Versionning [codefresh](https://codefresh.io/docs/docs/ci-cd-guides/helm-best-practices/)

Each Helm chart has the ability to define two separate versions:
- version in Chart.yaml: The version of the chart itself.
- appVersion in Chart.yaml: The version of the application contained in the chart.
These are unrelated and can be bumped up in any manner. 
You can sync them together or have them increase independently. 
There is no right or wrong practice here as long as you stick into one. 
<!-- TODO: Define a strategy for version -->
1. Simple 1-1 versioning: keep the chart version in sync with your actual application (don't use appVersion)
2. Chart versus application versioning: individually version charts and application 
    - if changes are happening in the charts themselves all the time
    - must define a chart versionning strategy !
3. Umbrella charts: the same can applyed as the two above
    - the chart and the sub-charts have the same version
    - when exactly the parent chart version should be bumped. 
        - Is it only when a child chart changes? 
        - Only when an application changes? 
        - or both?


from: [itnext](https://itnext.io/helm-3-umbrella-charts-standalone-chart-image-tags-an-alternative-approach-78a218d74e2d)

When making use of umbrella charts to deploy a multi-component stack, 
particularly where the sub-components of the stack will rarely, 
if ever, be deployed standalone, it makes sense to migrate image 
tag versions to the umbrella chart and maintain these here.

=> use "global" in the umbrella chart to maintain sub-charts versions ! 

## Helm promotion strategies

- promotion between environments (testing, staging, production).

### Single repository with multiple environments
A single Helm chart (the same across environments). 
It is deployed to multiple targets using a different set of values.

### Chart promotion between environments
The recommended deployment workflow.

## chart repository
use ArtifactHub: https://artifacthub.io/packages/search?kind=0
use our own repo:

A chart repository is an HTTP server that houses an index.yaml file and optionally some packaged charts. A chart repository can be any HTTP server that can serve YAML and tar files and can answer GET requests.

~~~
charts/
  |- index.yaml
  |- alpine-0.1.2.tgz
  |- alpine-0.1.2.tgz.prov
~~~

We can use GitHub Pages [Helm docs](https://helm.sh/docs/topics/chart_repository/).

## Abbreviation

Use abbreviation in naming manifests:

| Abbreviation | Full name               |
| ------------ | ----------------------- |
| svc          | service                 |  
| deploy       | deployment              |
| cm           | configmap               |
| secret       | secret                  |
| ds           | daemonset               |
| rc           | replicationcontroller   |
| petset       | petset                  |
| po           | pod                     |
| hpa          | horizontalpodautoscaler |
| ing          | ingress                 |
| job          | job                     |
| limit        | limitrange              |
| ns           | namespace               |
| pv           | persistentvolume        |
| pvc          | persistentvolumeclaim   |
| sa           | serviceaccount          |


## Security [bitnami](https://docs.bitnami.com/tutorials/production-ready-charts/)

### Use non-root containers

~~~
spec:
    {{- if .Values.securityContext.enabled }}
        securityContext:
        fsGroup: {{ .Values.securityContext.fsGroup }}
    {{- end }}
    {{- if .Values.securityContext.enabled }}
        securityContext:
        runAsUser: {{ .Values.securityContext.runAsUser }}
    {{- end }}
~~~

 <!-- Pod Security Context -->
 <!-- ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ -->
<!--  -->
In values:
~~~
securityContext:
  enabled: true
  fsGroup: 1001
  runAsUser: 1001
~~~

### Do not persist the configuration
### Integrate charts with logging and monitoring tools

## Tests:


## Questions: 

In terraform (control-plane.tf): The service uses the deployement labels (app, service) !
is that means that the service created after the deployment is created ?
is it more sense to make a values (for app and service) that will be used by both deployment and service ?
 


## TODO:
- Use control-plane.labels of _helpers.tpl
    - add extraLabels

