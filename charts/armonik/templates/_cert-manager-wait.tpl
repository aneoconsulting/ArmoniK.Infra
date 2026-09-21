{{/* Pod-template fragments: armonik.utils.patch parses what it patches, so each is a define.
     No extraContainers: a sidecar that never exits keeps the hook, and the release, waiting. */}}

{{/* Wait container: blocks until the cert-manager webhook is Available with its CA injected. */}}
{{- define "armonik.certManagerWait.container" -}}
{{- $root := .root -}}
{{- $wait := .wait -}}
{{- $image := .image -}}
name: wait
image: {{ printf "%s:%s" ($image.repository | default "alpine/k8s") ($image.tag | default "1.37.0") | quote }}
imagePullPolicy: {{ $image.pullPolicy | default "IfNotPresent" | quote }}
{{- with $wait.extraEnv }}
env:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $wait.extraVolumeMounts }}
volumeMounts:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $wait.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
command:
  - sh
  - -c
  - |
    set -e
    echo "Waiting for cert-manager webhook deployment..."
    kubectl wait \
      --for=condition=Available \
      deployment/cert-manager-webhook \
      -n {{ include "armonik.namespace" $root }} \
      --timeout={{ $wait.timeout | default "300s" }}
    echo "Waiting for webhook CA injection..."
    until kubectl get validatingwebhookconfiguration cert-manager-webhook \
      -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | grep -q .;
    do
      echo "CA bundle not injected yet..."
      sleep 5
    done
    echo "cert-manager webhook ready"
{{/* Non-trimming `end`: trimming drops the newline clip-chomping gives the script. */}}
{{ end -}}


{{/* Wait Job pod spec. Scheduling matters here: the hook gates the release. */}}
{{- define "armonik.certManagerWait.podSpec" -}}
{{- $root := .root -}}
{{- $wait := .wait -}}
{{- $global := $root.Values.global | default dict -}}
{{- $container := list (include "armonik.certManagerWait.container" .) $wait.containerPatch "certManagerWait.containerPatch" | include "armonik.utils.patch" | fromYaml -}}
restartPolicy: Never
serviceAccountName: {{ include "armonik.fullname" $root }}-cert-manager-wait
{{- with $wait.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- list $container | toYaml | nindent 2 }}
{{- with $wait.extraVolumes }}
volumes:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with concat ($wait.imagePullSecrets | default list) ($global.imagePullSecrets | default list) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{/* The hook gates the release: untolerated, it never schedules on a fully tainted cluster. */}}
{{- with $wait.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $wait.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $wait.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $wait.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
{{- end -}}
