#!/bin/sh
# trivy, as the trivy jobs of publish.yml and linter-helm.yml call it: in a
# throwaway container of its latest release, run from the repository root.
#
# trivy is not pinned, so that a scan gets its newest detections, and therefore
# must be able to do no more than anyone on the internet. A process of the job
# itself could do more: the runners grant passwordless sudo, which reads the
# memory of the runner, holding the job's GitHub token and the runtime token
# that writes the Actions cache other workflows restore. The container reaches
# no host process, no checkout, no token and no capability: it sees scan/ (its
# inputs and its reports), the trivy configuration, read-only, and its own
# cache, the vulnerability databases.
#
# TRIVY_IMAGE overrides the image; the "Set up trivy" steps pull it once, so
# that every call of a job runs the same release.
set -eu

cache=${XDG_CACHE_HOME:-$HOME/.cache}/trivy
mkdir -p "$cache" scan

exec docker run --rm \
  --user "$(id -u):$(id -g)" \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --read-only --tmpfs /tmp \
  --env TRIVY_CACHE_DIR=/cache \
  --env TRIVY_DISABLE_TELEMETRY \
  --env TRIVY_SKIP_VERSION_CHECK \
  --env TRIVY_NO_PROGRESS \
  --volume "$cache:/cache" \
  --volume "$PWD/scan:$PWD/scan" \
  --volume "$PWD/.github/trivy.yaml:$PWD/.github/trivy.yaml:ro" \
  --workdir "$PWD" \
  "${TRIVY_IMAGE:-ghcr.io/aquasecurity/trivy:latest}" "$@"
