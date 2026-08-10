{{- define "armonik.gcs.conf" -}}
{{- if .Values.gcs.enabled }}
env:
  Components__ObjectStorageAdaptorSettings__ClassName: "ArmoniK.Core.Adapters.Gcs.ObjectBuilder"
  Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath: "/adapters/object/gcs/ArmoniK.Core.Adapters.Gcs.dll"
  Gcs__ProjectId: {{ .Values.gcs.projectId | quote }}
  Gcs__BucketName: {{ .Values.gcs.bucketName | quote }}
  Gcs__CredentialsFilePath: {{ .Values.gcs.credentialsFilePath | quote }}
  Gcs__EmulatorEndpoint: {{ .Values.gcs.emulatorEndpoint | quote }}
{{- end }}
{{- end }}
