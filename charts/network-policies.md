# Network Policies

Every ArmoniK chart ships `NetworkPolicy` support, off by default (`networkPolicy.enabled: false`).
The umbrella's switch, each dependency's and each operator's are independent: opt in layer by layer.
The one exception is the Bitnami RabbitMQ chart, whose own `networkPolicy.enabled` defaults to
`true` (RabbitMQ itself is disabled by default).

## Inventory

| Component | Rendered by | Default egress | Default ingress |
|---|---|---|---|
| control-plane submitter + init | umbrella `armonik/templates/networkpolicies/control-plane.yaml` | MongoDB or PostgreSQL, RabbitMQ/ActiveMQ, Redis, DNS | nginx (control-port) only, see below |
| control-plane submitter (chart-local) | `armonik-control-plane` | DNS | Prometheus |
| control-plane metrics-exporter | umbrella + `armonik-control-plane` | MongoDB or PostgreSQL, DNS | KEDA (umbrella), Prometheus (chart-local) |
| compute-plane | umbrella `.../compute-plane.yaml` + `armonik-compute-plane` | MongoDB or PostgreSQL, RabbitMQ/ActiveMQ, Redis, DNS | Prometheus |
| nginx (ingress) | `armonik-ingress` + umbrella `.../nginx-egress.yaml` | DNS, GUI (both); control-plane, Grafana, Seq (umbrella only) | any source, 8080/9080 |
| GUI | `armonik-ingress` | DNS | nginx |
| gateway/httpRoute health check | `armonik-ingress`, with `gateway` or `httpRoute` enabled | - | `networkPolicy.healthCheckRules` |
| MongoDB operator | umbrella `.../mongodb.yaml` | MongoDB server, DNS, kube-api | MongoDB server |
| MongoDB server | umbrella `.../mongodb.yaml` | operator, replset peers, DNS | operator, replset peers, control-plane/init, metrics-exporter, compute-plane, mongodb-exporter |
| mongodb-exporter | umbrella `.../mongodb-exporter.yaml` | MongoDB, DNS | Prometheus |
| PostgreSQL (CloudNativePG Cluster) | umbrella `.../postgresql.yaml` | Cluster peers, DNS, kube-api | control-plane/init, metrics-exporter, compute-plane, Cluster peers, CloudNativePG operator, Prometheus |
| CloudNativePG operator | none, see [PostgreSQL](#postgresql-cloudnativepg) | - | - |
| Redis/valkey | umbrella `.../redis.yaml` | - | control-plane/init, compute-plane |
| ActiveMQ | umbrella `.../activemq.yaml` + `activemq/templates/network-policy.yaml` | DNS (chart-local) | control-plane/init, compute-plane (umbrella) |
| fluent-bit | umbrella `.../fluent-bit-egress.yaml` | DNS, kube-api, Seq | - |
| KEDA operator | umbrella `.../keda-metrics-egress.yaml` | control-plane metrics-exporter, DNS, kube-api | - |

The submitter admits nginx alone: under mTLS it trusts the identity headers nginx sets. Do not open
it to another pod, least of all the compute-plane, whose workers run user code.

The umbrella owns the policies of MongoDB, PostgreSQL, Redis/valkey and mongodb-exporter outright, their charts
shipping none. The other dependencies (ActiveMQ, RabbitMQ, Grafana, Seq, fluent-bit) also have
their own, toggled by `dependencies.<name>.networkPolicy.enabled`.

## Enabling it

| Release | Flag |
|---|---|
| umbrella (`armonik`) | `networkPolicy.enabled=true` |
| control-plane, compute-plane or ingress, standalone | `networkPolicy.enabled=true` |
| a dependency (activemq, rabbitmq, grafana, seq, fluent-bit) | `dependencies.<name>.networkPolicy.enabled=true` |
| an operator (keda, external-secrets, cert-manager, kube-prometheus's prometheus/prometheusOperator) | that chart's own flag under `operators.<name>` |

PostgreSQL, Redis/valkey and mongodb-exporter follow the umbrella's `networkPolicy.enabled`. That switch does
not cascade to dependency or operator charts, on purpose, so a default-deny baseline can be matched
incrementally. The umbrella policies selecting another chart's pods (nginx, KEDA, fluent-bit) still
grant the DNS and API egress those pods need, since selecting them isolates their egress whatever
that chart's own switch.

## PostgreSQL (CloudNativePG)

With `dependencies.postgresql.enabled`, the umbrella renders `<fullname>-postgresql-server` over every
pod of the Cluster (`cnpg.io/cluster: <cluster>`): the instances, and the initdb/join Jobs the
operator runs. The ArmoniK pods reach the instances only (`cnpg.io/podRole: instance`), whichever is
primary, so a switchover needs no change.

| Peer | Direction | Port | Purpose |
|---|---|---|---|
| control-plane/init, metrics-exporter, compute-plane | ingress | 5432 | queries; the control plane's task and result watchers also read the WAL over this port |
| other pods of the Cluster | ingress, egress | 5432 | streaming replication and `pg_basebackup` once `cluster.instances > 1` |
| CloudNativePG operator | ingress | 8000 | the instance manager's status API: health, switchover, fencing |
| Prometheus | ingress | 9187 | the Cluster's PodMonitor |
| Kubernetes API, DNS | egress | 443/6443, 53 | the instance manager reads its Cluster and writes its status |

CloudNativePG fixes 8000 and 9187, and the kubelet probes the status port from the node, which the
usual CNIs admit without a rule.

**The operator is found through `global.armonik.operators.postgresqlOperator.namespace`**, not
through the operator subchart, which a layered install does not render. The default resolves to
the release namespace when this release deploys the operator; a layered install must state it, or
the render fails. Its pods are matched by `app.kubernetes.io/name: cloudnative-pg`, which
`networkPolicy.postgresqlOperatorPodSelector` overrides.

**The operator gets no policy of its own**, unlike the MongoDB operator:

- its admission webhooks are called by the API server, which runs on the host network: a
  `NetworkPolicy` cannot select it portably (on Cilium, an `ipBlock` does not match node
  addresses), so restricting the operator's ingress would block every `Cluster` change;
- it is installed once per cluster and may manage Clusters that are not ArmoniK's, which an egress
  policy rendered by one ArmoniK release would cut off.

Admitting the operator on the instances' side keeps the data path closed all the same.

Not covered, add them with `networkPolicy.extraPolicies`:

- egress to an object store, for Barman backups or WAL archiving;
- `Pooler` (PgBouncer) pods, if `cluster.poolers` is set: the ArmoniK pods do not reach them.

The worker shares its pod's network namespace with the polling agent, so it can open a connection
to PostgreSQL, though without the agent's credentials. MongoDB has the same limitation: a
`NetworkPolicy` selects pods, not containers.

## Standalone installs

The umbrella's rules select control-plane and compute-plane pods by **label**, in the umbrella's
namespace. A standalone plane release in that namespace is covered with no extra configuration. In
another namespace, both sides need rules written by hand:

- egress from the plane: its `extraEgressRules` (below);
- ingress into the backends (MongoDB or PostgreSQL, Redis, ActiveMQ), which only admit the umbrella's namespace:
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

With PostgreSQL, the peer is `cnpg.io/cluster: <cluster>` plus `cnpg.io/podRole: instance`, on
5432. Repeat per backend (RabbitMQ/ActiveMQ, Redis) with its namespace, label and port; see
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
