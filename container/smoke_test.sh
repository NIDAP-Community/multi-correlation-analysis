#!/usr/bin/env bash
# Exercise the container's public CLI and ensure its required portable outputs.
set -euo pipefail
script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(CDPATH= cd -- "${script_dir}/.." && pwd)"
image_tag="${1:-multi-correlation-analysis:local}"
root="$(mktemp -d "${TMPDIR:-/tmp}/multi-correlation-container-smoke.XXXXXX")"
output_dir="${root}/output"
"${script_dir}/run_docker.sh" "${image_tag}" "${project_dir}/test_data" "${output_dir}" \
  --counts /data/counts.tsv --metadata /data/metadata.tsv --gene-column Gene \
  --sample-column SampleID --genes "ESR1,PGR,ERBB2,MKI67,GATA3" \
  --category-column Subtype --categories "Luminal,HER2,all" --duplicate-policy sum \
  --update-genes false --output-dir /output
for path in analysis_summary.tsv run_parameters.tsv all_correlation_matrix.tsv all_correlation_heatmap.png; do
  [[ -s "${output_dir}/${path}" ]] || { printf 'Missing container artifact: %s\n' "${path}" >&2; exit 1; }
done
printf 'Container smoke test passed. Artifacts retained at: %s\n' "${output_dir}"
