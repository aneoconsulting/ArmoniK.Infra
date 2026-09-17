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
override, else the shared global.armonik.certManager.issuer, else a local self-signed Issuer that
the caller must create itself (needsLocalIssuer: true then says so).
Input: list $ <tls.certManager.existingIssuer, may be nil> <issuerName string>
Usage: {{ list $ $x $n | include "armonik.certManager.getIssuer" | fromYaml }}
*/}}
{{- define "armonik.certManager.getIssuer" -}}
{{- $root := first . -}}
{{- $existingIssuer := index . 1 | default dict -}}
{{- $issuerName := index . 2 -}}
{{- $localEnabled := $existingIssuer.enabled | empty | not -}}
{{- $globalIssuer := include "armonik.certManager.issuer" $root | fromYaml -}}
{{- $useGlobal := and $globalIssuer.enabled (not $localEnabled) -}}
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
{{- else }}
name: {{ $issuerName | quote }}
kind: Issuer
group: cert-manager.io
needsLocalIssuer: true
{{- end }}
{{- end -}}

{{/*
The invariant tail of a Certificate spec: usages (server + client auth, always a leaf, never a CA),
privateKey, duration/renewBefore passthrough, and issuerRef from an armonik.certManager.getIssuer
result. Callers keep the per-component fields (metadata, commonName, dnsNames, secretName).
Goes under spec:, after those.

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
