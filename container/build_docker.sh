#!/usr/bin/env bash
# Build a locally usable linux/amd64 image, matching the OncoChat runtime ABI.
set -euo pipefail
script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(CDPATH= cd -- "${script_dir}/.." && pwd)"
image_tag="${1:-multi-correlation-analysis:local}"
vcs_ref="$(git -C "${project_dir}" rev-parse HEAD 2>/dev/null || printf unknown)"
build_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
args=(--file "${project_dir}/container/Dockerfile" --load --platform linux/amd64 --tag "${image_tag}"
      --build-arg "VCS_REF=${vcs_ref}" --build-arg "BUILD_DATE=${build_date}")
if [[ -n "${DOCKER_CA_CERT:-}" ]]; then
  [[ -r "${DOCKER_CA_CERT}" ]] || { printf 'DOCKER_CA_CERT is not a readable PEM file: %s\n' "${DOCKER_CA_CERT}" >&2; exit 2; }
  args+=(--secret "id=build_ca,src=${DOCKER_CA_CERT}")
fi
docker buildx build "${args[@]}" "${project_dir}"
