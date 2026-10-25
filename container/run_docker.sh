#!/usr/bin/env bash
# Run the OCI image using explicit read-only input and writable output mounts.
set -euo pipefail
image_tag="${1:-multi-correlation-analysis:local}"
data_dir="${2:?Provide a data directory}"
output_dir="${3:?Provide an output directory}"
shift 3
mkdir -p "${output_dir}"
docker run --rm --platform linux/amd64 \
  --user "$(id -u):$(id -g)" \
  -v "$(cd "${data_dir}" && pwd):/data:ro" \
  -v "$(cd "${output_dir}" && pwd):/output" \
  "${image_tag}" "$@"
