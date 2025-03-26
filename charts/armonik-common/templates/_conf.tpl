{{/*
Takes a list of configurations and returns a merged configuration.

# Schema

type: list
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
    {{- $_ := $conf.env | default dict | deepCopy | mergeOverwrite $merged.env }}
    {{- $_ := $conf.envConfigmap | default list | concat $merged.envConfigmap | set $merged "envConfigmap" }}
    {{- $_ := $conf.envSecret | default list | concat $merged.envSecret | set $merged "envSecret" }}
    {{- $_ := $conf.envFromConfigmap | default dict | deepCopy | mergeOverwrite $merged.envFromConfigmap }}
    {{- $_ := $conf.envFromSecret | default dict | deepCopy | mergeOverwrite $merged.envFromSecret }}
    {{- $_ := $conf.mountConfigmap | default dict | deepCopy | mergeOverwrite $merged.mountConfigmap }}
    {{- $_ := $conf.mountSecret | default dict | deepCopy | mergeOverwrite $merged.mountSecret }}
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
  - type: object
    properties:
      env: { "type": "object" }
      envConfigmap:
        type: array
        items: { "type": "string" }
  - type: string
*/}}
{{- define "armonik.conf.materialized" }}
  {{- $conf := index . 0 | deepCopy }}
  {{- $configmap := index . 1 }}
  {{- $_ := dict | set $conf "env" }}
  {{- $_ := $configmap | append $conf.envConfigmap | uniq | set $conf "envConfigmap" }}
  {{- $conf | toYaml }}
{{- end }}
