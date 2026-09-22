# Shared cert-manager issuer

Four consumers can get their TLS material from cert-manager: `armonik-ingress` (server TLS and
the mTLS client CA), `dependencies.redis`, `dependencies.activemq`, and `dependencies.mongodb`.
Each resolves its `Certificate`'s `issuerRef` the same way, in order:

1. a local `existingIssuer` override
2. a local Issuer the consumer creates for itself, as soon as its own `certManager.provider` is
   set at all (even explicitly to `selfSigned`) - present in the values, regardless of its
   resolved value
3. a shared issuer controlled by two umbrella-only values (`global.armonik.certManager.issuer`,
   the issuer every consumer without a closer override falls back to, and `certManagerIssuer`,
   whether and how this release creates it)
4. failing all of the above, a local Issuer the consumer creates for itself anyway, defaulting to
   `provider: selfSigned` - the zero-configuration default

Tiers 2 and 4 create the exact same kind of object (a local Issuer backed by
`certManager.provider`); the only difference is whether the shared issuer (tier 3) is skipped on
the way there. See [Mixing](#mixing-some-consumers-on-the-global-issuer-others-on-their-own-local-fallback)
for why that distinction matters.

## Issuer resolution modes

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

Each consumer creates its **own** local Issuer — ingress, redis, activemq and mongodb end up with
four independent Issuer objects, not one shared root (mongodb's is one object shared by both its
Certificates, never one per Certificate, see [MongoDB](#mongodb)). `provider` defaults to
`selfSigned`, same as always; set it per consumer for a different backend:

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

The value lives under each consumer's own `certManager` block, sibling to `existingIssuer`:
`dependencies.redis.tls.certManager`, `dependencies.activemq.tls.certManager` (`tls.certManager`
when activemq is installed standalone), `ingress.tls.certManager` (`tls.certManager` standalone),
`dependencies.mongodb.certManager`. Unlike `certManagerIssuer`, which is umbrella-only, this is a
value every one of these charts carries on its own, so it also works when a consumer is installed
as its own release.

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

Every consumer's `Certificate` then points its `issuerRef.name` at the same Issuer, as long as that
consumer has no `existingIssuer` AND no `certManager.provider` of its own set (tiers 1 and 2 above).
`provider` and the per-provider blocks under `certManagerIssuer` are umbrella-only: they exist only
to let this release create the Issuer named by `global.armonik.certManager.issuer`; a consumer
never reads them directly.

### Mixing: some consumers on the global issuer, others on their own local fallback

Setting a consumer's own `certManager.provider` (tier 2) keeps it on its own local fallback even
while the global issuer is enabled release-wide - no real pre-existing `existingIssuer` object
needed, unlike the `existingIssuer` override, which requires one already in the cluster. A consumer
left without its own `provider` set falls through to the global issuer instead, once one is
enabled:

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
        # no provider set -> uses the global issuer above

  mongodb:
    certManager:
      enabled: true
      provider: vault   # present at all -> keeps its own local fallback; mongodb still rejects selfSigned
      vault:
        server: https://vault.example.com:8200
        path: pki_int/sign/mongodb
        auth:
          kubernetes:
            role: mongodb-cert-manager
```

Confirmed by rendering: redis's `Certificate` references the shared issuer
(`<release>-shared-issuer`); mongodb creates and references its own local Issuer instead, unaffected
by the global issuer being enabled. Setting `provider` only matters when the global issuer is
actually enabled - with it disabled, every consumer without an `existingIssuer` already falls to
its own local fallback regardless, whether or not `provider` was set (tiers 2 and 4 collapse into
the same outcome). `existingIssuer` still wins over a locally-set `provider` if both are set on the
same consumer. The [namespace guard](../armonik/templates/certmanager-issuer-guard.yaml) skips a
consumer with its own `provider` set too: its local Issuer is always created in its own namespace,
so the namespace-mismatch check that guard exists for does not apply to it.

One consequence worth calling out explicitly: to keep a consumer on the *default* local provider
(`selfSigned`) while a global issuer is also enabled release-wide, `provider: selfSigned` has to be
written out - an absent `provider` key looks identical to "nothing configured" and falls through to
the global issuer once one exists.

A cluster-scoped issuer (`global.armonik.certManager.issuer.kind: ClusterIssuer` or
`GoogleCASClusterIssuer`) exempts every consumer from the namespace guard regardless of
`namespaceOverride`, since a ClusterIssuer is not namespace-bound to begin with. Use this to avoid
namespace friction entirely when every consumer should share one root.

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
into the created Issuer's spec. This section uses `certManagerIssuer` throughout since it is the
umbrella's own shared-issuer knob, but a consumer's own local-fallback `certManager.provider`
(above) takes the exact same values and the exact same per-provider block shapes - only the values
path differs.

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

**A selfSigned issuer always fails at render time for MongoDB, by design** - whether it is the
global shared issuer or MongoDB's own local fallback:

```
dependencies.mongodb.certManager.enabled cannot use a selfSigned shared issuer: replica
set members must chain to a common CA. Use certManagerIssuer.provider=ca, vault, acme,
venafi or googleCas, or point dependencies.mongodb.certManager.existingIssuer at an
issuer backed by a real CA.
```

```
dependencies.mongodb.certManager.enabled cannot use a local selfSigned fallback issuer:
replica set members must chain to a common CA, and cert-manager's selfSigned issuer type
has no persistent signing key, so ssl and ssl-internal would each get an independently
self-signed root that does not trust the other. Set dependencies.mongodb.certManager.provider
to ca, vault, acme, venafi or googleCas, point dependencies.mongodb.certManager.existingIssuer
at an issuer backed by a real CA, or set global.armonik.certManager.issuer.enabled=true with
certManagerIssuer.provider set to a real CA.
```

Replica set members validate each other's certificates, and a `selfSigned` issuer produces no
common root — every certificate it signs is independently self-issued, even two certificates that
happen to reference the exact same `selfSigned` Issuer object (that issuer type has no persistent
signing key at all). Use `ca`, `vault`, `acme`, `venafi` or `googleCas` for MongoDB, wherever the
issuer comes from.

Five supported configurations, all verified against a live replica set or by rendering:

**a) `tls.certManagementPolicy: auto`** (the psmdb operator's own default): the operator
provisions its own independent CA via its own Issuer/Certificate pair, entirely separate from
`global.armonik.certManager.issuer`. Right choice when a shared root across components does not
matter, only working TLS does. With no `dependencies.mongodb.certManager` block at all,
`mongodb-certificate.yaml` renders nothing; the operator creates and manages its own
`<cluster-name>-psmdb-ca-issuer`/`<cluster-name>-ca-cert` pair entirely on its own.

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

**d) `tls.certManagementPolicy: userProvidedOnly`, local fallback** - neither `existingIssuer` nor
the global shared issuer configured, so this chart creates its own local Issuer for MongoDB, backed
by `dependencies.mongodb.certManager.provider`. Unlike the other three consumers, this local Issuer
is resolved **once** and shared by both Certificates below it (never one throwaway Issuer per
Certificate), and `provider: selfSigned` - the default everywhere else - is rejected here for the
reason above:

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
      users: <release-name>-mongodb-secrets
      ssl: armonik-mongodb-ssl
      sslInternal: armonik-mongodb-ssl-internal
```

Confirmed by rendering: both Certificates' `issuerRef.name` resolve to the same local Issuer
(`<cluster-name>-issuer`), rendered exactly once regardless of how many Certificates reference it.

**e) The psmdb operator's own native cert-manager integration**, via `tls.issuerConf`. This is a
genuinely different mechanism from (b)/(c)/(d), not a variant of them: instead of this chart
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

Expect an extra, unused `<cluster-name>-psmdb-ca-issuer`/`-ca-cert` pair alongside this: the
operator still runs its own auto-CA logic from (a) regardless of `issuerConf`, it is just never
referenced - the two Certificates that actually matter
(`<cluster-name>-ssl`/`-ssl-internal`) reference `tls.issuerConf.name` instead. Not a sign that
`issuerConf` failed to take effect.

Per the [Percona cert-manager docs](https://docs.percona.com/percona-operator-for-mongodb/1.23.0/tls-cert-manager.html),
the operator creates exactly two `Certificate` objects regardless of replica set size:
`<cluster-name>-ssl` and `<cluster-name>-ssl-internal`, shared across every member.
This matches the shape of configurations (b), (c) and (d) above. Pointing `issuerConf` at an
external issuer does not change this behavior: the operator still requests the same two
certificates from the same named issuer, never one certificate per member.

`selfSigned` therefore fails here for the same reason it fails in (b), (c) and (d): a
`selfSigned` Issuer gives each certificate its own independent root, regardless of
whether this chart or the operator requested it.

This configuration requires no `dependencies.mongodb.certManager.*`, `secrets.ssl`, or
`secrets.sslInternal` keys. The operator names and manages both Secrets end to end
(`secrets.users` remains required either way, unrelated to TLS). Prefer this option
over (b)/(c)/(d) to keep certificate issuance inside the operator's own reconciliation
loop. Prefer (b)/(c)/(d) to centralize issuance in this chart's own templates alongside
redis, activemq, and ingress.
