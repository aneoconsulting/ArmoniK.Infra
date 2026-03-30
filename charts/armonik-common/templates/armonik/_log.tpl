{{- define "armonik.conf.logHelper" -}}
  {{- $level := (.Values.log | default dict).minimumLevel | default "Information" -}}
env:
  Serilog__MinimumLevel: {{ $level }}
{{- if $level | eq "Information" }}
  Serilog__MinimumLevel__Override__ArmoniK.Core.Common.Auth.Authentication.Authenticator: Warning
  Serilog__MinimumLevel__Override__Grpc.AspNetCore.Server.ServerCallHandler: Warning
  Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Authorization: Warning
  Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Hosting.Diagnostics: Warning
  Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Routing: Warning
  Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Routing.EndpointMiddleware: Warning
  Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Server.Kestrel: Warning
  Serilog__MinimumLevel__Override__Microsoft.Extensions.Diagnostics.HealthChecks: Warning
  Serilog__MinimumLevel__Override__Microsoft.Extensions.Http.DefaultHttpClientFactory: Warning
  Serilog__MinimumLevel__Override__Serilog.AspNetCore.RequestLoggingMiddleware: Warning
{{- end -}}
{{- end -}}

{{- define "armonik.conf.logRaw" -}}
  {{- $ctx := include "armonik.conf.context" . | fromYaml -}}
  {{- list
        (include "armonik.conf.logHelper" $ctx | fromYaml)
        $ctx.Values.log
      | include "armonik.conf.merge"
  -}}
{{- end -}}

{{- define "armonik.conf.log" -}}
  {{- $configmap := list "log" . | include "armonik.conf.configmap" -}}
  {{- include "armonik.conf.logRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
{{- end -}}
