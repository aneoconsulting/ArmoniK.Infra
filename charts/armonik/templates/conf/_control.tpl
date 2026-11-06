{{/* "control" layer: identity header names + controlHelper hook (empty) + conf.control. */}}
{{- define "armonik.conf.controlHelper" -}}
{{- end -}}
{{/*
Authenticator header names from ingress.identityHeaders, the single source nginx sends them from,
so a renamed header reaches ArmoniK Core too. Rendered even at Core's defaults, which the umbrella
does not duplicate. Nothing without the ingress subchart.
*/}}
{{- define "armonik.conf.identityHeaders" -}}
  {{- with .Subcharts.ingress -}}
    {{- $headers := include "armonik.ingress.identityHeaders" .Values | fromYaml -}}
env:
  Authenticator__CNHeader: {{ $headers.commonName.name | quote }}
  Authenticator__FingerprintHeader: {{ $headers.fingerprint.name | quote }}
  Authenticator__ImpersonationUsernameHeader: {{ $headers.impersonationUsername.name | quote }}
  Authenticator__ImpersonationIdHeader: {{ $headers.impersonationId.name | quote }}
  {{- end -}}
{{- end -}}
{{- define "armonik.conf.control" -}}
  {{- list
        (include "armonik.conf.identityHeaders" . | fromYaml)
        (include "armonik.conf.controlHelper" . | fromYaml)
        (list .Values "conf" "control" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
