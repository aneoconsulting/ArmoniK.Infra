{{/*
global.armonik.certManager.issuer resolved: enabled, plus the issuerRef name/kind/group.
*/}}
{{- define "armonik.certManager.issuer" -}}
{{- $issuer := list .Values "global" "armonik" "certManager" "issuer" | include "armonik.utils.index" | fromYaml -}}
enabled: {{ $issuer.enabled | empty | not }}
name: {{ tpl ($issuer.name | default "") . | quote }}
kind: {{ $issuer.kind | default "Issuer" | quote }}
group: {{ $issuer.group | default "cert-manager.io" | quote }}
{{- end -}}

{{/*
issuerRef (name/kind/group) a Certificate points at, plus needsLocalIssuer when the caller must
create that Issuer itself. In order:
  1. existingIssuer, when enabled;
  2. the shared global.armonik.certManager.issuer, when enabled and localRequested is not set;
  3. a local Issuer named issuerName, whose kind/group follow localProvider (default "selfSigned")
     as armonik.certManager.issuerManifest creates it: Issuer for a native provider, GoogleCASIssuer
     for googleCas.
localRequested lets one consumer keep its own local Issuer under an enabled global one, without a
pre-existing existingIssuer. Callers set it from the presence of their certManager.provider key
(hasKey), not its value, so an explicit "selfSigned" still opts out.
Input: list $ <tls.certManager.existingIssuer, may be nil> <issuerName> <localProvider, may be empty> <localRequested, may be empty>
Usage: {{ list $ $x $n $provider $localRequested | include "armonik.certManager.getIssuer" | fromYaml }}
*/}}
{{- define "armonik.certManager.getIssuer" -}}
{{- $root := first . -}}
{{- $existingIssuer := index . 1 | default dict -}}
{{- $issuerName := index . 2 -}}
{{- $localProvider := index . 3 | default "selfSigned" -}}
{{- $localRequested := index . 4 | empty | not -}}
{{- $localEnabled := $existingIssuer.enabled | empty | not -}}
{{- $globalIssuer := include "armonik.certManager.issuer" $root | fromYaml -}}
{{- $useGlobal := and $globalIssuer.enabled (not $localEnabled) (not $localRequested) -}}
{{- if $localEnabled }}
name: {{ $existingIssuer.name | quote }}
kind: {{ $existingIssuer.kind | default "Issuer" | quote }}
group: {{ $existingIssuer.group | default "cert-manager.io" | quote }}
needsLocalIssuer: false
{{- else if $useGlobal }}
name: {{ $globalIssuer.name | quote }}
kind: {{ $globalIssuer.kind | quote }}
group: {{ $globalIssuer.group | quote }}
needsLocalIssuer: false
{{- else if eq $localProvider "googleCas" }}
name: {{ $issuerName | quote }}
kind: GoogleCASIssuer
group: cas-issuer.jetstack.io
needsLocalIssuer: true
{{- else }}
name: {{ $issuerName | quote }}
kind: Issuer
group: cert-manager.io
needsLocalIssuer: true
{{- end }}
{{- end -}}

{{/*
Renders and validates one issuer manifest: a cert-manager one for a native provider, a
GoogleCASIssuer/GoogleCASClusterIssuer for googleCas. Single home of the googleCas kind/group checks
and the per-provider spec guard, shared by the umbrella's certmanager-issuer.yaml and every
consumer's local fallback Issuer. Hooked (weight 0) when this release installs the matching operator.
Input: dict
  root             $ of the caller, needed for armonik.operators
  name             metadata.name (already resolved)
  namespace        metadata.namespace (already resolved)
  provider         selfSigned|ca|vault|acme|venafi|googleCas, default "selfSigned"
  kind             default "Issuer"
  group            default "cert-manager.io"
  spec             dict, forwarded as-is into spec.<provider> (native) or spec (googleCas)
  labels           optional, pre-rendered labels block (e.g. include "armonik.labels" .)
  extraAnnotations optional, pre-rendered annotations block, added next to the hook annotations
  specValuesPath   values path named in "<specValuesPath>.<provider> is required..." errors
  refValuesPath    values path named in "<refValuesPath>.kind/.group is invalid..." errors, default specValuesPath
Usage: {{ include "armonik.certManager.issuerManifest" (dict "root" $ "name" $n "namespace" $ns
       "provider" $p "kind" $k "group" $g "spec" $s "specValuesPath" "...") }}
*/}}
{{- define "armonik.certManager.issuerManifest" -}}
{{- $root := .root -}}
{{- $provider := .provider | default "selfSigned" -}}
{{- $kind := .kind | default "Issuer" -}}
{{- $group := .group | default "cert-manager.io" -}}
{{- $spec := .spec | default dict -}}
{{- $specValuesPath := .specValuesPath | default "certManager" -}}
{{- $refValuesPath := .refValuesPath | default $specValuesPath -}}
{{- $ops := include "armonik.operators" $root | fromYaml -}}
{{- $nativeProviders := list "selfSigned" "ca" "vault" "acme" "venafi" -}}
{{- if has $provider $nativeProviders -}}
{{- if and ($spec | empty) (ne $provider "selfSigned") -}}
{{- fail (printf "%s.%s is required for provider=%s: forward the Issuer.spec.%s fields as-is." $specValuesPath $provider $provider $provider) -}}
{{- end -}}
apiVersion: cert-manager.io/v1
kind: {{ $kind | quote }}
metadata:
  name: {{ .name | quote }}
  namespace: {{ .namespace | quote }}
  {{- if or $ops.certManager.deploy .extraAnnotations }}
  annotations:
    {{- if $ops.certManager.deploy }}
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-weight": "0"
    {{- end }}
    {{- with .extraAnnotations }}
    {{- . | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with .labels }}
  labels:
    {{- . | nindent 4 }}
  {{- end }}
spec:
  {{ $provider }}:
    {{- toYaml $spec | nindent 4 }}
{{- else if eq $provider "googleCas" -}}
{{- if not (or $ops.googleCasIssuer.deploy $ops.googleCasIssuer.available) -}}
{{- fail (printf "%s.provider=googleCas requires the Google CAS Issuer operator: set global.armonik.operators.googleCasIssuer.deploy=true (this release installs it) or .available=true (installed by another release)." $specValuesPath) -}}
{{- end -}}
{{- if and (ne $kind "GoogleCASIssuer") (ne $kind "GoogleCASClusterIssuer") -}}
{{- fail (printf "%s.kind %q is invalid for provider=googleCas: set it to GoogleCASIssuer or GoogleCASClusterIssuer." $refValuesPath $kind) -}}
{{- end -}}
{{- if ne $group "cas-issuer.jetstack.io" -}}
{{- fail (printf "%s.group %q is invalid for provider=googleCas: set it to cas-issuer.jetstack.io (the default cert-manager.io only fits the native providers: selfSigned, ca, vault, acme, venafi)." $refValuesPath $group) -}}
{{- end -}}
{{- if $spec | empty -}}
{{- fail (printf "%s.googleCas is required for provider=googleCas: forward the GoogleCASIssuer/GoogleCASClusterIssuer spec fields (project, location, caPoolId, ...) as-is." $specValuesPath) -}}
{{- end -}}
apiVersion: cas-issuer.jetstack.io/v1beta1
kind: {{ $kind | quote }}
metadata:
  name: {{ .name | quote }}
  namespace: {{ .namespace | quote }}
  {{- if or $ops.googleCasIssuer.deploy .extraAnnotations }}
  annotations:
    {{- if $ops.googleCasIssuer.deploy }}
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-weight": "0"
    {{- end }}
    {{- with .extraAnnotations }}
    {{- . | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- with .labels }}
  labels:
    {{- . | nindent 4 }}
  {{- end }}
spec:
  {{- toYaml $spec | nindent 2 }}
{{- else -}}
{{- fail (printf "%s.provider %q is not recognized: use selfSigned, ca, vault, acme, venafi or googleCas." $specValuesPath $provider) -}}
{{- end -}}
{{- end -}}

{{/*
Common tail of a Certificate spec: usages (server and client auth, a leaf certificate, never a CA),
privateKey, duration/renewBefore passthrough, and issuerRef. Callers keep the per-component fields
(commonName, dnsNames, secretName).
Input: dict "certManager" <the component's own certManager block, read for .duration/.renewBefore>
       "issuer" <armonik.certManager.getIssuer's output, fromYaml'd>
Usage: under spec:, after the component-specific fields:
       {{- include "armonik.certManager.certificateSpec" (dict "certManager" $certManager "issuer" $issuer) | nindent 2 }}
*/}}
{{- define "armonik.certManager.certificateSpec" -}}
usages:
  - server auth
  - client auth
privateKey:
  algorithm: RSA
  size: 2048
{{- with .certManager.duration }}
duration: {{ . }}
{{- end }}
{{- with .certManager.renewBefore }}
renewBefore: {{ . }}
{{- end }}
issuerRef:
  name: {{ .issuer.name | quote }}
  kind: {{ .issuer.kind | quote }}
  group: {{ .issuer.group | quote }}
{{- end -}}
