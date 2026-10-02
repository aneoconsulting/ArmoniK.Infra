{{/*
Chart name, or nameOverride.
*/}}
{{- define "keda-hpa-activemq.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified name, truncated to 63 chars (DNS label limit). The release name alone when it
already contains the chart name.
*/}}
{{- define "keda-hpa-activemq.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart name and version, for the helm.sh/chart label.
*/}}
{{- define "keda-hpa-activemq.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "keda-hpa-activemq.labels" -}}
helm.sh/chart: {{ include "keda-hpa-activemq.chart" . }}
{{ include "keda-hpa-activemq.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "keda-hpa-activemq.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keda-hpa-activemq.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name. Unused: values.yaml has no serviceAccount block.
*/}}
{{- define "keda-hpa-activemq.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "keda-hpa-activemq.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
