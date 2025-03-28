{{/*
Like index, but does not error if any intermediary key is absent.
If result is empty, it is not printed out, and thus is directly compatible with conditions.

To get the result as a value other than a string you would need to convert it back using the following functions:
- bool: `empty`
- int: `int`
- array: `fromYamlArray`
- object: `fromYaml`
*/}}
{{- define "armonik.index" -}}
  {{- $value := first . | dict "value" -}}
  {{- range $key := rest . -}}
    {{- if $value.value -}}
      {{- $_ := index $value.value $key | set $value "value" -}}
    {{- end -}}
  {{- end -}}
  {{- if $value.value -}}
    {{- $value.value | toYaml -}}
  {{- end -}}
{{- end -}}
