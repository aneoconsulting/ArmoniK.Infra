{{/*
Configuration for GCS forwarded to ArmoniK Core.
This configuration is used to configure the GCS object storage adapter.
*/}}
{{- define "armonik.gcs.conf" -}}
{{- $gcs := list .Values "dependencies" "gcs" | include "armonik.utils.index" | fromYaml -}}
{{- if $gcs.enabled }}
env:
  Components__ObjectStorageAdaptorSettings__ClassName: "ArmoniK.Core.Adapters.Gcs.ObjectBuilder"
  Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath: "/adapters/object/gcs/ArmoniK.Core.Adapters.Gcs.dll"
  Gcs__ProjectId: {{ $gcs.projectId | quote }}
  Gcs__BucketName: {{ $gcs.bucketName | quote }}
  Gcs__CredentialsFilePath: {{ $gcs.credentialsFilePath | quote }}
  Gcs__EmulatorEndpoint: {{ $gcs.emulatorEndpoint | quote }}
{{- end }}
{{- end }}
