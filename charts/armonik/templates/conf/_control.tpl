{{/* "control" layer: identity header names + controlHelper hook (empty) + conf.control. */}}
{{- define "armonik.conf.controlHelper" -}}
{{- end -}}
{{/*
ArmoniK Core identity header names (Identity__*) from ingress.identityHeaders, the single source
nginx writes them from, so a renamed header reaches Core too. Only those of the methods
control-plane.authorization.authentication selects: Core warns about the settings of the others.
Shared by the control and init layers, the init validating the same configuration. Nothing without
the ingress subchart or the control plane; a value in control-plane.authorization.identity wins,
being the pod's own env.
*/}}
{{- define "armonik.conf.identityHeaders" -}}
  {{- $controlPlane := index .Subcharts "control-plane" -}}
  {{- with .Subcharts.ingress -}}
    {{- if $controlPlane -}}
      {{- $headers := include "armonik.ingress.identityHeaders" .Values | fromYaml -}}
      {{- $methods := include "armonik.control.authentication" $controlPlane.Values | splitList "," -}}
env:
      {{- if has "Xfcc" $methods }}
  Identity__CertificateHeader: {{ $headers.certificate.name | quote }}
      {{- end }}
      {{- if has "Proxy" $methods }}
  Identity__UserHeader: {{ $headers.user.name | quote }}
  Identity__RolesHeader: {{ $headers.groups.name | quote }}
      {{- end }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- define "armonik.conf.control" -}}
  {{- list
        (include "armonik.conf.identityHeaders" . | fromYaml)
        (include "armonik.conf.controlHelper" . | fromYaml)
        (list .Values "conf" "control" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
