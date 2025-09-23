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
          path:      { "type": "string" }
          subpath:   { "type": "string" }
          mode:      { "type": "string" }
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
          path:      { "type": "string" }
          subpath:   { "type": "string" }
          mode:      { "type": "string" }
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
Materialize env inside a configmap

# Schema

type: object
properties:
  env: { "type": "object" }
*/}}
{{- define "armonik.conf.materialize" }}
  {{- .env | default dict | toYaml }}
{{- end }}

{{/*
Materialized configuration

# Schema

type: array
prefixItems:
  - type: string
  - type: object
    properties:
      env: { "type": "object" }
      envConfigmap:
        type: array
        items: { "type": "string" }
*/}}
{{- define "armonik.conf.materialized" }}
  {{- $configmap := index . 0 }}
  {{- $conf := index . 1 | deepCopy }}
  {{- $_ := dict | set $conf "env" }}
  {{- $_ := $configmap | append $conf.envConfigmap | uniq | set $conf "envConfigmap" }}
  {{- $conf | toYaml }}
{{- end }}

{{/*
Gets the context to execute conf named templates

# Usage

{{ $ctx := include "armonik.conf.context" $ | fromYaml }}
*/}}
{{- define "armonik.conf.context" -}}
  {{- list . "conf" | include "armonik.dependencyContext" -}}
{{- end -}}


{{- define "armonik.conf.configmap" -}}
  {{- $configmap := index . 0 -}}
  {{- $ctx := index . 1 | include "armonik.conf.context" | fromYaml -}}
  {{- if $ctx.Values.fullnameOverride }}
    {{- printf "%s-%s" $ctx.Values.fullnameOverride $configmap | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- $name := default $ctx.Chart.Name $ctx.Values.nameOverride }}
    {{- if contains $name $ctx.Release.Name }}
      {{- printf "%s-%s" $ctx.Release.Name $configmap | trunc 63 | trimSuffix "-" }}
    {{- else }}
      {{- printf "%s-%s-%s" $ctx.Release.Name $name $configmap | trunc 63 | trimSuffix "-" }}
    {{- end }}
  {{- end }}
{{- end -}}{{/* define "armonik.conf.configmap" */}}

{{- define "armonik.conf.generateEnv" }}
{{- range $name, $value := .env }}
- name: {{ $name }}
  value: {{ $value }}
{{- end }}{{/* range $name, $value := .env */}}
{{- range $name, $value := .envFromConfigmap }}
- name: {{ $name }}
  valueFrom:
    configMapKeyRef:
      name: {{ $value.configmap }}
      key: {{ $value.field }}
{{- end }}{{/* range $name, $value := .envFromConfigmap */}}
{{- range $name, $value := .envFromSecret }}
- name: {{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ $value.secret }}
      key: {{ $value.field }}
{{- end }}{{/* range $name, $value := .envFromSecret */}}
{{- end -}}{{/* define "armonik.conf.{{- define "armonik.conf.generateEnv" */}}
 
{{- define "armonik.conf.generateEnvFrom" }}
{{- range $name := .envConfigmap }}
- configMapRef:
    name: {{ $name }}
    optional: false
{{- end }}{{/* range $name := .envConfigmap */}}
{{- range $name := .envSecret }}
- secretRef:
    name: {{ $name }}
    optional: false
{{- end }}{{/* range $name := .envSecret */}}
{{- end -}}{{/* define "armonik.conf.generateEnvFrom" */}}

{{- define "armonik.conf.generateVolumeMounts" }}
{{- range $name, $mount := .mountConfigmap }}
- name: {{ $name }}
  mountPath: {{ $mount.path }}
  readOnly: {{ or (eq (toString $mount.mode) "0444") true }}
{{- end }}{{/* range $name, $mount := .mountConfigmap */}}
{{- range $name, $mount := .mountSecret }}
- name: {{ $name }}
  mountPath: {{ $mount.path }}
  readOnly: {{ or (eq (toString $mount.mode) "0444") true }}
{{- end }}{{/* range $name, $mount := .mountSecret */}}
{{- end -}}{{/* define "armonik.conf.generateVolumeMounts" */}}

{{- define "armonik.conf.generateVolumes" }}
{{- range $name, $mount := .mountConfigmap }}
- name: {{ $name }}
  configMap:
    name: {{ $mount.configmap }}
    {{- if $mount.items }}
    items:
      {{- range $itemName, $item := $mount.items }}
      - key: {{ $item.field }}
        path: {{ $itemName }}
        {{- if $item.mode }}
        mode: {{ $item.mode }}
        {{- end }}{{/* if $item.mode */}}
      {{- end }}{{/* range $itemName, $item := $mount.items */}}
    {{- end }}{{/* if $mount.items */}}
    {{- if $mount.mode }}
    defaultMode: {{ $mount.mode | replace "0" "" }}
    {{- end }}{{/* if $mount.mode */}}
{{- end }}{{/* range $name, $mount := .mountConfigmap */}}
{{- range $name, $mount := .mountSecret }}
- name: {{ $name }}
  secret:
    secretName: {{ $mount.secret }}
    {{- if $mount.items }}
    items:
      {{- range $itemName, $item := $mount.items }}
      - key: {{ $item.field }}
        path: {{ $itemName }}
        {{- if $item.mode }}
        mode: {{ $item.mode }}
        {{- end }}{{/* if $item.mode" */}}
      {{- end }}{{/* $itemName, $item := $mount.items */}}
    {{- end }}{{/* if $mount.items */}}
    {{- if $mount.mode }}
    defaultMode: {{ $mount.mode | replace "0" "" }}
    {{- end }}{{/* if $mount.mode */}}
{{- end }}{{/* range $name, $mount := .mountSecret */}}
{{- end -}}{{/* define "armonik.conf.generateVolumes" */}}
