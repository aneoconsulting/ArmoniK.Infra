# Shared cert-manager issuer

Four consumers can get TLS material from cert-manager: `armonik-ingress` (server TLS and the mTLS
client CA), `dependencies.redis`, `dependencies.activemq` and `dependencies.mongodb`. Each resolves
its `Certificate`'s `issuerRef` in this order:

1. its own `existingIssuer`;
2. a local Issuer it creates itself, when its own `certManager.provider` key is present (any value,
   `selfSigned` included);
3. the shared issuer, `global.armonik.certManager.issuer` (umbrella-only: `certManagerIssuer` says
   whether and how this release creates it);
4. otherwise a local Issuer it creates itself anyway, `provider: selfSigned` by default.

Tiers 2 and 4 create the same object, a local Issuer backed by `certManager.provider`. They differ
only in whether tier 3 is skipped, see [Mixing](#mixing-shared-and-local-issuers).

## Issuer resolution modes

### Local fallback (default)

Only TLS and cert-manager need enabling on the consumer:

```yaml
dependencies:
  redis:
    tls:
      enabled: true
      existingSecret: redis-tls
      certManager:
        enabled: true
```

Each consumer creates its **own** Issuer: four independent Issuers, no shared root (mongodb's one
Issuer serves both its Certificates, see [MongoDB](#mongodb)). `provider` defaults to `selfSigned`;
set it per consumer for another backend:

```yaml
dependencies:
  redis:
    tls:
      enabled: true
      existingSecret: redis-tls
      certManager:
        enabled: true
        provider: vault   # or ca / acme / venafi / googleCas; never selfSigned for mongodb
        vault:
          server: https://vault.example.com:8200
          path: pki_int/sign/redis
          auth:
            kubernetes:
              role: redis-cert-manager
```

The block lives in each consumer's own `certManager`, next to `existingIssuer`:

| Consumer | Under the umbrella | Standalone |
|---|---|---|
| redis | `dependencies.redis.tls.certManager` | - |
| activemq | `dependencies.activemq.tls.certManager` | `tls.certManager` |
| ingress | `ingress.tls.certManager` | `tls.certManager` |
| mongodb | `dependencies.mongodb.certManager` | - |

Unlike `certManagerIssuer`, these are chart values of each consumer, so they also work when the
consumer is its own release.

### Global shared issuer

```yaml
global:
  armonik:
    certManager:
      issuer:
        enabled: true

certManagerIssuer:
  create: true
  provider: selfSigned   # or ca / vault / acme / venafi / googleCas, see below
```

Every consumer without its own `existingIssuer` or `certManager.provider` (tiers 1 and 2) then
points `issuerRef.name` at this Issuer, `<release>-shared-issuer` by default
(`global.armonik.certManager.issuer.name`). `certManagerIssuer` only drives the creation of that
Issuer; consumers never read it.

### Mixing shared and local issuers

A consumer that sets its own `certManager.provider` keeps its local Issuer while the shared issuer is
enabled, with no pre-existing Issuer needed (unlike `existingIssuer`). A consumer without
`provider` uses the shared issuer:

```yaml
global:
  armonik:
    certManager:
      issuer:
        enabled: true

certManagerIssuer:
  create: true
  provider: selfSigned

dependencies:
  redis:
    tls:
      enabled: true
      existingSecret: redis-tls
      certManager:
        enabled: true
        # no provider -> the shared issuer

  mongodb:
    certManager:
      enabled: true
      provider: vault   # present -> its own local Issuer; never selfSigned for mongodb
      vault:
        server: https://vault.example.com:8200
        path: pki_int/sign/mongodb
        auth:
          kubernetes:
            role: mongodb-cert-manager
```

- redis references `<release>-shared-issuer`; mongodb creates and references its own Issuer.
- `provider` only matters while the shared issuer is enabled. Without it, every consumer lacking an
  `existingIssuer` gets its local Issuer anyway (tiers 2 and 4 coincide).
- To keep a consumer on a local `selfSigned` Issuer while the shared issuer is enabled, write
  `provider: selfSigned` explicitly: an absent key falls through to the shared issuer.
- `existingIssuer` still wins over `provider`.
- The namespace guard (`armonik/templates/certmanager-issuer-guard.yaml`) fails the render when a
  consumer of the shared namespaced Issuer (when `certManagerIssuer.create=true`) renders its
  Certificate in another namespace. It skips consumers with their own `provider` (their Issuer is
  created in their own namespace) or `existingIssuer`.
- A cluster-scoped shared issuer (`global.armonik.certManager.issuer.kind: ClusterIssuer` or
  `GoogleCASClusterIssuer`) is exempt from that guard, whatever the `namespaceOverride`s.

### existingIssuer (per consumer)

```yaml
dependencies:
  redis:
    tls:
      enabled: true
      existingSecret: redis-tls
      certManager:
        enabled: true
        existingIssuer:
          enabled: true
          name: my-manual-issuer
          kind: Issuer
          group: cert-manager.io
```

Nothing is created: the Issuer must already exist. The chart cannot check it at render time. If it
is missing, the `Certificate` stays `READY: False` and its `CertificateRequest` reports
`Referenced "Issuer" not found`.

## Providers

`certManagerIssuer.provider` selects which block under `certManagerIssuer` is forwarded, as is, into
the created Issuer's spec. A consumer's own `certManager.provider` takes the same values and block
shapes; only the values path differs.

### selfSigned, ca, vault, acme, venafi

The cert-manager.io native issuer types: the matching block becomes `Issuer.spec.<provider>`
unchanged. See the [cert-manager docs](https://cert-manager.io/docs/configuration/) for their
fields. For [Venafi](https://cert-manager.io/docs/configuration/venafi/), `caBundle` must already be
base64-encoded; the chart does not encode it.

```yaml
certManagerIssuer:
  create: true
  provider: venafi
  venafi:
    zone: "My Application\\My CIT"
    cloud:
      apiTokenSecretRef:
        name: venafi-token
```

`selfSigned` takes no fields (`certManagerIssuer.selfSigned: {}`, the default). Every certificate it
signs is its own root, so the served certificate always looks self-issued, whichever Issuer signed
it. Check routing on the `Certificate`'s `spec.issuerRef.name`, not on the TLS handshake.

### googleCas

A separate CRD group, `cas-issuer.jetstack.io`, from the
[Google CAS Issuer](https://github.com/cert-manager/google-cas-issuer). The `googleCas` block is the
`spec` of the resulting `GoogleCASIssuer` / `GoogleCASClusterIssuer` (`project`, `location`,
`caPoolId`, `certificateAuthorityId`, `credentials`). The Google CAS Issuer operator is off by
default: install it with `global.armonik.operators.googleCasIssuer.deploy=true`, or from another
release.

```yaml
global:
  armonik:
    certManager:
      issuer:
        enabled: true
        kind: GoogleCASIssuer
        group: cas-issuer.jetstack.io

certManagerIssuer:
  create: true
  provider: googleCas
  googleCas:
    project: gcp-project
    location: region-gcp
    caPoolId: ca-pool
    credentials:
      name: cas-credentials
      key: credentials.json

operators:
  cert-manager:
    approveSignerNames:
      - "issuers.cert-manager.io/*"
      - "clusterissuers.cert-manager.io/*"
      - "googlecasissuers.cas-issuer.jetstack.io/*"
      - "googlecasclusterissuers.cas-issuer.jetstack.io/*"
```

**`approveSignerNames` replaces the cert-manager chart's default, it does not extend it.** The
default covers only `issuers.cert-manager.io/*` and `clusterissuers.cert-manager.io/*`, so list
those too. When this release installs cert-manager, the render fails unless both `googlecas*`
entries are present.

## MongoDB

`dependencies.mongodb.tls` and `dependencies.mongodb.secrets` pass straight into the
`PerconaServerMongoDB` CR; see the
[psmdb-db README](https://github.com/percona/percona-helm-charts/blob/psmdb-db-1.23.3/charts/psmdb-db/README.md)
for their fields. ArmoniK's own trigger keys live in the sibling `dependencies.mongodb.certManager`.

**A `selfSigned` issuer is rejected at render time for MongoDB**, shared or local. Replica set
members must chain to a common CA, and a `selfSigned` issuer has no persistent signing key: every
certificate it signs is its own root, even two certificates from the same Issuer object. Use `ca`,
`vault`, `acme`, `venafi` or `googleCas`, whichever tier the issuer comes from.

The render cannot see what backs an `existingIssuer`: pointing it at a `selfSigned` Issuer brings the
same problem back unchecked.

Five supported configurations:

**a) `tls.certManagementPolicy: auto`** (the psmdb operator's default). The operator provisions its
own CA (`<cluster-name>-psmdb-ca-issuer` / `<cluster-name>-ca-cert`), independent of
`global.armonik.certManager.issuer`. Choose it when TLS matters but a shared root does not. Without a
`dependencies.mongodb.certManager` block, `mongodb-certificate.yaml` renders nothing.

**b) `tls.certManagementPolicy: userProvidedOnly`**, the chart requesting both Certificates from the
shared issuer:

```yaml
dependencies:
  mongodb:
    enabled: true
    certManager:
      enabled: true
      existingSecret: armonik-mongodb-ssl
      existingSecretInternal: armonik-mongodb-ssl-internal
    tls:
      allowInvalidCertificates: true
      certManagementPolicy: userProvidedOnly
    secrets:
      users: <cluster-name>-secrets   # exactly this name, see below
      ssl: armonik-mongodb-ssl
      sslInternal: armonik-mongodb-ssl-internal
```

`secrets.users` must be set, to `<cluster-name>-secrets`, whenever you set any `secrets` key:
psmdb-db fills it in only when the whole `secrets` block is empty. `<cluster-name>` is the psmdb-db
fullname: `<release>-mongodb` by default, truncated to 21 characters, and changed by
`dependencies.mongodb.nameOverride` / `fullnameOverride`. Omitted, the operator falls back to `percona-server-mongodb-users`
instead of the Secret the umbrella's conf `ExternalSecret` reads, and the failure surfaces on an
unrelated resource.

**c) `userProvidedOnly` with an `existingIssuer`**, as for the other consumers:

```yaml
dependencies:
  mongodb:
    enabled: true
    certManager:
      enabled: true
      existingIssuer:
        enabled: true
        name: existing-issuer
        kind: Issuer
        group: cert-manager.io
      existingSecret: armonik-mongodb-ssl
      existingSecretInternal: armonik-mongodb-ssl-internal
    tls:
      mode: preferTLS
      allowInvalidCertificates: true
      certManagementPolicy: userProvidedOnly
    secrets:
      users: <cluster-name>-secrets
      ssl: armonik-mongodb-ssl
      sslInternal: armonik-mongodb-ssl-internal
```

Both Certificates reference `existing-issuer`.

**d) `userProvidedOnly` with a local Issuer**: no `existingIssuer`, no shared issuer. The chart
creates one Issuer for MongoDB, `<cluster-name>-issuer`, backed by
`dependencies.mongodb.certManager.provider` and shared by both Certificates. `selfSigned`, the
default elsewhere, is rejected:

```yaml
dependencies:
  mongodb:
    enabled: true
    certManager:
      enabled: true
      provider: ca   # or vault / acme / venafi / googleCas; selfSigned fails
      ca:
        secretName: my-ca-key-pair
      existingSecret: armonik-mongodb-ssl
      existingSecretInternal: armonik-mongodb-ssl-internal
    tls:
      allowInvalidCertificates: true
      certManagementPolicy: userProvidedOnly
    secrets:
      users: <cluster-name>-secrets
      ssl: armonik-mongodb-ssl
      sslInternal: armonik-mongodb-ssl-internal
```

**e) The operator's native cert-manager integration**, `tls.issuerConf`. A different mechanism from
(b) to (d): the operator requests and manages its own Certificates against the named issuer.
`mongodb-certificate.yaml` is not involved; leave `dependencies.mongodb.certManager.enabled` unset.

```yaml
dependencies:
  mongodb:
    enabled: true
    tls:
      issuerConf:
        name: armonik-shared-issuer
        kind: GoogleCASIssuer
        group: cas-issuer.jetstack.io
    secrets:
      users: <cluster-name>-secrets
```

- `tls` reaches the CR's `spec.tls.issuerConf` verbatim; `certManagementPolicy` need not be set.
- The operator still creates its unused auto-CA pair from (a). The two Certificates that matter,
  `<cluster-name>-ssl` and `<cluster-name>-ssl-internal`, reference `tls.issuerConf.name`.
- The operator creates exactly those two Certificates, shared by every member, whatever the replica
  set size ([Percona docs](https://docs.percona.com/percona-operator-for-mongodb/1.23.0/tls-cert-manager.html)).
  `selfSigned` therefore fails here as in (b) to (d).
- No `dependencies.mongodb.certManager.*`, `secrets.ssl` or `secrets.sslInternal` needed: the
  operator names and manages both Secrets.

Prefer (e) to keep issuance in the operator's reconciliation loop, (b) to (d) to issue from the
charts alongside redis, activemq and ingress.
