# TCGA-PRAD seven-gene panel example

## Purpose

This record documents the real-data figure displayed in the repository README. It demonstrates the category-specific correlation workflow only; it is not intended as a clinical, diagnostic, or prognostic analysis.

## Public source and inputs

- Study: [The Cancer Genome Atlas Prostate Adenocarcinoma (TCGA-PRAD)](https://portal.gdc.cancer.gov/projects/TCGA-PRAD).
- Input type: normalized bulk RNA-seq expression with a gene-symbol column, plus matching sample metadata.
- Input data are not committed to this repository. The README contains only a derived correlation heatmap.

## Run configuration

- Genes: `AR, FOXA1, KLK2, KLK3, NKX3-1, TMPRSS2, ERG`.
- Correlation: Spearman, pairwise complete observations.
- Duplicate policy: `max` (no duplicate rows occurred for this panel in the source snapshot).
- L2P updating: disabled because the source rows already used the requested current symbols.
- Categories: primary tumor (`TP`), normal tissue (`NT`), and pooled (`all`).

After matching metadata IDs to count-table columns, the run contained 496 `TP` samples, 52 `NT` samples, and 549 pooled matched samples. The pooled set includes every matched metadata category; it should not be interpreted as a tumor-only analysis.

## Reproduction command

Set the two paths to locally obtained TCGA-PRAD files, then run:

```bash
Rscript --vanilla entrypoint.R \
  --counts "$TCGA_PRAD_NORMALIZED_COUNTS" \
  --metadata "$TCGA_PRAD_SAMPLE_METADATA" \
  --gene-column Gene \
  --sample-column sample2 \
  --genes "AR,FOXA1,KLK2,KLK3,NKX3-1,TMPRSS2,ERG" \
  --category-column samptype \
  --categories "TP,NT,all" \
  --duplicate-policy max \
  --correlation-method spearman \
  --update-genes false \
  --heatmap-style circle \
  --output-dir results/tcga-prad-seven-gene-panel
```

The identical analysis was also run with `--heatmap-style square` into a separate output directory. In the default circle figure, circle area encodes inverse raw p-value, color encodes signed correlation, and the printed number is the correlation coefficient. The README contains the derived pooled-category figure from each run and no input data. The full output contract also includes category-specific correlation, p-value, and Benjamini-Hochberg FDR matrices.
