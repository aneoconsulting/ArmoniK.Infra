# Network Policies

Every ArmoniK chart ships `NetworkPolicy` support, off by default (`networkPolicy.enabled: false`).
The umbrella's switch, each dependency's and each operator's are independent: opt in layer by layer.
The one exception is the Bitnami RabbitMQ chart, whose own `networkPolicy.enabled` defaults to
`true` (RabbitMQ itself is disabled by default).

## Inventory

| Component | Rendered by | Default egress | Default ingress |
|---|---|---|---|
| control-plane submitter + init | umbrella `armonik/templates/networkpolicies/control-plane.yaml` | MongoDB, RabbitMQ/ActiveMQ, Redis, DNS | compute-plane, nginx (control-port) |
| control-plane submitter (chart-local) | `armonik-control-plane` | DNS | Prometheus |
| control-plane metrics-exporter | umbrella + `armonik-control-plane` | MongoDB, DNS | KEDA (umbrella), Prometheus (chart-local) |
| compute-plane | umbrella `.../compute-plane.yaml` + `armonik-compute-plane` | MongoDB, RabbitMQ/ActiveMQ, Redis, DNS | Prometheus |
| nginx (ingress) | `armonik-ingress` + umbrella `.../nginx-egress.yaml` | DNS, GUI; control-plane, Grafana, Seq (umbrella only) | any source, 8080/9080 |
| GUI | `armonik-ingress` | DNS | nginx |
| gateway/httpRoute health check | `armonik-ingress`, with `gateway` or `httpRoute` enabled | - | `networkPolicy.healthCheckRules` |
| MongoDB operator | umbrella `.../mongodb.yaml` | MongoDB server, DNS, kube-api | MongoDB server |
| MongoDB server | umbrella `.../mongodb.yaml` | operator, replset peers, DNS | operator, replset peers, control-plane/init, metrics-exporter, compute-plane, mongodb-exporter |
| mongodb-exporter | umbrella `.../mongodb-exporter.yaml` | MongoDB, DNS | Prometheus |
| Redis/valkey | umbrella `.../redis.yaml` | - | control-plane/init, compute-plane |
| ActiveMQ | umbrella `.../activemq.yaml` + `activemq/templates/network-policy.yaml` | DNS (chart-local) | control-plane/init, compute-plane (umbrella) |
| fluent-bit | umbrella `.../fluent-bit-egress.yaml` | DNS, kube-api, Seq | - |
| KEDA operator | umbrella `.../keda-metrics-egress.yaml` | control-plane metrics-exporter | - |

The umbrella owns the policies of MongoDB, Redis/valkey and mongodb-exporter outright, their charts
shipping none. The other dependencies (ActiveMQ, RabbitMQ, Grafana, Seq, fluent-bit) also have
their own, toggled by `dependencies.<name>.networkPolicy.enabled`.

## Enabling it

| Release | Flag |
|---|---|
| umbrella (`armonik`) | `networkPolicy.enabled=true` |
| control-plane, compute-plane or ingress, standalone | `networkPolicy.enabled=true` |
| a dependency (activemq, rabbitmq, grafana, seq, fluent-bit) | `dependencies.<name>.networkPolicy.enabled=true` |
| an operator (keda, external-secrets, cert-manager, kube-prometheus's prometheus/prometheusOperator) | that chart's own flag under `operators.<name>` |

Redis/valkey and mongodb-exporter follow the umbrella's `networkPolicy.enabled`. That switch does
not cascade to dependency or operator charts, on purpose, so a default-deny baseline can be matched
incrementally.

## Standalone installs

The umbrella's rules select control-plane and compute-plane pods by **label**, in the umbrella's
namespace. A standalone plane release in that namespace is covered with no extra configuration. In
another namespace, both sides need rules written by hand:

- egress from the plane: its `extraEgressRules` (below);
- ingress into the backends (MongoDB, Redis, ActiveMQ), which only admit the umbrella's namespace:
  the umbrella's `networkPolicy.extraPolicies`.

| Deployed as | Same namespace as the umbrella | Different namespace |
|---|---|---|
| control-plane / compute-plane, standalone | covered | `networkPolicy.{submitter,metricsExporter}.extraEgressRules` (control-plane) or `networkPolicy.extraEgressRules` (compute-plane), plus the backends' ingress |
| ingress, standalone | **not** covered: its egress to control-plane, Grafana and Seq resolves through `.Subcharts`, which a standalone release lacks | `networkPolicy.nginx.extraEgressRules` |

### Example: standalone compute-plane

```sh
helm install my-compute-plane ./charts/armonik-compute-plane \
  -n <namespace> \
  --set conf.source=<umbrella-release> \
  --set networkPolicy.enabled=true
```

In the umbrella's namespace (with the umbrella's `networkPolicy.enabled=true`), that is enough. In
another namespace, add the egress, for instance to MongoDB:

```yaml
networkPolicy:
  enabled: true
  extraEgressRules:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: <mongodb-namespace>
          podSelector:
            matchLabels:
              app.kubernetes.io/name: percona-server-mongodb
      ports:
        - protocol: TCP
          port: 27017
```

Repeat per backend (RabbitMQ/ActiveMQ, Redis) with its namespace, label and port; see
`armonik-compute-plane/values.yaml`. A standalone control-plane uses
`networkPolicy.submitter.extraEgressRules` the same way, and a standalone ingress
`networkPolicy.nginx.extraEgressRules`, towards control-plane, Grafana and Seq.

### Example: standalone control-plane

```sh
helm install my-control-plane ./charts/armonik-control-plane \
  -n <namespace> \
  --set conf.source=<umbrella-release> \
  --set networkPolicy.enabled=true
```

Nginx to control-plane breaks silently in this layout. The umbrella derives that egress in
`nginx-egress.yaml` from `.Subcharts["control-plane"]`, which is absent with
`control-plane.enabled: false`, so the rule renders empty with no error. Symptom:
`connect() failed (111: Connection refused)` or 502 on every gRPC call, while Grafana and Seq keep
working.

Fix it on the release that renders `ingress`. The port is the pod's container port, not the
Service port:

```yaml
control-plane:
  enabled: false

ingress:
  networkPolicy:
    enabled: true
    nginx:
      extraEgressRules:
        - to:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: <control-plane-namespace>
              podSelector:
                matchLabels:
                  app.kubernetes.io/component: control-plane
          ports:
            - protocol: TCP
              port: <control-plane's control-port container port, 1080 by default>
```

The control-plane side admits nginx through the umbrella's submitter policy, in the umbrella's
namespace only. In another namespace, also admit nginx (and compute-plane) with
`networkPolicy.submitter.extraIngressRules` on the control-plane release.

## Escape hatches

- `networkPolicy.extraIngressRules` / `extraEgressRules` on each plane or dependency chart append to
  its built-in rules.
- `networkPolicy.extraPolicies` on the umbrella renders whole extra `NetworkPolicy` resources
  (with the umbrella's `networkPolicy.enabled=true`), independent of the rules above: a scraper in another namespace, a custom sidecar, a backend's
  ingress from another namespace.
