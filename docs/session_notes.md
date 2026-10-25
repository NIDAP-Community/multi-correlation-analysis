# Session notes

## 2026-10-25

Initial local scaffold created from the released Multi-Correlation Template Hub v5 behavior. The local R core and CLI fixture passed, producing all expected category-specific tables and heatmaps. On 2026-10-25, the user completed the AMD64 OCI image build and `container/smoke_test.sh`; the container successfully produced complete Luminal, HER2, and pooled (`all`) results and passed its portable artifact assertions. A README figure was then generated from a local public TCGA-PRAD normalized-expression snapshot using the documented seven-gene panel; only the derived PNG and provenance record were added.

Pre-push parity review against `multi-gene-correlations` added the standard local `renv` contract, an explicit L2P package URL record, stronger data/output ignore rules, local-R and HPC/Apptainer documentation, template provenance, research-use notice, and pre-release version metadata. Local L2P restoration is pending a configured macOS compiler toolchain; the container installation remains the validated route.

The public source repository was created at `NIDAP-Community/multi-correlation-analysis` from commit `52f5c9f`. Its initial GitHub Actions `validate` workflow and GitHub-provided CodeQL setup both completed successfully. The validated runtime image built from `52f5c9f` was published publicly to GHCR as `v0.1.0`, `latest`, and `52f5c9f`, all at digest `sha256:30fb2057871e40949d36634963f3fef5966d57ee059b7bbe6fb389c95b0bc37a`. GitHub recognizes `NIDAP-Community/multi-correlation-analysis` as the package source, and the package inherits the source repository's access settings.
