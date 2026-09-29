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
      uniqueItems: true
      items:
        # "<secret>" is shorthand for { secret: <secret> }.
        oneOf:
          - { "type": "string" }
          - type: object
            required: [ "secret" ]
            properties:
              secret:    { "type": "string" }
              # Store fields as on envFromSecret below.
              storeName: { "type": "string" }
              storeKind: { "type": "string", "enum": [ "SecretStore", "ClusterSecretStore" ] }
              namespace: { "type": "string" }
              version:   { "type": "string" }
    envFromSecret:
      type: object
      additionalProperties:
        type: object
        required: [ "secret" ]
        properties:
          secret: { "type": "string" }
          # Required unless storeName is set: without a property the Kubernetes provider imports
          # the whole Secret as one blob, while a store entry may hold a single value.
          field:  { "type": "string" }
          # Aggregation source only: an ESO store that ALREADY exists, these charts creating none
          # but their own Kubernetes-provider ones. storeKind defaults to SecretStore, which must
          # then sit in the release namespace. namespace routes that Kubernetes store instead, so
          # it excludes storeName. version needs storeName, the Kubernetes provider ignoring it.
          storeName: { "type": "string" }
          storeKind: { "type": "string", "enum": [ "SecretStore", "ClusterSecretStore" ] }
          namespace: { "type": "string" }
          version:   { "type": "string" }
    mountConfigmap: { type: array, items: <same object as mountSecret below, with configmap instead of secret/prefix> }
    mountSecret:
      type: array
      items:
        type: object
        required: [ "secret" ]        # or "configmap" for mountConfigmap
        properties:
          secret: { "type": "string" }
          # Aggregation source only (umbrella conf.<layer>.mountSecret): key prefix on imported keys;
          # "" / unset = none. A source drives the aggregate via secret/prefix/items; the consuming-mount
          # fields below may still be set to mirror the plane config (only path is then validated).
          prefix:    { "type": "string" }
          # Store fields as on envFromSecret above; aggregation source only.
          storeName: { "type": "string" }
          storeKind: { "type": "string", "enum": [ "SecretStore", "ClusterSecretStore" ] }
          namespace: { "type": "string" }
          version:   { "type": "string" }
          # Consuming-mount mountPath; defaults to armonik.conf.mountPath. Entries (secret and/or
          # configmap) that resolve to the SAME path are merged into one projected volume. On an
          # aggregation source it is validated against the umbrella mountPath (equal, or under it if subpath).
          path:      { "type": "string" }
          # Consuming-mount subPath (selects one file; not refreshed on rotation). Rejected when the path
          # is shared by 2+ entries (a projected group has a single mountPath).
          subpath:   { "type": "string" }
          # File mode; defaults to "0444". When a path is shared it is the projected volume defaultMode
          # and must be identical across the group (use items[].mode for per-file perms).
          mode:      { "type": "string" }
          optional:  { "type": "boolean" }
          # map <dest> -> { field: <source key> }.
          #  consuming mount: secret/configmap volume items (whitelist).
          #  aggregation source: per-key select+rename into the aggregate via ESO data[] ("<prefix><dest>", flat).
          # field is required unless storeName is set, as on envFromSecret.
          items:
            type: object
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
                  "mountConfigmap" list
                  "mountSecret" list
  }}
  {{- range $conf := . }}
    {{- if $conf -}}
      {{- $_ := $conf.env | default dict | deepCopy | mergeOverwrite $merged.env }}
      {{- $_ := $conf.envConfigmap | default list | concat $merged.envConfigmap | set $merged "envConfigmap" }}
      {{- range $s := $conf.envSecret | default list }}
        {{- $_ := include "armonik.conf.secretItem" $s | fromYaml | append $merged.envSecret | set $merged "envSecret" }}
      {{- end }}
      {{- $_ := $conf.envFromConfigmap | default dict | deepCopy | mergeOverwrite $merged.envFromConfigmap }}
      {{- $_ := $conf.envFromSecret | default dict | deepCopy | mergeOverwrite $merged.envFromSecret }}
      {{- $_ := $conf.mountConfigmap | default list | concat $merged.mountConfigmap | set $merged "mountConfigmap" }}
      {{- $_ := $conf.mountSecret | default list | concat $merged.mountSecret | set $merged "mountSecret" }}
    {{- end -}}
  {{- end }}
  {{- $_ := $merged.envConfigmap | uniq | set $merged "envConfigmap" }}
  {{- $_ := $merged.envSecret | uniq | set $merged "envSecret" }}
  {{- $merged | toYaml }}
{{- end }}

{{/*
Normalizes one envSecret item: "<secret>" is shorthand for { secret: <secret> }. Applied by both
armonik.conf.merge and armonik.conf.resolve, callers reaching the emitters through only one.

# Usage

{{ $item := include "armonik.conf.secretItem" $s | fromYaml }}
*/}}
{{- define "armonik.conf.secretItem" -}}
  {{- if kindIs "map" . -}}
    {{- toYaml . -}}
  {{- else -}}
    {{- dict "secret" (toString .) | toYaml -}}
  {{- end -}}
{{- end -}}

{{/*
Prefix of every conf Secret name: .Values.conf.source (tpl-rendered), default .Release.Name.

# Usage

{{ include "armonik.conf.source" $ }}
*/}}
{{- define "armonik.conf.source" -}}
  {{- $global := list .Values "global" "armonik" "source" | include "armonik.utils.index" -}}
  {{- $conf := list .Values "conf" | include "armonik.utils.index" | fromYaml -}}
  {{- $source := $conf.source | default $global | default .Release.Name -}}
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
Volume/volumeMount name for a group of conf mounts at one path. Content-addressed: a pure function of
the path AND the group's mount specs, so the same (path + sources) always yields the same name in both
generators, while different source sets at the same path (e.g. compute agent vs credential-free worker)
get distinct volumes. Args: (list <path> <group>), group = list of { mount: <entry> }.

# Usage

{{ list $p $group | include "armonik.conf.mountVolumeName" }}
*/}}
{{- define "armonik.conf.mountVolumeName" -}}
  {{- $path := index . 0 -}}
  {{- $specs := list -}}
  {{- range $e := index . 1 -}}
    {{- $specs = append $specs $e.mount -}}
  {{- end -}}
  {{- printf "conf-%s" (list $path $specs | toYaml | sha256sum | trunc 16) -}}
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
ESO sync cadence of the conf ExternalSecrets: .Values.conf.refreshInterval, else 1h0m0s. A 0 syncs
once and never refreshes. Worth raising on a metered provider (Secret Manager bills per access); it
cannot be per store, one layer being one ExternalSecret that may mix stores.

# Usage

{{ include "armonik.conf.refreshInterval" $ }}
*/}}
{{- define "armonik.conf.refreshInterval" -}}
  {{- $conf := list .Values "conf" | include "armonik.utils.index" | fromYaml -}}
  {{- $value := "1h0m0s" -}}
  {{- /* Decoded, not `default`ed: a bare 0 is a legitimate value default would swallow. */ -}}
  {{- if not (kindIs "invalid" $conf.refreshInterval) -}}
    {{- $value = $conf.refreshInterval | toString | default $value -}}
  {{- end -}}
  {{- $value -}}
{{- end -}}

{{/*
Optional refreshPolicy of the conf ExternalSecrets: .Values.conf.refreshPolicy, else empty, ESO
then applying Periodic.

# Usage

{{- with (include "armonik.conf.refreshPolicy" $) }}
refreshPolicy: {{ . | quote }}
{{- end }}
*/}}
{{- define "armonik.conf.refreshPolicy" -}}
  {{- $conf := list .Values "conf" | include "armonik.utils.index" | fromYaml -}}
  {{- with $conf.refreshPolicy -}}
    {{- if not (has . (list "CreatedOnce" "Periodic" "OnChange")) -}}
      {{- printf "conf.refreshPolicy %q must be CreatedOnce, Periodic or OnChange" . | fail -}}
    {{- end -}}
    {{- . -}}
  {{- end -}}
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
Per-release SecretStore reading the given namespace, as seen from the namespace holding the
ExternalSecret: this chart's, or the optional third argument (see secret-store.yaml).

# Usage

{{ list "" $ | include "armonik.conf.storeName" }}
{{ list "mongodb-ns" $ | include "armonik.conf.storeName" }}
{{ list "mongodb-ns" $ "exporter-ns" | include "armonik.conf.storeName" }}
*/}}
{{- define "armonik.conf.storeName" -}}
  {{- $namespace := index . 0 -}}
  {{- $root := index . 1 -}}
  {{- $consumer := include "armonik.namespace" $root -}}
  {{- if gt (len .) 2 -}}
    {{- $consumer = index . 2 -}}
  {{- end -}}
  {{- if or (not $namespace) (eq $namespace $consumer) -}}
    {{- printf "%s-conf-store" $root.Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-conf-store-%s" $root.Release.Name $namespace | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{/*
Store to route one data[]/dataFrom[] entry through, empty when the base store reads it. Arguments as
armonik.conf.storeName.
*/}}
{{- define "armonik.conf.storeNameOverride" -}}
  {{- $namespace := index . 0 -}}
  {{- $root := index . 1 -}}
  {{- $consumer := include "armonik.namespace" $root -}}
  {{- if gt (len .) 2 -}}
    {{- $consumer = index . 2 -}}
  {{- end -}}
  {{- if and $namespace (ne $namespace $consumer) -}}
    {{- list $namespace $root $consumer | include "armonik.conf.storeName" -}}
  {{- end -}}
{{- end -}}

{{/*
storeRef of one conf aggregation source: empty when it reads this release's own Kubernetes-provider
store, else the store to route it through. Single validation point for the store fields. A named
store is never created here and its existence is uncheckable (lookup is banned), so a namespaced
SecretStore outside the release namespace only surfaces as an ESO sync error.

Args: (list <source> <label> $), label naming the source in failure messages.

# Usage

{{- with (list $ref (printf "conf layer %q env %q" $layer $k) $ | include "armonik.conf.sourceRef") }}
sourceRef:
  storeRef:
    {{- . | nindent 4 }}
{{- end }}
*/}}
{{- define "armonik.conf.sourceRef" -}}
  {{- $entry := index . 0 -}}
  {{- $label := index . 1 -}}
  {{- $root := index . 2 -}}
  {{- $name := $entry.storeName | default "" -}}
  {{- $kind := $entry.storeKind | default "" -}}
  {{- if $name -}}
    {{- with $entry.namespace -}}
      {{- printf "%s: storeName %q excludes namespace %q, which routes the Kubernetes provider only" $label $name . | fail -}}
    {{- end -}}
    {{- $kind = $kind | default "SecretStore" -}}
    {{- if not (has $kind (list "SecretStore" "ClusterSecretStore")) -}}
      {{- printf "%s: storeKind %q must be SecretStore or ClusterSecretStore" $label $kind | fail -}}
    {{- end -}}
kind: {{ $kind | quote }}
name: {{ tpl $name $root | quote }}
  {{- else -}}
    {{- with $kind -}}
      {{- printf "%s: storeKind %q needs a storeName" $label . | fail -}}
    {{- end -}}
    {{- with $entry.version -}}
      {{- printf "%s: version %q needs a storeName, the Kubernetes provider ignoring it" $label (toString .) | fail -}}
    {{- end -}}
    {{- with (list $entry.namespace $root | include "armonik.conf.storeNameOverride") -}}
kind: "SecretStore"
name: {{ . | quote }}
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
      {{- $item := include "armonik.conf.secretItem" $s | fromYaml -}}
      {{- $_ := set $item "secret" (tpl $item.secret $root) -}}
      {{- if $item.storeName -}}
        {{- $_ := set $item "storeName" (tpl $item.storeName $root) -}}
      {{- end -}}
      {{- if $item.namespace -}}
        {{- $_ := set $item "namespace" (tpl $item.namespace $root) -}}
      {{- end -}}
      {{- $rendered = append $rendered $item -}}
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
  {{- range $name, $ref := $conf.envFromSecret | default dict -}}
    {{- if $ref.namespace -}}
      {{- $_ := set $ref "namespace" (tpl $ref.namespace $root) -}}
    {{- end -}}
    {{- if $ref.storeName -}}
      {{- $_ := set $ref "storeName" (tpl $ref.storeName $root) -}}
    {{- end -}}
  {{- end -}}
  {{- $mountPath := include "armonik.conf.mountPath" $root -}}
  {{- range $m := $conf.mountSecret | default list -}}
    {{- $_ := set $m "secret" (tpl $m.secret $root) -}}
    {{- if $m.namespace -}}
      {{- $_ := set $m "namespace" (tpl $m.namespace $root) -}}
    {{- end -}}
    {{- if $m.storeName -}}
      {{- $_ := set $m "storeName" (tpl $m.storeName $root) -}}
    {{- end -}}
    {{- if $m.subpath -}}
      {{- $_ := set $m "subpath" (tpl $m.subpath $root) -}}
    {{- end -}}
    {{- if $m.path -}}
      {{- $_ := set $m "path" (tpl $m.path $root) -}}
    {{- else -}}
      {{- $_ := set $m "path" $mountPath -}}
    {{- end -}}
    {{- if not $m.mode -}}
      {{- $_ := set $m "mode" "0444" -}}
    {{- end -}}
  {{- end -}}
  {{- range $m := $conf.mountConfigmap | default list -}}
    {{- $_ := set $m "configmap" (tpl $m.configmap $root) -}}
    {{- if $m.subpath -}}
      {{- $_ := set $m "subpath" (tpl $m.subpath $root) -}}
    {{- end -}}
    {{- if $m.path -}}
      {{- $_ := set $m "path" (tpl $m.path $root) -}}
    {{- else -}}
      {{- $_ := set $m "path" $mountPath -}}
    {{- end -}}
    {{- if not $m.mode -}}
      {{- $_ := set $m "mode" "0444" -}}
    {{- end -}}
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
{{- range $s := .envSecret }}
{{- $item := include "armonik.conf.secretItem" $s | fromYaml }}
- secretRef:
    name: {{ $item.secret | quote }}
    optional: false
{{- end }}{{/* range $s := .envSecret */}}
{{- end -}}{{/* define "armonik.conf.generateEnvFrom" */}}

{{/* Groups a conf's mountConfigmap + mountSecret entries by resolved path (entries sharing a path are
     merged into one projected volume). Returns, as YAML:
       order:  [ paths, in first-seen order ]
       byPath: { <path>: [ { kind: configmap|secret, mount: <entry> } ] } */}}
{{- define "armonik.conf.groupMounts" -}}
  {{- $byPath := dict -}}
  {{- $order := list -}}
  {{- range $mount := .mountConfigmap -}}
    {{- $e := dict "kind" "configmap" "mount" $mount -}}
    {{- if hasKey $byPath $mount.path -}}
      {{- $_ := set $byPath $mount.path (append (index $byPath $mount.path) $e) -}}
    {{- else -}}
      {{- $_ := set $byPath $mount.path (list $e) -}}
      {{- $order = append $order $mount.path -}}
    {{- end -}}
  {{- end -}}
  {{- range $mount := .mountSecret -}}
    {{- $e := dict "kind" "secret" "mount" $mount -}}
    {{- if hasKey $byPath $mount.path -}}
      {{- $_ := set $byPath $mount.path (append (index $byPath $mount.path) $e) -}}
    {{- else -}}
      {{- $_ := set $byPath $mount.path (list $e) -}}
      {{- $order = append $order $mount.path -}}
    {{- end -}}
  {{- end -}}
  {{- dict "order" $order "byPath" $byPath | toYaml -}}
{{- end -}}{{/* define "armonik.conf.groupMounts" */}}

{{/* Emits one volumeMount per distinct path (entries sharing a path are merged into one projected
     volume, so they share a single mountPath). */}}
{{- define "armonik.conf.generateVolumeMounts" -}}
  {{- $g := include "armonik.conf.groupMounts" . | fromYaml -}}
  {{- range $p := $g.order }}
    {{- $group := index $g.byPath $p -}}
    {{- if gt (len $group) 1 -}}
      {{- range $e := $group -}}
        {{- if $e.mount.subpath -}}
          {{- fail (printf "conf mount of %q: subpath is not supported at shared path %q - entries sharing a path are merged into one projected volume with a single mountPath; use a distinct path" (coalesce $e.mount.secret $e.mount.configmap) $p) -}}
        {{- end -}}
      {{- end -}}
    {{- end }}
- name: {{ list $p $group | include "armonik.conf.mountVolumeName" | quote }}
  mountPath: {{ $p | quote }}
  {{- if and (eq (len $group) 1) (index $group 0).mount.subpath }}
  subPath: {{ (index $group 0).mount.subpath | quote }}
  {{- end }}
  readOnly: true
  {{- end }}
{{- end -}}{{/* define "armonik.conf.generateVolumeMounts" */}}

{{/* Takes a LIST of confs (one per container that shares this pod's volumes). Within a conf, entries
     (mountConfigmap + mountSecret) sharing a path become sources of one projected volume; across confs,
     identical (path + sources) volumes are deduplicated by their content-addressed name, while different
     source sets at the same path (e.g. compute agent vs credential-free worker) yield distinct volumes.
     configMap sources first, then secret sources (deterministic "last source wins" on a duplicate path). */}}
{{- define "armonik.conf.generateVolumes" -}}
  {{- $byName := dict -}}
  {{- $order := list -}}
  {{- range $conf := . -}}
    {{- $g := include "armonik.conf.groupMounts" $conf | fromYaml -}}
    {{- range $p := $g.order -}}
      {{- $group := index $g.byPath $p -}}
      {{- $name := list $p $group | include "armonik.conf.mountVolumeName" -}}
      {{- if not (hasKey $byName $name) -}}
        {{- $_ := set $byName $name (dict "path" $p "group" $group) -}}
        {{- $order = append $order $name -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- range $name := $order }}
    {{- $group := (index $byName $name).group -}}
    {{- $modes := list -}}
    {{- range $e := $group -}}
      {{- with $e.mount.mode -}}
        {{- $modes = append $modes . -}}
      {{- end -}}
    {{- end -}}
    {{- $modes = uniq $modes -}}
    {{- if gt (len $modes) 1 -}}
      {{- fail (printf "conf mounts at shared path %q have conflicting modes %v; a projected volume has a single defaultMode - use the same mode on all entries at this path (or items[].mode for per-file perms)" (index $byName $name).path $modes) -}}
    {{- end }}
- name: {{ $name | quote }}
  projected:
    {{- if $modes }}
    defaultMode: {{ index $modes 0 }}
    {{- end }}
    sources:
      {{- range $e := $group }}
      {{- if eq $e.kind "configmap" }}
      - configMap:
          name: {{ $e.mount.configmap | quote }}
          optional: {{ $e.mount.optional | default false }}
          {{- with $e.mount.items }}
          items:
            {{- range $itemName, $item := . }}
            - key: {{ $item.field | quote }}
              path: {{ $itemName | quote }}
              {{- with $item.mode }}
              mode: {{ . }}
              {{- end }}
            {{- end }}
          {{- end }}
      {{- else }}
      - secret:
          name: {{ $e.mount.secret | quote }}
          optional: {{ $e.mount.optional | default false }}
          {{- with $e.mount.items }}
          items:
            {{- range $itemName, $item := . }}
            - key: {{ $item.field | quote }}
              path: {{ $itemName | quote }}
              {{- with $item.mode }}
              mode: {{ . }}
              {{- end }}
            {{- end }}
          {{- end }}
      {{- end }}
      {{- end }}
{{- end }}
{{- end -}}{{/* define "armonik.conf.generateVolumes" */}}

{{- define "armonik.controlPlane.source" -}}
  {{- $global := list .Values "global" "armonik" "controlPlane" | include "armonik.utils.index" -}}
  {{- $conf := list .Values "controlPlane" | include "armonik.utils.index" | fromYaml -}}
  {{- $source := $conf.source | default $global | default .Release.Name -}}
  {{- tpl $source . -}}
{{- end -}}
