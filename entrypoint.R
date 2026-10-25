#!/usr/bin/env Rscript

# Command-line adapter for a portable counts-plus-metadata correlation run.
`%||%` <- function(left, right) if (is.null(left) || !length(left) || is.na(left)) right else left
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0L || any(args %in% c("--help", "-h"))) {
  cat("Multi-Correlation Analysis\n\n",
      "Required: --counts FILE --metadata FILE --gene-column NAME --sample-column NAME\n",
      "          --genes GENE1,GENE2 --category-column NAME --categories VALUE1,VALUE2\n\n",
      "Optional: --samples ID1,ID2 --duplicate-policy sum|max --correlation-method pearson|spearman\n",
      "          --min-samples 3 --update-genes true|false --heatmap-style circle|square\n",
      "          --show-significance true|false (show circle p-value-size key)\n",
      "          --output-dir DIRECTORY\n", sep = "")
  quit(status = 0)
}

parse_options <- function(arguments) {
  output <- list()
  i <- 1L
  while (i <= length(arguments)) {
    argument <- arguments[[i]]
    if (!startsWith(argument, "--")) stop("Unexpected argument: ", argument)
    key_value <- sub("^--", "", argument)
    if (grepl("=", key_value, fixed = TRUE)) {
      pieces <- strsplit(key_value, "=", fixed = TRUE)[[1]]
      output[[pieces[[1]]]] <- paste(pieces[-1], collapse = "=")
    } else {
      if (i == length(arguments) || startsWith(arguments[[i + 1L]], "--")) stop("Missing value for --", key_value)
      output[[key_value]] <- arguments[[i + 1L]]
      i <- i + 1L
    }
    i <- i + 1L
  }
  output
}

script_argument <- commandArgs(FALSE)
script_file <- sub("^--file=", "", script_argument[grepl("^--file=", script_argument)][1])
script_dir <- if (!is.na(script_file) && nzchar(script_file)) dirname(normalizePath(script_file)) else getwd()
source(file.path(script_dir, "R", "multi_correlation.R"))
options <- parse_options(args)
options$`heatmap-style` <- tolower(options$`heatmap-style` %||% "circle")
options$`show-significance` <- parse_bool(options$`show-significance` %||% "true")
required <- c("counts", "metadata", "gene-column", "sample-column", "genes", "category-column", "categories")
missing <- required[!required %in% names(options)]
if (length(missing)) stop("Missing required options: ", paste(paste0("--", missing), collapse = ", "))

counts <- read_table_auto(options$counts)
metadata <- read_table_auto(options$metadata)
summary <- run_multi_correlation(
  counts = counts, metadata = metadata, gene_column = options$`gene-column`,
  sample_column = options$`sample-column`, genes = parse_list(options$genes),
  category_column = options$`category-column`, categories = parse_list(options$categories),
  samples = parse_list(options$samples %||% ""), duplicate_policy = options$`duplicate-policy` %||% "max",
  correlation_method = options$`correlation-method` %||% "spearman",
  min_samples = as.integer(options$`min-samples` %||% 3L),
  update_genes = parse_bool(options$`update-genes` %||% "true"),
  heatmap_style = options$`heatmap-style`,
  show_significance = options$`show-significance`,
  output_dir = options$`output-dir` %||% "/output")
utils::write.table(data.frame(option = names(options), value = unlist(options, use.names = FALSE)),
                   file.path(options$`output-dir` %||% "/output", "run_parameters.tsv"),
                   sep = "\t", quote = FALSE, row.names = FALSE)
print(summary, row.names = FALSE)
