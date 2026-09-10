{{/*
Resolves global.armonik.certManager.issuer
Usage: {{ include "armonik.certManager.issuer" . | fromYaml }}
*/}}
{{- define "armonik.certManager.issuer" -}}
{{- $issuer := list .Values "global" "armonik" "certManager" "issuer" | include "armonik.utils.index" | fromYaml -}}
enabled: {{ $issuer.enabled | empty | not }}
create: {{ $issuer.create | empty | not }}
provider: {{ $issuer.provider | default "selfSigned" | quote }}
name: {{ tpl ($issuer.name | default "") . | quote }}
kind: {{ $issuer.kind | default "Issuer" | quote }}
group: {{ $issuer.group | default "cert-manager.io" | quote }}
{{- end -}}
