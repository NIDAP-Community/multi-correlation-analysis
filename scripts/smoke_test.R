# This deterministic fixture exercises duplicate handling, sample metadata,
# category output, p-value/FDR output, and the portable heatmap artifact.
script_argument <- commandArgs(FALSE)
script_file <- sub("^--file=", "", script_argument[grepl("^--file=", script_argument)][1])
script_path <- if (!is.na(script_file) && nzchar(script_file)) normalizePath(script_file) else normalizePath("scripts/smoke_test.R")
project_dir <- dirname(dirname(script_path))
source(file.path(project_dir, "R", "multi_correlation.R"))

# The circle view must use a monotonic inverse p-value scale: stronger evidence
# yields a larger bubble score, while a larger p-value yields a smaller score.
p_value_scores <- p_value_score(c(0.5, 0.05, 0.01, 0.001))
if (!all(diff(p_value_scores) > 0)) {
  stop("P-value bubble scale is not monotonically inverse to raw p-value.")
}
output_dir <- file.path(tempdir(), "multi-correlation-smoke")
unlink(output_dir, recursive = TRUE)
summary <- run_multi_correlation(
  counts = read_table_auto(file.path(project_dir, "test_data", "counts.tsv")),
  metadata = read_table_auto(file.path(project_dir, "test_data", "metadata.tsv")),
  gene_column = "Gene", sample_column = "SampleID",
  genes = c("ESR1", "PGR", "ERBB2", "MKI67", "GATA3"),
  category_column = "Subtype", categories = c("Luminal", "HER2", "all"),
  duplicate_policy = "sum", correlation_method = "spearman", update_genes = FALSE,
  heatmap_style = "circle", output_dir = output_dir)
required <- c("analysis_summary.tsv", "Luminal_correlation_matrix.tsv",
              "Luminal_p_value_matrix.tsv", "Luminal_fdr_matrix.tsv",
              "Luminal_correlation_heatmap.png", "all_correlation_heatmap.png")
missing <- required[!file.exists(file.path(output_dir, required))]
if (length(missing)) stop("Smoke test missing artifacts: ", paste(missing, collapse = ", "))
if (!all(summary$status == "complete")) stop("Smoke test categories did not complete.")
# The alternate square rendering must remain a supported public interface.
square_output_dir <- file.path(tempdir(), "multi-correlation-smoke-square")
square_summary <- run_multi_correlation(
  counts = read_table_auto(file.path(project_dir, "test_data", "counts.tsv")),
  metadata = read_table_auto(file.path(project_dir, "test_data", "metadata.tsv")),
  gene_column = "Gene", sample_column = "SampleID",
  genes = c("ESR1", "PGR", "ERBB2", "MKI67", "GATA3"),
  category_column = "Subtype", categories = c("all"), duplicate_policy = "sum",
  correlation_method = "spearman", update_genes = FALSE, heatmap_style = "square",
  output_dir = square_output_dir)
if (!file.exists(file.path(square_output_dir, "all_correlation_heatmap.png")) ||
    square_summary$status[[1]] != "complete") {
  stop("Square heatmap smoke test did not complete.")
}
# The documented default duplicate policy also needs to preserve sample names.
max_output_dir <- file.path(tempdir(), "multi-correlation-smoke-max")
max_summary <- run_multi_correlation(
  counts = read_table_auto(file.path(project_dir, "test_data", "counts.tsv")),
  metadata = read_table_auto(file.path(project_dir, "test_data", "metadata.tsv")),
  gene_column = "Gene", sample_column = "SampleID",
  genes = c("ESR1", "PGR", "ERBB2", "MKI67", "GATA3"),
  category_column = "Subtype", categories = c("all"), update_genes = FALSE,
  output_dir = max_output_dir)
if (!file.exists(file.path(max_output_dir, "all_correlation_heatmap.png")) ||
    max_summary$status[[1]] != "complete") {
  stop("Default max-duplicate smoke test did not complete.")
}
message("Smoke test passed. Artifacts: ", output_dir)
