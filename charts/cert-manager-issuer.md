# Shared cert-manager issuer

Four consumers can get their TLS material from cert-manager: `armonik-ingress` (server TLS and
the mTLS client CA), `dependencies.redis`, `dependencies.activemq`, and `dependencies.mongodb`.
Each resolves its `Certificate`'s `issuerRef` the same way, controlled by two umbrella-only
values: `global.armonik.certManager.issuer` (the issuer every consumer falls back to) and
`certManagerIssuer` (whether and how this release creates that issuer).

## Issuer resolution modes

Precedence, per consumer: a local `existingIssuer` override, else the global shared issuer, else
(all consumers except MongoDB) a throwaway local `selfSigned` Issuer.

### Local fallback (default)

No issuer configuration needed beyond enabling TLS and cert-manager on the consumer itself:

```yaml
dependencies:
  redis:
    tls:
      enabled: true
      existingSecret: redis-tls
      certManager:
        enabled: true
```

Each consumer creates its **own** throwaway `selfSigned` Issuer — ingress, redis and activemq end
up with three independent Issuer objects, not one shared root. MongoDB has no local fallback: it
fails at render time if neither `existingIssuer` nor the global issuer is configured (see
[MongoDB](#mongodb)).

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

Every consumer's `Certificate` then points its `issuerRef.name` at the same Issuer. `provider` and
the per-provider blocks under `certManagerIssuer` are umbrella-only: they exist only to let this
release create the Issuer named by `global.armonik.certManager.issuer`; a consumer never reads
them directly.

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

This does **not** create anything — the Issuer must already exist in the cluster. If it doesn't,
the `Certificate` sits at `READY: False` forever with no error anywhere (cert-manager itself never
surfaces a "no such issuer" condition on the request). This is expected behavior, not a bug in the
chart.

## Providers

`certManagerIssuer.provider` selects which block under `certManagerIssuer` is forwarded, as-is,
into the created Issuer's spec.

### selfSigned, ca, vault, acme, venafi

These are the cert-manager.io native `IssuerConfig` fields: the matching block becomes
`Issuer.spec.<provider>` unchanged. See the [cert-manager configuration
docs](https://cert-manager.io/docs/configuration/) for the fields each one takes; for Venafi
specifically, see the [CyberArk/Venafi issuer
docs](https://cert-manager.io/docs/configuration/venafi/) — note `caBundle` must already be
base64-encoded, the chart does not encode it for you.

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

`selfSigned` needs no fields (`certManagerIssuer.selfSigned: {}` is valid and is the default). Each
Certificate it signs is its own root — checking the served certificate's issuer/subject fields
will always look self-issued, correctly-routed or not; the only reliable check is the
`Certificate` object's own `spec.issuerRef.name`, not what the live TLS handshake shows.

### googleCas

A separate CRD group (`cas-issuer.jetstack.io`, from the [Google CAS
Issuer](https://github.com/cert-manager/google-cas-issuer) project), not a cert-manager.io native
provider. The `googleCas` block IS the resulting `GoogleCASIssuer`/`GoogleCASClusterIssuer`'s
`spec` directly (`project`, `location`, `caPoolId`, `certificateAuthorityId`, `credentials`).

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



**`approveSignerNames` REPLACES the cert-manager chart's default, it does not extend it.** The
   default only covers `issuers.cert-manager.io/*` and `clusterissuers.cert-manager.io/*`; without
   the two `googlecas*` entries.


## MongoDB

`dependencies.mongodb.tls`/`.secrets` pass straight into the PerconaServerMongoDB CR see the [psmdb-db
README](https://github.com/percona/percona-helm-charts/blob/psmdb-db-1.23.2/charts/psmdb-db/README.md)
for the authoritative field list. This chart only forwards a subset and adds its own trigger keys
under the sibling `dependencies.mongodb.certManager`.

**A selfSigned shared issuer always fails at render time for MongoDB, by design:**

```
dependencies.mongodb.certManager.enabled cannot use a selfSigned shared issuer: replica
set members must chain to a common CA. Use certManagerIssuer.provider=ca, vault, acme,
venafi or googleCas, or point dependencies.mongodb.certManager.existingIssuer at an
issuer backed by a real CA.
```

Replica set members validate each other's certificates, and a `selfSigned` issuer produces no
common root — every certificate it signs is independently self-issued. Use `ca`, `vault`, `acme`,
`venafi` or `googleCas` for MongoDB.

Four supported configurations, all verified against a live replica set or by rendering:

**a) `tls.certManagementPolicy: auto`** (the psmdb operator's own default): the operator
provisions its own independent CA via its own Issuer/Certificate pair, entirely separate from
`global.armonik.certManager.issuer`. Right choice when a shared root across components does not
matter, only working TLS does.

**b) `tls.certManagementPolicy: userProvidedOnly`**, with this chart's `mongodb-certificate.yaml`
requesting the two Certificates against the shared issuer instead:

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
      users: <release-name>-mongodb-secrets  # must match <your-release-name>-mongodb-secrets exactly - not a free-form name
      ssl: armonik-mongodb-ssl
      sslInternal: armonik-mongodb-ssl-internal
```

`secrets.users` is required whenever `certManager.enabled` is true, and must equal
`<release-name>-mongodb-secrets` (derived from the psmdb-db subchart's own fullname, so a
`dependencies.mongodb.nameOverride`/`fullnameOverride` changes it) — not a free-form name. Setting
it to anything else, or dropping it, makes the operator fall back to its own default secret name
instead of the one the umbrella's conf `ExternalSecret` expects, and the failure surfaces on an
unrelated resource.

**c) `tls.certManagementPolicy: userProvidedOnly`, existingIssuer** instead of the global shared
issuer — supported the same way as the other three consumers:

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
      users: <release-name>-mongodb-secrets
      ssl: armonik-mongodb-ssl
      sslInternal: armonik-mongodb-ssl-internal
```

Confirmed by rendering `certificate/mongodb-certificate.yaml`: both Certificates' `issuerRef.name`
resolve to `existing-issuer`. As with any `existingIssuer`, this chart cannot check what backs it —
pointing it at a `selfSigned` Issuer silently reintroduces the same no-common-CA problem the guard
above exists to catch (see [existingIssuer](#existingissuer-per-consumer)).

**d) The psmdb operator's own native cert-manager integration**, via `tls.issuerConf`. This is a
genuinely different mechanism from (b)/(c), not a variant of them: instead of this chart
requesting Certificates and handing them to the operator
(`certManagementPolicy: userProvidedOnly`), the operator requests and manages its own Certificates
internally against the named issuer. This chart's `mongodb-certificate.yaml` is not involved at
all — `dependencies.mongodb.certManager.enabled` stays unset/false.

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
      users: <release-name>-mongodb-secrets
```

Confirmed wired end to end by rendering: `dependencies.mongodb.tls` passes straight through to the
psmdb-db subchart's own values, and the resulting `PerconaServerMongoDB` CR's `spec.tls.issuerConf`
matches this verbatim. `certManagementPolicy` does not need to be set for `issuerConf` to take
effect.

Per the [Percona cert-manager docs](https://docs.percona.com/percona-operator-for-mongodb/1.23.0/tls-cert-manager.html),
the operator creates exactly two `Certificate` objects regardless of replica set size:
`<cluster-name>-ssl` and `<cluster-name>-ssl-internal`, shared across every member.
This matches the shape of configurations (b) and (c) above. Pointing `issuerConf` at an
external issuer does not change this behavior: the operator still requests the same two
certificates from the same named issuer, never one certificate per member.

`selfSigned` therefore fails here for the same reason it fails in (b) and (c): a
`selfSigned` Issuer gives each certificate its own independent root, regardless of
whether this chart or the operator requested it.

This configuration requires no `dependencies.mongodb.certManager.*`, `secrets.ssl`, or
`secrets.sslInternal` keys. The operator names and manages both Secrets end to end
(`secrets.users` remains required either way, unrelated to TLS). Prefer this option
over (b)/(c) to keep certificate issuance inside the operator's own reconciliation
loop. Prefer (b)/(c) to centralize issuance in this chart's own templates alongside
redis, activemq, and ingress.
