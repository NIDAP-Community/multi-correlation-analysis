# Decision log

## 2026-10-25 — Initial standalone implementation

- Repository name: `multi-correlation-analysis`.
- Keep it distinct from `multi-gene-correlations`; the latter is signature-centric, while this application produces a gene-by-gene correlation matrix.
- Preserve Template Hub v5 inputs (`Normalized_Counts`, `Sample_Metadata`, gene/sample/category selection, selected samples, and duplicate policy) while adding explicit validation and persistent output artifacts.
- Default to Spearman correlation for a robust cross-platform rank association; allow Pearson as an explicit option.
- Default duplicate policy remains `max` for compatibility with the original template, while documenting `sum` for RNA-seq counts.
- Package an AMD64 OCI image and postpone GHCR publication until local image validation is complete.

## 2026-10-25 — Local reproducibility and distribution contract

- Track `renv.lock` and the `renv/` activation metadata, but do not track a project library or auto-activate it through `.Rprofile`.
- Pin L2P by its published tarball URL because it is installed from source rather than a CRAN repository.
- Support HPC execution by pulling the OCI image into Apptainer/Singularity; do not commit container binaries or source data.
- After the first Git commit, rebuild the OCI image so `org.opencontainers.image.revision` records the real source revision.
