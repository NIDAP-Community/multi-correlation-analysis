#!/usr/bin/env bash
# Invoke an R script without a project autoloader; safe for noninteractive use.
set -euo pipefail

# When a developer has restored the tracked renv lockfile, make that project
# library visible without enabling an interactive .Rprofile autoloader.
script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(CDPATH= cd -- "${script_dir}/.." && pwd)"
renv_package_dir="$(find "${project_dir}/renv/library" -maxdepth 4 -type d -name renv -print -quit 2>/dev/null || true)"
if [[ -n "${renv_package_dir}" ]]; then
  project_library="$(dirname "${renv_package_dir}")"
  export R_LIBS_USER="${project_library}${R_LIBS_USER:+:${R_LIBS_USER}}"
fi
export RENV_CONFIG_AUTOLOADER_ENABLED=FALSE
exec Rscript --vanilla "$@"
