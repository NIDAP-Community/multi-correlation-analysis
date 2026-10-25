# Core routines for the standalone Multi-Correlation Analysis application.
#
# Input counts are a wide table: one gene identifier column followed by one
# numeric expression column per sample. Metadata supplies the sample IDs and a
# user-selected category column used to make separate correlation analyses.

read_table_auto <- function(path) {
  if (!file.exists(path)) stop("Input file does not exist: ", path)
  extension <- tolower(tools::file_ext(path))
  if (extension %in% c("tsv", "txt")) {
    utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
  } else {
    utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  }
}

parse_list <- function(value) {
  if (is.null(value) || !length(value) || !nzchar(value)) return(character())
  if (file.exists(value)) {
    values <- trimws(readLines(value, warn = FALSE))
    return(values[nzchar(values)])
  }
  values <- trimws(strsplit(value, ",", fixed = TRUE)[[1]])
  values[nzchar(values)]
}

parse_bool <- function(value, default = FALSE) {
  if (is.null(value) || !length(value) || !nzchar(value)) return(default)
  value <- tolower(value)
  if (value %in% c("true", "t", "1", "yes", "y")) return(TRUE)
  if (value %in% c("false", "f", "0", "no", "n")) return(FALSE)
  stop("Expected a Boolean value, received: ", value)
}

resolve_column <- function(columns, requested, input_name) {
  matches <- columns[tolower(columns) == tolower(requested)]
  if (!length(matches)) {
    stop("Column '", requested, "' was not found in ", input_name,
         ". Available columns: ", paste(columns, collapse = ", "))
  }
  matches[[1]]
}

safe_name <- function(value) {
  result <- gsub("[^A-Za-z0-9_-]+", "_", value)
  result <- gsub("^_+|_+$", "", result)
  ifelse(nzchar(result), result, "unnamed_category")
}

normalize_genes <- function(genes, use_l2p = TRUE) {
  genes <- unique(trimws(genes[nzchar(genes)]))
  report <- data.frame(input_gene = genes, normalized_gene = genes,
                       method = "identity", stringsAsFactors = FALSE)
  if (!use_l2p || !length(genes)) return(report)

  if (!requireNamespace("l2p", quietly = TRUE)) {
    warning("l2p is unavailable; retaining supplied gene symbols.")
    return(report)
  }

  updated <- tryCatch(l2p::updategenes(genes), error = function(e) e)
  if (inherits(updated, "error") || !"newname" %in% names(updated)) {
    warning("l2p gene-symbol update failed; retaining supplied symbols.")
    return(report)
  }
  report$normalized_gene <- ifelse(is.na(updated$newname) | !nzchar(updated$newname),
                                   report$input_gene, updated$newname)
  report$method <- "l2p::updategenes"
  report
}

deduplicate_counts <- function(counts, gene_column, sample_columns, policy) {
  selected <- counts[, c(gene_column, sample_columns), drop = FALSE]
  selected[[gene_column]] <- trimws(as.character(selected[[gene_column]]))
  selected <- selected[!is.na(selected[[gene_column]]) &
                       nzchar(selected[[gene_column]]) &
                       selected[[gene_column]] != "---", , drop = FALSE]
  for (sample in sample_columns) {
    selected[[sample]] <- suppressWarnings(as.numeric(selected[[sample]]))
  }
  if (!nrow(selected)) stop("No usable gene rows remain after identifier filtering.")

  if (!anyDuplicated(selected[[gene_column]])) return(selected)
  groups <- split(seq_len(nrow(selected)), selected[[gene_column]])
  collapsed <- lapply(names(groups), function(gene) {
    rows <- selected[groups[[gene]], sample_columns, drop = FALSE]
    values <- if (policy == "sum") {
      vapply(rows, function(x) sum(x, na.rm = TRUE), numeric(1))
    } else {
      totals <- rowSums(rows, na.rm = TRUE)
      as.numeric(rows[which.max(totals), , drop = TRUE])
    }
    data.frame(gene = gene, t(values), check.names = FALSE, stringsAsFactors = FALSE)
  })
  collapsed <- do.call(rbind, collapsed)
  names(collapsed)[1] <- gene_column
  rownames(collapsed) <- NULL
  collapsed
}

correlation_statistics <- function(sample_by_gene, method) {
  gene_count <- ncol(sample_by_gene)
  correlation <- stats::cor(sample_by_gene, method = method, use = "pairwise.complete.obs")
  p_value <- matrix(NA_real_, gene_count, gene_count,
                    dimnames = list(colnames(sample_by_gene), colnames(sample_by_gene)))
  diag(p_value) <- 0
  for (i in seq_len(gene_count - 1L)) {
    for (j in (i + 1L):gene_count) {
      pair <- stats::complete.cases(sample_by_gene[, i], sample_by_gene[, j])
      value <- if (sum(pair) >= 3L &&
                   stats::sd(sample_by_gene[pair, i]) > 0 &&
                   stats::sd(sample_by_gene[pair, j]) > 0) {
        tryCatch(stats::cor.test(sample_by_gene[pair, i], sample_by_gene[pair, j],
                                 method = method, exact = FALSE)$p.value,
                 error = function(e) NA_real_)
      } else NA_real_
      p_value[i, j] <- value
      p_value[j, i] <- value
    }
  }
  fdr <- matrix(NA_real_, gene_count, gene_count, dimnames = dimnames(p_value))
  diag(fdr) <- 0
  upper <- upper.tri(p_value)
  fdr[upper] <- stats::p.adjust(p_value[upper], method = "BH")
  fdr[lower.tri(fdr)] <- t(fdr)[lower.tri(fdr)]
  list(correlation = correlation, p_value = p_value, fdr = fdr)
}

ordered_correlation <- function(correlation) {
  if (nrow(correlation) < 3L || any(!is.finite(correlation))) return(seq_len(nrow(correlation)))
  tryCatch(stats::hclust(stats::as.dist(1 - correlation))$order,
           error = function(e) seq_len(nrow(correlation)))
}

write_matrix_tsv <- function(matrix, path) {
  output <- data.frame(gene = rownames(matrix), matrix, check.names = FALSE)
  utils::write.table(output, path, sep = "\t", quote = FALSE, row.names = FALSE)
}

plot_heatmap <- function(correlation, title, path) {
  grDevices::png(path, width = 1800, height = 1600, res = 220)
  on.exit(grDevices::dev.off(), add = TRUE)
  if (requireNamespace("corrplot", quietly = TRUE)) {
    corrplot::corrplot(correlation, method = "color", type = "upper", order = "original",
                       addCoef.col = "black", number.cex = 0.65, tl.col = "black",
                       tl.srt = 45, mar = c(1, 1, 3, 1), title = title)
  } else {
    stats::heatmap(correlation, symm = TRUE, col = grDevices::colorRampPalette(
      c("#2166AC", "#F7F7F7", "#B2182B"))(100), main = title)
  }
}

run_multi_correlation <- function(counts, metadata, gene_column, sample_column,
                                  genes, category_column, categories,
                                  samples = character(), duplicate_policy = "max",
                                  correlation_method = "spearman", min_samples = 3L,
                                  update_genes = TRUE, output_dir = ".") {
  if (!duplicate_policy %in% c("sum", "max")) stop("duplicate_policy must be 'sum' or 'max'.")
  if (!correlation_method %in% c("pearson", "spearman")) stop("correlation_method must be pearson or spearman.")
  if (min_samples < 3L) stop("min_samples must be at least 3.")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  gene_column <- resolve_column(names(counts), gene_column, "counts")
  sample_column <- resolve_column(names(metadata), sample_column, "metadata")
  category_column <- resolve_column(names(metadata), category_column, "metadata")
  metadata[[sample_column]] <- as.character(metadata[[sample_column]])
  available_samples <- intersect(names(counts)[names(counts) != gene_column], metadata[[sample_column]])
  selected_samples <- if (length(samples)) intersect(samples, available_samples) else available_samples
  if (!length(selected_samples)) stop("No count-table sample columns match the selected metadata samples.")
  metadata <- metadata[metadata[[sample_column]] %in% selected_samples, , drop = FALSE]
  metadata <- metadata[match(selected_samples, metadata[[sample_column]]), , drop = FALSE]

  requested <- normalize_genes(genes, use_l2p = update_genes)
  utils::write.table(requested, file.path(output_dir, "gene_normalization.tsv"), sep = "\t",
                     quote = FALSE, row.names = FALSE)
  normalized_genes <- unique(requested$normalized_gene)
  counts <- deduplicate_counts(counts, gene_column, selected_samples, duplicate_policy)
  rownames(counts) <- counts[[gene_column]]
  present_genes <- intersect(normalized_genes, rownames(counts))
  missing_genes <- setdiff(normalized_genes, present_genes)
  if (length(present_genes) < 2L) stop("Fewer than two requested genes are present after normalization and filtering.")
  utils::write.table(data.frame(gene = missing_genes), file.path(output_dir, "missing_genes.tsv"),
                     sep = "\t", quote = FALSE, row.names = FALSE)

  if (!length(categories) || any(tolower(categories) == "all")) {
    requested_categories <- unique(c(setdiff(categories, "all"), "all"))
  } else requested_categories <- categories
  summary_rows <- list()
  for (category in requested_categories) {
    category_samples <- if (tolower(category) == "all") selected_samples else {
      intersect(selected_samples, metadata[[sample_column]][metadata[[category_column]] == category])
    }
    status <- "complete"
    if (length(category_samples) < min_samples) status <- "insufficient_samples"
    if (status == "complete") {
      expression <- as.matrix(counts[present_genes, category_samples, drop = FALSE])
      sample_by_gene <- t(expression)
      colnames(sample_by_gene) <- present_genes
      variable <- vapply(seq_len(ncol(sample_by_gene)), function(i) {
        sum(is.finite(sample_by_gene[, i])) >= min_samples && stats::sd(sample_by_gene[, i], na.rm = TRUE) > 0
      }, logical(1))
      if (sum(variable) < 2L) {
        status <- "fewer_than_two_variable_genes"
      } else {
        sample_by_gene <- sample_by_gene[, variable, drop = FALSE]
        statistics <- correlation_statistics(sample_by_gene, correlation_method)
        order <- ordered_correlation(statistics$correlation)
        statistics <- lapply(statistics, function(x) x[order, order, drop = FALSE])
        prefix <- file.path(output_dir, safe_name(category))
        write_matrix_tsv(statistics$correlation, paste0(prefix, "_correlation_matrix.tsv"))
        write_matrix_tsv(statistics$p_value, paste0(prefix, "_p_value_matrix.tsv"))
        write_matrix_tsv(statistics$fdr, paste0(prefix, "_fdr_matrix.tsv"))
        plot_heatmap(statistics$correlation,
                     sprintf("Gene correlation: %s (n = %d)", category, length(category_samples)),
                     paste0(prefix, "_correlation_heatmap.png"))
      }
    }
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      category = category, n_samples = length(category_samples), n_requested_genes = length(normalized_genes),
      n_present_genes = length(present_genes), n_missing_genes = length(missing_genes), status = status,
      stringsAsFactors = FALSE)
  }
  summary <- do.call(rbind, summary_rows)
  utils::write.table(summary, file.path(output_dir, "analysis_summary.tsv"), sep = "\t",
                     quote = FALSE, row.names = FALSE)
  invisible(summary)
}
