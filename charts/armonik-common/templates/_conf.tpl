{{/*
Takes a list of configurations and returns a merged configuration.

# Schema

type: array
items:
  type: object
  properties:
    env:
      type: object
      additionalProperties: { "type": "string" }
    envConfigmap:
      type: array
      items: { "type": "string" }
      uniqueItems: true
    envFromConfigmap:
      type: object
      additionalProperties:
        type: object
        required: [ "configmap", "field" ]
        properties:
          configmap: { "type": "string" }
          field:     { "type": "string" }
    envSecret:
      type: array
      items: { "type": "string" }
      uniqueItems: true
    envFromSecret:
      type: object
      additionalProperties:
        type: object
        required: [ "secret", "field" ]
        properties:
          secret: { "type": "string" }
          field:  { "type": "string" }
    mountConfigmap:
      type: object
      additionalProperties:
        type: object
        required: [ "configmap", "path" ]
        properties:
          configmap: { "type": "string" }
          # See mountSecret below.
          path:      { "type": "string" }
          subpath:   { "type": "string" }
          mode:      { "type": "string" }
          optional:  { "type": "boolean" }
          items:
            type: object
            required: [ "field" ]
            properties:
              field: { "type": "string" }
              mode:  { "type": "string" }
    mountSecret:
      type: object
      additionalProperties:
        type: object
        required: [ "secret", "path" ]
        properties:
          secret: { "type": "string" }
          # Aggregation source only (conf.<layer>.mountSecret): key prefix on imported keys; default
          # "<mount-name>-", "" for none. A source drives the aggregate via secret/prefix/items; the
          # consuming-mount fields below may still be set to mirror the plane config (only path is
          # then validated - see path).
          prefix:    { "type": "string" }
          # Consuming-mount mountPath. On an aggregation source it is validated against the umbrella
          # mountPath: it must equal it (or, with a subpath, be a path under it).
          path:      { "type": "string" }
          # Consuming-mount subPath (aggregate key, prefix included). Not refreshed on rotation.
          subpath:   { "type": "string" }
          mode:      { "type": "string" }
          optional:  { "type": "boolean" }
          # map <dest> -> { field: <source key> }.
          #  consuming mount: secret volume items (whitelist).
          #  aggregation source: per-key select+rename into the aggregate via ESO data[] ("<prefix><dest>", flat).
          items:
            type: object
            required: [ "field" ]
            properties:
              field: { "type": "string" }
              mode:  { "type": "string" }


*/}}
{{- define "armonik.conf.merge" }}
  {{- $merged := dict
                  "env" dict
                  "envConfigmap" list
                  "envFromConfigmap" dict
                  "envSecret" list
                  "envFromSecret" dict
                  "mountConfigmap" dict
                  "mountSecret" dict
  }}
  {{- range $conf := . }}
    {{- if $conf -}}
      {{- $_ := $conf.env | default dict | deepCopy | mergeOverwrite $merged.env }}
      {{- $_ := $conf.envConfigmap | default list | concat $merged.envConfigmap | set $merged "envConfigmap" }}
      {{- $_ := $conf.envSecret | default list | concat $merged.envSecret | set $merged "envSecret" }}
      {{- $_ := $conf.envFromConfigmap | default dict | deepCopy | mergeOverwrite $merged.envFromConfigmap }}
      {{- $_ := $conf.envFromSecret | default dict | deepCopy | mergeOverwrite $merged.envFromSecret }}
      {{- $_ := $conf.mountConfigmap | default dict | deepCopy | mergeOverwrite $merged.mountConfigmap }}
      {{- $_ := $conf.mountSecret | default dict | deepCopy | mergeOverwrite $merged.mountSecret }}
    {{- end -}}
  {{- end }}
  {{- $_ := $merged.envConfigmap | uniq | set $merged "envConfigmap" }}
  {{- $_ := $merged.envSecret | uniq | set $merged "envSecret" }}
  {{- $merged | toYaml }}
{{- end }}

{{/*
Prefix of every conf Secret name: .Values.conf.source (tpl-rendered), default .Release.Name.

# Usage

{{ include "armonik.conf.source" $ }}
*/}}
{{- define "armonik.conf.source" -}}
  {{- $conf := list .Values "conf" | include "armonik.utils.index" | fromYaml -}}
  {{- $source := $conf.source | default .Release.Name -}}
  {{- tpl $source . -}}
{{- end -}}

{{/*
Name of a conf layer's Secret: <source>-conf-<layer>.

# Usage

{{ list "core" $ | include "armonik.conf.secretName" }}
*/}}
{{- define "armonik.conf.secretName" -}}
  {{- $layer := index . 0 -}}
  {{- $root := index . 1 -}}
  {{- printf "%s-conf-%s" (include "armonik.conf.source" $root) $layer | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name of a conf layer's mount Secret (TLS material): <source>-conf-<layer>-mount.

# Usage

{{ list "core" $ | include "armonik.conf.mountSecretName" }}
*/}}
{{- define "armonik.conf.mountSecretName" -}}
  {{- $layer := index . 0 -}}
  {{- $root := index . 1 -}}
  {{- printf "%s-conf-%s-mount" (include "armonik.conf.source" $root) $layer | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Root dir for conf mount Secrets in pods; both the storage env strings and the volumeMounts derive
from it. Precedence: .Values.conf.mountPath > .Values.global.armonik.mountPath > "/mounts" (trailing
"/" trimmed). Root scope only, never inside a backend-subchart `with`.

# Usage

{{ include "armonik.conf.mountPath" $ }}
*/}}
{{- define "armonik.conf.mountPath" -}}
  {{- $global := list .Values "global" "armonik" "mountPath" | include "armonik.utils.index" -}}
  {{- $conf := list .Values "conf" | include "armonik.utils.index" | fromYaml -}}
  {{- $conf.mountPath | default $global | default "/mounts" | trimSuffix "/" -}}
{{- end -}}

{{/*
In-pod path of one mounted conf file: <mountPath>/<prefix><filename>. Keeps the storage env string
and the mounted file in sync.

# Usage

{{ list "mongodb-" "ca.crt" $root | include "armonik.conf.mountFilePath" }}
*/}}
{{- define "armonik.conf.mountFilePath" -}}
  {{- $prefix := index . 0 -}}
  {{- $file := index . 1 -}}
  {{- $root := index . 2 -}}
  {{- printf "%s/%s%s" (include "armonik.conf.mountPath" $root) $prefix $file -}}
{{- end -}}

{{/*
Name of the release SecretStore used by the conf ExternalSecrets.

# Usage

{{ include "armonik.conf.storeName" $ }}
*/}}
{{- define "armonik.conf.storeName" -}}
  {{- printf "%s-conf-store" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Whether ESO is enabled (dependencies.external-secrets.enabled). "true"/"false"; default "true".

# Usage

{{ if eq (include "armonik.conf.esoEnabled" $) "true" }}
*/}}
{{- define "armonik.conf.esoEnabled" -}}
  {{- $eso := list .Values "dependencies" "external-secrets" | include "armonik.utils.index" | fromYaml -}}
  {{- if kindIs "bool" $eso.enabled -}}{{ $eso.enabled }}{{- else -}}true{{- end -}}
{{- end -}}

{{/*
Fails if a built conf layer declares fields the umbrella cannot render into a Secret:
- envConfigmap / envFromConfigmap / mountConfigmap are ALWAYS unsupported (a layer is rendered as a
  Secret, and ESO can import only from Secrets, so ConfigMap sources cannot be represented).
- when ESO is disabled a layer is a plain Secret carrying only literal env, so envSecret /
  envFromSecret / mountSecret (which need ESO to populate/aggregate) are unsupported too.

# Usage

{{ list "core" $conf $ | include "armonik.conf.validate" }}
*/}}
{{- define "armonik.conf.validate" -}}
  {{- $layer := index . 0 -}}
  {{- $conf := index . 1 -}}
  {{- $root := index . 2 -}}
  {{- if or $conf.envConfigmap $conf.envFromConfigmap $conf.mountConfigmap -}}
    {{- fail (printf "conf layer %q: envConfigmap/envFromConfigmap/mountConfigmap are unsupported - each layer is rendered as a Secret and ESO can import only from Secrets" $layer) -}}
  {{- end -}}
  {{- if ne (include "armonik.conf.esoEnabled" $root) "true" -}}
    {{- if or $conf.envSecret $conf.envFromSecret $conf.mountSecret -}}
      {{- fail (printf "conf layer %q: External Secrets is disabled, so only 'env' is supported; envSecret/envFromSecret/mountSecret require ESO (enable dependencies.external-secrets, or pre-create the Secret)" $layer) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
tpl-renders a conf's name-bearing fields (envSecret/envConfigmap/mountSecret.secret/...) against
the root. Idempotent on plain strings.

# Usage

{{ $conf := list $conf $ | include "armonik.conf.resolve" | fromYaml }}
*/}}
{{- define "armonik.conf.resolve" -}}
  {{- $conf := index . 0 | deepCopy -}}
  {{- $root := index . 1 -}}
  {{- if $conf.envSecret -}}
    {{- $rendered := list -}}
    {{- range $s := $conf.envSecret -}}
      {{- $rendered = append $rendered (tpl $s $root) -}}
    {{- end -}}
    {{- $_ := set $conf "envSecret" $rendered -}}
  {{- end -}}
  {{- if $conf.envConfigmap -}}
    {{- $rendered := list -}}
    {{- range $s := $conf.envConfigmap -}}
      {{- $rendered = append $rendered (tpl $s $root) -}}
    {{- end -}}
    {{- $_ := set $conf "envConfigmap" $rendered -}}
  {{- end -}}
  {{- range $n, $m := $conf.mountSecret | default dict -}}
    {{- $_ := set $m "secret" (tpl $m.secret $root) -}}
    {{- if $m.subpath -}}{{- $_ := set $m "subpath" (tpl $m.subpath $root) -}}{{- end -}}
    {{- if $m.path -}}{{- $_ := set $m "path" (tpl $m.path $root) -}}{{- end -}}
  {{- end -}}
  {{- range $n, $m := $conf.mountConfigmap | default dict -}}
    {{- $_ := set $m "configmap" (tpl $m.configmap $root) -}}
    {{- if $m.subpath -}}{{- $_ := set $m "subpath" (tpl $m.subpath $root) -}}{{- end -}}
    {{- if $m.path -}}{{- $_ := set $m "path" (tpl $m.path $root) -}}{{- end -}}
  {{- end -}}
  {{- $conf | toYaml -}}
{{- end -}}

{{- define "armonik.conf.generateEnv" }}
{{- range $name, $value := .env }}
- name: {{ $name | quote }}
  value: {{ $value | quote }}
{{- end }}{{/* range $name, $value := .env */}}
{{- range $name, $value := .envFromConfigmap }}
- name: {{ $name | quote }}
  valueFrom:
    configMapKeyRef:
      name: {{ $value.configmap | quote }}
      key: {{ $value.field | quote }}
{{- end }}{{/* range $name, $value := .envFromConfigmap */}}
{{- range $name, $value := .envFromSecret }}
- name: {{ $name | quote }}
  valueFrom:
    secretKeyRef:
      name: {{ $value.secret | quote }}
      key: {{ $value.field | quote }}
{{- end }}{{/* range $name, $value := .envFromSecret */}}
{{- end -}}{{/* define "armonik.conf.generateEnv" */}}

{{- define "armonik.conf.generateEnvFrom" }}
{{- range $name := .envConfigmap }}
- configMapRef:
    name: {{ $name | quote }}
    optional: false
{{- end }}{{/* range $name := .envConfigmap */}}
{{- range $name := .envSecret }}
- secretRef:
    name: {{ $name | quote }}
    optional: false
{{- end }}{{/* range $name := .envSecret */}}
{{- end -}}{{/* define "armonik.conf.generateEnvFrom" */}}

{{- define "armonik.conf.generateVolumeMounts" }}
{{- range $name, $mount := .mountConfigmap }}
- name: {{ $name | quote }}
  mountPath: {{ $mount.path | quote }}
  {{- with $mount.subpath }}
  subPath: {{ . | quote }}
  {{- end }}
  readOnly: true
{{- end }}{{/* range $name, $mount := .mountConfigmap */}}
{{- range $name, $mount := .mountSecret }}
- name: {{ $name | quote }}
  mountPath: {{ $mount.path | quote }}
  {{- with $mount.subpath }}
  subPath: {{ . | quote }}
  {{- end }}
  readOnly: true
{{- end }}{{/* range $name, $mount := .mountSecret */}}
{{- end -}}{{/* define "armonik.conf.generateVolumeMounts" */}}

{{- define "armonik.conf.generateVolumes" }}
{{- range $name, $mount := .mountConfigmap }}
- name: {{ $name | quote }}
  configMap:
    name: {{ $mount.configmap | quote }}
    optional: {{ $mount.optional | default false }}
    {{- if $mount.items }}
    items:
      {{- range $itemName, $item := $mount.items }}
      - key: {{ $item.field | quote }}
        path: {{ $itemName | quote }}
        {{- if $item.mode }}
        mode: {{ $item.mode }}
        {{- end }}{{/* if $item.mode */}}
      {{- end }}{{/* range $itemName, $item := $mount.items */}}
    {{- end }}{{/* if $mount.items */}}
    {{- if $mount.mode }}
    defaultMode: {{ $mount.mode }}
    {{- end }}{{/* if $mount.mode */}}
{{- end }}{{/* range $name, $mount := .mountConfigmap */}}
{{- range $name, $mount := .mountSecret }}
- name: {{ $name | quote }}
  secret:
    secretName: {{ $mount.secret | quote }}
    optional: {{ $mount.optional | default false }}
    {{- if $mount.items }}
    items:
      {{- range $itemName, $item := $mount.items }}
      - key: {{ $item.field | quote }}
        path: {{ $itemName | quote }}
        {{- if $item.mode }}
        mode: {{ $item.mode }}
        {{- end }}{{/* if $item.mode" */}}
      {{- end }}{{/* $itemName, $item := $mount.items */}}
    {{- end }}{{/* if $mount.items */}}
    {{- if $mount.mode }}
    defaultMode: {{ $mount.mode }}
    {{- end }}{{/* if $mount.mode */}}
{{- end }}{{/* range $name, $mount := .mountSecret */}}
{{- end -}}{{/* define "armonik.conf.generateVolumes" */}}
