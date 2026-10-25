# Changelog

## 0.1.1 — 2026-10-25

- Adds a selectable correlation-heatmap style: the circle/bubble view is now the default, and `--heatmap-style square` retains the colored-square alternative.
- In the default circle/bubble view, circle area now encodes inverse raw p-value, color encodes signed correlation, and printed labels retain the correlation coefficient. An in-plot size key can be hidden explicitly.
- Fixes the default `max` duplicate-gene policy so its representative row retains the original sample-column names.

## 0.1.0 — 2026-10-25

- Initial standalone implementation of category-specific gene-gene correlation analysis.
- Adds L2P-assisted gene normalization, duplicate-gene policies, correlation/p-value/FDR matrices, heatmaps, a fixture smoke test, and an AMD64 OCI container contract.
- Published the validated AMD64 OCI image to GHCR with `v0.1.0`, `latest`, and immutable source tag `52f5c9f`.
