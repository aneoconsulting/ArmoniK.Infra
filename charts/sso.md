# Single sign-on (OIDC)

`armonik-ingress` can put the web port behind an OIDC identity provider: an oauth2-proxy sidecar
in the nginx pod, consulted by nginx `auth_request`. It is off by default (`sso.enabled: false`),
and with it off the chart renders exactly as without these values.

The two ingress ports split by audience:

| Port | Service | Container | Serves | Authentication with SSO |
|---|---|---|---|---|
| web | 5000 | 8080, 8443 with TLS | admin GUI, gRPC-web, Grafana, Seq | OIDC session cookie |
| grpc | 5001 | 9080, 9443 with TLS | gRPC API only | client certificate (mTLS), unchanged |

SDK and CLI clients use the grpc port and keep authenticating with certificates; browsers use the
web port and authenticate with the IdP.

## Architecture

```
 browser                     nginx pod
 -------                     ------------------------------------------------------------
   |   GET /admin/  ------>  | web server (8080/8443)                                     |
   |                         |   auth_request /oauth2/auth  --->  oauth2-proxy           |
   |                         |                                    127.0.0.1:4180         |
   |   <-- 302 to the IdP    |   401: page   -> /oauth2/start --->   |  (sidecar)        |
   |                         |   401: gRPC-web -> grpc-status 16      |                    |
   |                         |   403: gRPC-web -> grpc-status 7       |                    |
   |   /oauth2/callback ---> |   /oauth2/*   ----------------------> |  ---> IdP (443)    |
   |                         |                                                            |
   |   gRPC-web + cookie --> |   CN <- session claim or group, fingerprint <- fixed     |
   |                         |   impersonation headers cleared                            |
   |                         |   grpc_pass  -------------------------------> control plane
   |                         |                                                            |
 SDK / CLI                   | grpc server (9080/9443)                                    |
   |   gRPC + client cert -> |   ssl_verify_client on, CN and fingerprint from the cert   |
   |                         |   grpc_pass  -------------------------------> control plane
                             ------------------------------------------------------------
```

ArmoniK Core needs no change: it still authenticates on the `X-Certificate-Client-CN` and
`X-Certificate-Client-Fingerprint` headers (`identityHeaders`, whose names the umbrella passes to
the control plane), which nginx now fills from the SSO session on the web port. nginx sets them on every request, so a client never chooses its identity.

- **Pages** (GUI, Grafana, Seq, `/static/`) without a session: nginx hands the request to
  `/oauth2/start`, which answers a 302 to the IdP. The original URI travels in
  `X-Auth-Request-Redirect` rather than in `rd`, nginx having no URL encoding.
- **gRPC-web** without a session: HTTP 200 with `grpc-status: 16` (UNAUTHENTICATED) and an empty
  body, a trailers-only response the gRPC-web client reports as an error instead of following a
  redirect.
- **Authenticated but refused** (oauth2-proxy answers 403, for instance `allowedGroups` or
  `emailDomains`): a page gets a plain 403, never a redirect, so no login loop; a gRPC-web call
  gets HTTP 200 with `grpc-status: 7` (PERMISSION_DENIED), trailers-only like the 401 case.
- **Unauthenticated routes**: `sso.healthPath` (default `/healthz`, 200 for load balancer health
  checks) and `/oauth2/*`.

## Canonical host

A login must start on the host the IdP returns to: oauth2-proxy sets its CSRF cookie on the host
the browser used, and the callback goes to `publicUrl`. Opened on another name or on an IP, the
callback finds no CSRF cookie and the login fails. So, before `auth_request`, the web port answers
any request whose host differs from `publicUrl`'s with a 302 to `<publicUrl><request URI>`, gRPC-web
calls included.

- The host is compared without its port and case-insensitively. A request on the right host but
  another port (a `kubectl port-forward`, a NodePort) is not redirected: cookies ignore the port, so
  the login works and lands on the `publicUrl` port after the callback. That port must be reachable.
- Exempt, answered on any host: `sso.healthPath`, and the oauth2-proxy `/oauth2/ping` and
  `/oauth2/ready`; the kubelet sends the sidecar readiness probe to the latter with the pod IP as
  host.

oauth2-proxy also names each CSRF cookie after its login attempt (`cookieCsrfPerRequest`), so
parallel requests without a session, a page and its favicon for instance, each start a login
without overwriting each other's cookie. Each expires after `cookieCsrfExpire`.

## Identity

ArmoniK Core requires both headers non-empty, and nginx always sends `sso.fingerprint` (default
`sso`) with an SSO identity. So SSO identities are declared in `rbac.userCertificates` with their
`commonName` and `fingerprint: <sso.fingerprint>`. A client certificate always presents its real
fingerprint on the grpc port, never `sso`, so it cannot match an SSO entry, even when the CA signed
a `sso:...` CN. An entry without a fingerprint would match any fingerprint for its CN, such a
certificate included: with SSO on, the umbrella refuses any `userCertificates` entry whose
`commonName` starts with `cnPrefix` or `groupCnPrefix` (case-insensitive) unless its `fingerprint`
is `sso.fingerprint`, and the ingress refuses an `sso.fingerprint` that looks like a certificate
fingerprint. The prefixes keep SSO identities apart from certificate CNs, so the ingress refuses an
empty `cnPrefix`, and an empty `groupCnPrefix` in group mode; an empty `groupCnPrefix` in user mode
is ignored by the umbrella check.

- `identityMode: user`: CN is `<cnPrefix><identityClaim>`, by default `sso:<email>`. A session
  without that claim gets an empty CN, which Core rejects.
- `identityMode: group`: CN is `<groupCnPrefix><cn>` for the first `groupMapping` entry whose group
  the user is in (whole group names, case-sensitive). A user in none of them gets an empty CN.
  The ArmoniK user is then the group, not the person.

`X-Impersonate-*` are always cleared on the web port.

## Values

| Value | Default | Notes |
|---|---|---|
| `sso.enabled` | `false` | A boolean: a string such as `"false"` fails the render |
| `sso.publicUrl` | `""` | Required. `scheme://host[:port]`, no path. Redirect URI `<publicUrl>/oauth2/callback`; `https` makes the cookie Secure |
| `sso.identityMode` | `user` | `user` or `group` |
| `sso.identityClaim` | `email` | `email`, `preferred_username` or `user` (the `sub` claim, oauth2-proxy's user) |
| `sso.cnPrefix` | `sso:` | Non-empty |
| `sso.fingerprint` | `sso` | Non-empty, not 32 or more hex digits. Every SSO `userCertificates` entry carries it |
| `sso.groupCnPrefix` | `sso-group:` | group mode, non-empty there |
| `sso.groupMapping` | `[]` | group mode, ordered `{group, cn}` |
| `sso.healthPath` | `/healthz` | |
| `sso.oauth2Proxy.image` | `quay.io/oauth2-proxy/oauth2-proxy:v7.15.5` | Exact tag, v7.15.2 or later |
| `sso.oauth2Proxy.issuerUrl` | `""` | Required |
| `sso.oauth2Proxy.clientId` | `""` | Required |
| `sso.oauth2Proxy.existingSecret` | `""` | Required. Keys `client-secret`, `cookie-secret` |
| `sso.oauth2Proxy.externalSecret` | none | `storeName`, `storeKind`, `clientSecret`/`cookieSecret` `{key, property}`: ESO builds `existingSecret` |
| `sso.oauth2Proxy.scopes` | `openid email profile` | |
| `sso.oauth2Proxy.groupsClaim` | `groups` | |
| `sso.oauth2Proxy.allowedGroups` | `[]` | Empty: any authenticated user |
| `sso.oauth2Proxy.emailDomains` | `["*"]` | |
| `sso.oauth2Proxy.cookieExpire` | `8h` | Session lifetime |
| `sso.oauth2Proxy.cookieRefresh` | `0` | Disabled; must stay 0 with `sessionCookieMinimal` |
| `sso.oauth2Proxy.sessionCookieMinimal` | `true` | Identity only in the cookie, no OAuth tokens |
| `sso.oauth2Proxy.cookieCsrfPerRequest` | `true` | One CSRF cookie per login attempt |
| `sso.oauth2Proxy.cookieCsrfExpire` | `15m` | CSRF cookie lifetime |
| `sso.oauth2Proxy.extraArgs` | `[]` | `--ping-user-agent` and `--gcp-healthchecks` are refused |
| `sso.oauth2Proxy.resources`, `securityContext` | `{}` | securityContext defaults to the chart's, read-only root filesystem |
| `sso.networkPolicy.idpEgressCidrs` | `[]` | Required once a NetworkPolicy selects the nginx pod |

Every value is validated at render time and a bad one fails with its key in the message.

## Example: user mode

```yaml
ingress:
  tls:
    enabled: true
  mtls:
    enabled: true
  sso:
    enabled: true
    publicUrl: https://armonik.example.com
    oauth2Proxy:
      issuerUrl: https://accounts.google.com
      clientId: 1234-abcd.apps.googleusercontent.com
      existingSecret: armonik-oauth2-proxy
      emailDomains: [example.com]
control-plane:
  rbac:
    authentication:
      required: true
    authorization:
      required: true
    users:
      alice: [Submitter]
      bob: [Monitoring]
    userCertificates:
      alice:
        commonName: "sso:alice@example.com"
        fingerprint: sso
      bob:
        commonName: "sso:bob@example.com"
        fingerprint: sso
```

## Example: group mode

```yaml
ingress:
  sso:
    enabled: true
    publicUrl: https://armonik.example.com
    identityMode: group
    groupMapping:
      - group: armonik-admins
        cn: admins
      - group: armonik-users
        cn: users
    oauth2Proxy:
      issuerUrl: https://keycloak.example.com/realms/armonik
      clientId: armonik
      existingSecret: armonik-oauth2-proxy
      allowedGroups: [armonik-admins, armonik-users]
control-plane:
  rbac:
    authentication:
      required: true
    authorization:
      required: true
    users:
      sso-admins: [Submitter]
      sso-users: [Monitoring]
    userCertificates:
      sso-admins:
        commonName: "sso-group:admins"
        fingerprint: sso
      sso-users:
        commonName: "sso-group:users"
        fingerprint: sso
```

## The Secret

The cookie secret must be 16, 24 or 32 bytes:

```sh
kubectl -n armonik create secret generic armonik-oauth2-proxy \
  --from-literal=client-secret='<client secret from the IdP>' \
  --from-literal=cookie-secret="$(openssl rand -hex 16)"
```

Or let ESO build it from an existing store:

```yaml
ingress:
  sso:
    oauth2Proxy:
      existingSecret: armonik-oauth2-proxy
      externalSecret:
        storeName: vault
        storeKind: ClusterSecretStore
        clientSecret: {key: armonik/oauth2-proxy, property: client-secret}
        cookieSecret: {key: armonik/oauth2-proxy, property: cookie-secret}
```

## Identity providers

### Google

- OAuth client of type "Web application", authorized redirect URI
  `https://armonik.example.com/oauth2/callback`.
- `issuerUrl: https://accounts.google.com`, scopes `openid email profile`.
- Google ID tokens carry no `groups` claim: use user mode, and restrict with `emailDomains`.

### Keycloak

- Client with "Client authentication" on, standard flow, valid redirect URI
  `https://armonik.example.com/oauth2/callback`.
- `issuerUrl: https://<keycloak>/realms/<realm>`.
- For group mode, add a "Group Membership" mapper to the client's dedicated scope, token claim
  name `groups`. With "Full group path" on, groups read `/armonik-admins`: write them so in
  `groupMapping` and `allowedGroups`.

## The sidecar

oauth2-proxy is a native sidecar: the last entry of the nginx pod's `initContainers`, after
`extraInitContainers`, with `restartPolicy: Always`. `extraContainers` still follow nginx in
`containers`, and a `podSpecPatch.initContainers` list is refused with SSO (use
`extraInitContainers`). So `sso.enabled` needs Kubernetes 1.29 or later, where native sidecars are
on by default (GA in 1.33): an older API server drops `restartPolicy`, leaving an init container
that never exits and an nginx that never starts. The render fails below 1.29, read from the API
server by `helm install` and from `--kube-version` by `helm template`. The ingress chart itself
still installs on 1.25 with SSO off.

**Startup.** nginx starts once the sidecar's `startupProbe` passes, so nginx never serves a request
oauth2-proxy cannot answer. oauth2-proxy runs OIDC discovery before listening and exits if the IdP
is unreachable: the sidecar then restarts with a back-off and nginx waits, the grpc port included.
That port has no use for oauth2-proxy, but an IdP outage at pod start now delays it; a running pod
is not affected.

**Probes.** oauth2-proxy listens on 127.0.0.1:4180, out of the kubelet's reach, and its image has
no shell for an `exec` probe. It also opens its metrics listener on the pod IP (`--metrics-address`,
port 44180, named `sso-metrics`), which answers `/metrics` on every path and nothing else: no ping,
no auth endpoint. No Service targets it and no NetworkPolicy rule admits it; kubelet probes do not
go through NetworkPolicies.

| Probe | Target | Why |
|---|---|---|
| startup | `/metrics` on `sso-metrics`, every 2 s, 60 s budget | Gates nginx's start; must not go through nginx, which is not running yet |
| liveness | `/metrics` on `sso-metrics` | Restarts a hung process; an nginx failure does not restart the sidecar |
| readiness | `/oauth2/ready` through nginx's web port | Checks the real listener end to end; it only takes the pod out of the endpoints, never restarts or gates a start |

A crashed oauth2-proxy exits and is restarted by `restartPolicy: Always` without a probe.

Set aside:

- Probes through nginx for startup and liveness (the previous setup): the startup probe would
  deadlock (nginx starts after it), and a liveness probe would restart oauth2-proxy whenever nginx
  fails.
- No startup probe: nginx would start as soon as the process runs, before oauth2-proxy listens,
  and answer its first requests with 500.
- oauth2-proxy listening on the pod IP: it would expose `/oauth2/auth` and `/oauth2/start` beside
  nginx, where only a NetworkPolicy, often absent, would stop a client.
- `tcpSocket` on the metrics port: same reach as `httpGet`, without the HTTP round trip.
- `exec`: the image is distroless.

**Shutdown.** The kubelet sends SIGTERM to the sidecar only after nginx has exited, so oauth2-proxy
answers auth subrequests while nginx drains. Both share `terminationGracePeriodSeconds` (Kubernetes'
default 30 s, the chart sets none, `podSpecPatch` can): nginx uses most of it, oauth2-proxy stops
within a second of its SIGTERM. A gRPC stream still open at the deadline is cut as before SSO, and
both containers are then killed together.

## Network policies

oauth2-proxy runs in the nginx pod, so the nginx pod needs TCP 443 to the IdP. Once a
NetworkPolicy selects that pod (`ingress.networkPolicy.enabled`, or the umbrella's
`networkPolicy.enabled`), list the IdP's addresses in `sso.networkPolicy.idpEgressCidrs`; the render
fails without them. The umbrella's nginx egress policy also allows DNS, as it does without SSO.

## Limits

- **SDK and CLI authenticate with certificates only.** Without `mtls.enabled` the grpc port clears
  every identity header, so they cannot authenticate at all; NOTES.txt warns about it.
- **No Gateway API mode yet.** `sso.enabled` fails with `gateway.enabled` or `httpRoute.enabled`:
  the default HTTPRoute sends only `content-type: application/grpc` to the grpc port, so
  `application/grpc+proto` reaches the web port, and a Gateway terminating TLS leaves nginx no client
  certificate to verify.
- **Groups need an IdP that sends them**: Google does not.
- **Session size.** nginx passes on one `Set-Cookie` per auth subrequest, so the session must stay
  one cookie: past 4 KB oauth2-proxy splits it in `_0`/`_1` and a refresh would keep only the first
  part. `sessionCookieMinimal: true` (default) stores the identity alone (user, email, groups), not
  the OAuth tokens: 60 long groups and long claims fit in one cookie of about 1.2 KB. Refreshing
  needs those tokens, so `cookieRefresh` stays 0, which oauth2-proxy enforces. Turning
  `sessionCookieMinimal` off brings the split back with large tokens (Keycloak, Entra ID); NOTES
  warns about it. A server-side session store (Redis) is planned to lift this.
- **Large headers.** nginx reads oauth2-proxy's responses with 64 KB header buffers, the groups
  header alone exceeding the 4 KB default with a few dozen groups.
- **Health checks**: a TCP check works on either port; an HTTP one must target `sso.healthPath` on
  the web port (enforced for a GKE `HealthCheckPolicy`).
- **Revocation.** With no refresh, the session is not re-checked at the IdP: removing a user, or a
  user from a group, takes effect at the latest after `cookieExpire` (8h by default). Lower it for
  a faster revocation; the server-side session store planned with Redis would allow refreshing.
