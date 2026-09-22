{{/*
Resolves global.armonik.certManager.issuer into the issuerRef fields (name/kind/group) a Certificate uses.
Usage: {{ include "armonik.certManager.issuer" . | fromYaml }}
*/}}
{{- define "armonik.certManager.issuer" -}}
{{- $issuer := list .Values "global" "armonik" "certManager" "issuer" | include "armonik.utils.index" | fromYaml -}}
enabled: {{ $issuer.enabled | empty | not }}
name: {{ tpl ($issuer.name | default "") . | quote }}
kind: {{ $issuer.kind | default "Issuer" | quote }}
group: {{ $issuer.group | default "cert-manager.io" | quote }}
{{- end -}}

{{/*
Gets the Issuer a Certificate's issuerRef should point at, in order: a local existingIssuer
override, else a local Issuer the caller creates itself when the caller says the consumer has its
own provider configured (localRequested), else the shared global.armonik.certManager.issuer, else
(nothing configured anywhere) a local Issuer the caller creates itself anyway, defaulting to
provider selfSigned - kind/group for that local Issuer are derived from localProvider (default
"selfSigned"), matching what armonik.certManager.issuerManifest actually creates for that
provider: every native provider (selfSigned/ca/vault/acme/venafi) is a namespaced Issuer, googleCas
a GoogleCASIssuer.
localRequested lets one consumer opt out of an enabled global issuer and keep its own local Issuer
instead, without needing a real pre-existing existingIssuer to point at - a release can then mix
"most consumers share the global issuer" with "this one consumer keeps its own". Callers derive it
from whether the consumer's own certManager.provider key is present at all (hasKey $certManager
"provider"), not its resolved value - so provider explicitly set to "selfSigned" still counts as
requested, only an absent key falls through to the global issuer. It has no effect unless the
global issuer is actually enabled; existingIssuer still wins over both.
Input: list $ <tls.certManager.existingIssuer, may be nil> <issuerName string> <localProvider string, may be empty> <localRequested, may be empty>
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
Renders and validates ONE Issuer-shaped manifest (a namespaced Issuer for every native provider, or
a GoogleCASIssuer/GoogleCASClusterIssuer for provider=googleCas), from an already-resolved name/
namespace/kind/group/provider/spec. Shared by certmanager-issuer.yaml (the umbrella's single shared
issuer) and every consumer's own local fallback Issuer (redis/activemq/armonik-ingress/mongodb), so
the googleCas kind/group hard validation and the per-provider spec-not-empty guard live in exactly
one place instead of being reimplemented at each call site.
Input: dict
  root             $ of the caller, needed for armonik.operators
  name             metadata.name (already resolved)
  namespace        metadata.namespace (already resolved)
  provider         selfSigned|ca|vault|acme|venafi|googleCas, default "selfSigned"
  kind             default "Issuer"
  group            default "cert-manager.io"
  spec             dict, forwarded as-is into spec.<provider> (native) or spec (googleCas)
  labels           optional, pre-rendered labels block (e.g. include "armonik.labels" .)
  extraAnnotations optional, pre-rendered annotations block merged alongside the hook annotation
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
Renders the tail of a Certificate's spec that is identical everywhere one is emitted: usages (server
auth + client auth - a leaf certificate used for both, never a CA), the privateKey block, duration/
renewBefore passthrough, and issuerRef built from an already-fetched issuer (armonik.certManager.
getIssuer's output, fromYaml'd). Callers keep metadata, labels, commonName, dnsNames and secretName
local - those vary per component and are not this helper's concern.
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
