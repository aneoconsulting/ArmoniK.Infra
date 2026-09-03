# Network Policies

Every chart ships `NetworkPolicy` support, off by default (`networkPolicy.enabled: false`
everywhere). Nothing changes in the cluster until you opt in, layer by layer: the umbrella's own
switch, each dependency's own switch, and each install-once operator's own switch are all
independent.

## Inventory

| Component | Rendered by | Default egress | Default ingress |
|---|---|---|---|
| control-plane submitter + init | umbrella `armonik/templates/networkpolicies/control-plane.yaml` | MongoDB, RabbitMQ/ActiveMQ, Redis, DNS | compute-plane, ingress (control-port) |
| control-plane submitter (chart-local) | `armonik-control-plane` | DNS | Prometheus |
| control-plane metrics-exporter | umbrella + `armonik-control-plane` | MongoDB, DNS | KEDA, Prometheus |
| compute-plane | umbrella `.../compute-plane.yaml` + `armonik-compute-plane` | MongoDB, RabbitMQ/ActiveMQ, Redis, DNS | Prometheus |
| nginx (ingress) | `armonik-ingress` + umbrella `.../nginx-egress.yaml` | DNS, GUI, control-plane/grafana/seq (umbrella only) | external 8080/9080 |
| GUI | `armonik-ingress` | DNS | nginx |
| MongoDB operator | umbrella `.../mongodb.yaml` | MongoDB server, cert-manager, DNS, kube-api | MongoDB server |
| MongoDB server | umbrella `.../mongodb.yaml` | operator, DNS | operator, control-plane, compute-plane |
| Redis/valkey | umbrella `.../redis.yaml` | - | control-plane, compute-plane |
| ActiveMQ | `activemq/templates/network-policy.yaml` | DNS | control-plane/init, compute-plane |
| fluent-bit | umbrella `.../fluent-bit-egress.yaml` | DNS, kube-api, Seq | - |
| wait-cert-manager Job | umbrella `.../wait-cert-manager-egress.yaml` | DNS, kube-api | - |
| KEDA operator | umbrella `.../keda-metrics-egress.yaml` | control-plane metrics-exporter | - |

MongoDB and Redis/valkey are the only two dependencies whose upstream chart ships no
`NetworkPolicy` of its own; the umbrella owns both outright. Every other dependency (ActiveMQ,
RabbitMQ, Grafana, Seq, fluent-bit) defines its own, toggled by its own
`dependencies.<name>.networkPolicy.enabled`.

## Enabling it

| Release | Flag |
|---|---|
| umbrella (`armonik`) | `networkPolicy.enabled=true` |
| control-plane, standalone | `networkPolicy.enabled=true` |
| compute-plane, standalone | `networkPolicy.enabled=true` |
| ingress, standalone | `networkPolicy.enabled=true` |
| a dependency (activemq, grafana, seq, fluent-bit) | `dependencies.<name>.networkPolicy.enabled=true` |
| an operator (keda, external-secrets, cert-manager, kube-prometheus's prometheus/prometheusOperator) | that chart's own flag under `operators.<name>` |

Redis is covered by the umbrella's own `networkPolicy.enabled` and has no separate flag. Turning on
the umbrella's switch does not cascade to dependency or operator charts - each is independent, on
purpose, so a cluster-wide default-deny baseline can be matched incrementally.

## Standalone installs

control-plane and compute-plane admit each other (and are admitted by MongoDB/Redis) by **label**,
not by Helm ownership, so a standalone release needs no extra configuration as long as it shares a
namespace with the umbrella release. A different namespace needs the missing egress written by
hand.

| Deployed as | Same namespace as the umbrella | Different namespace |
|---|---|---|
| control-plane / compute-plane, standalone | covered automatically | add `networkPolicy.{submitter,metricsExporter}.extraEgressRules` (control-plane) or `networkPolicy.extraEgressRules` (compute-plane) |
| ingress, standalone | **not** covered (its egress rule only resolves via `.Subcharts`, which a standalone release doesn't have) | same: add `networkPolicy.nginx.extraEgressRules` |

### Example: standalone compute-plane

```sh
helm install my-compute-plane ./charts/armonik-compute-plane \
  -n <namespace> \
  --set conf.source=<umbrella-release> \
  --set networkPolicy.enabled=true \
```

If `<namespace>` is the umbrella release's own namespace (and the umbrella also has
`networkPolicy.enabled=true`), this is already enough: MongoDB/RabbitMQ/ActiveMQ/Redis all admit
this pod by label. In a different namespace, add the missing egress yourself, e.g. for MongoDB:

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

Repeat per backend (RabbitMQ/ActiveMQ, Redis) with that backend's own namespace, label and port -
see `armonik-compute-plane/values.yaml` for the full set. The same pattern applies to a standalone
control-plane (`networkPolicy.submitter.extraEgressRules`) and a standalone ingress
(`networkPolicy.nginx.extraEgressRules`, targeting control-plane/grafana/seq instead).

### Example: standalone control-plane

```sh
helm install my-control-plane ./charts/armonik-control-plane \
  -n <namespace> \
  --set conf.source=<umbrella-release> \
  --set networkPolicy.enabled=true
```

The table above covers control-plane's own egress and its ingress from compute-plane, both
label-based. Nginx reaching a standalone control-plane is a separate rule that always breaks: it's
derived only in the umbrella's `nginx-egress.yaml` via `.Subcharts["control-plane"]`, absent
whenever `control-plane.enabled: false`, so the rule silently renders empty - no error. Control-plane
still admits nginx (its ingress rule only needs `.Subcharts.ingress`); nginx just never gets
permission to send. Symptom: `connect() failed (111: Connection refused)` / 502 on every gRPC call,
while Grafana/Seq keep working.

Fix, on the release that renders `ingress` - port is the pod's container port, not the Service port:

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

## Escape hatches

- `networkPolicy.extraIngressRules` / `extraEgressRules` on each plane/dependency chart append to
  its own built-in rules.
- `networkPolicy.extraPolicies` on the umbrella renders whole extra `NetworkPolicy` resources,
  independent of every rule above - for anything not covered by the wiring in this document (a
  monitoring scraper in another namespace, a custom sidecar).
