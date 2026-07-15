{{/* "log" layer: Serilog levels from conf.log.minimumLevel (validated, fail-fast) + conf.log. */}}
{{- define "armonik.conf.logHelper" -}}
  {{- $level := (list .Values "conf" "log" | include "armonik.utils.index" | fromYaml).minimumLevel | default "Information" -}}
  {{- $validLevels := list "Verbose" "Debug" "Information" "Warning" "Error" "Fatal" -}}
  {{- if not (has $level $validLevels) -}}
    {{- fail (printf "conf.log.minimumLevel %q is invalid; must be one of: %s" $level (join ", " $validLevels)) -}}
  {{- end -}}
env:
  Serilog__MinimumLevel: {{ $level }}
{{- if eq $level "Information" }}
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
{{- end }}
{{- end -}}
{{- define "armonik.conf.log" -}}
  {{- list
        (include "armonik.conf.logHelper" . | fromYaml)
        (list .Values "conf" "log" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
