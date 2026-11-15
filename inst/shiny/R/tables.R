# The data behind the app's downloads and charts, from asDataFrame() tables: the key columns ((Taxon,) Module),
# Description, then one column per sample.

# the sample columns of a table
sampleColumns <- function(table) {
  colnames(table)[-seq_len(match("Description", colnames(table)))]
}

# one row per sample and reported (taxon,) module: Sample, (Taxon,) Module, Description, Abundance, Coverage. A module
# below the cutoff in a sample is 0 in the tables, and left out here.
longTable <- function(abundance, coverage) {
  keys <- colnames(abundance)[seq_len(match("Description", colnames(abundance)))]
  long <- do.call(rbind, lapply(sampleColumns(abundance), function(sample) {
    data.frame(
      Sample = rep(sample, nrow(abundance)), abundance[keys], Abundance = abundance[[sample]],
      Coverage = coverage[[sample]], check.names = FALSE, row.names = NULL
    )
  }))
  long[long$Coverage > 0, , drop = FALSE]
}

# the coverage distribution omixer-rpm learns the cutoff from, from the coverage table of a run with cutoff 0: every
# observed coverage (> 0, of a module in a profile), highest first, with the number of observations at or above it
coverageDistribution <- function(coverage) {
  values <- unlist(coverage[sampleColumns(coverage)], use.names = FALSE)
  values <- values[values > 0]
  points <- sort(unique(values), decreasing = TRUE)
  data.frame(coverage = points, kept = cumsum(tabulate(match(values, points), length(points))))
}

# the rows with the highest mean value (abundance: log10, 0 = not reported), ordered by similarity; a matrix with a
# label per row and a column per sample, NA where the module is not reported
heatmapMatrix <- function(table, top, log = FALSE) {
  values <- as.matrix(table[sampleColumns(table)])
  values[values == 0] <- NA
  if (log) {
    values <- log10(values)
  }
  module <- paste(table$Module, table$Description)
  rownames(values) <- if ("Taxon" %in% colnames(table)) paste0(table$Taxon, ": ", module) else module
  means <- rowMeans(values, na.rm = TRUE)
  values <- values[order(-ifelse(is.nan(means), -Inf, means))[seq_len(min(top, nrow(values)))], , drop = FALSE]
  if (nrow(values) > 2) {
    distances <- dist(ifelse(is.na(values), min(values, na.rm = TRUE) - 1, values))
    values <- values[hclust(distances)$order, , drop = FALSE]
  }
  values
}

# the modules of a per-taxon table that some taxon carries, highest total abundance first, as select choices
taxonModules <- function(abundance) {
  totals <- rowsum(rowSums(as.matrix(abundance[sampleColumns(abundance)])), abundance$Module)[, 1]
  totals <- sort(totals[totals > 0], decreasing = TRUE)
  descriptions <- abundance$Description[match(names(totals), abundance$Module)]
  stats::setNames(names(totals), paste(names(totals), descriptions))
}

# the abundance of a module per taxon (rows: the `top` taxa with the highest total, then the rest as "Other taxa") and
# sample (columns), and each taxon's share of the sample's sum (0 in a sample without the module)
taxonShares <- function(abundance, module, top = 8) {
  rows <- abundance[abundance$Module == module, , drop = FALSE]
  values <- as.matrix(rows[sampleColumns(abundance)])
  rownames(values) <- rows$Taxon
  values <- values[order(-rowSums(values)), , drop = FALSE]
  values <- values[rowSums(values) > 0, , drop = FALSE]
  if (nrow(values) > top) {
    rest <- values[-seq_len(top), , drop = FALSE]
    values <- rbind(values[seq_len(top), , drop = FALSE], "Other taxa" = colSums(rest))
  }
  sums <- colSums(values)
  shares <- sweep(values, 2, ifelse(sums > 0, sums, 1), "/")
  list(abundance = values, shares = shares)
}

# the links between the `taxa` taxa and `modules` modules with the highest abundance in a per-taxon table: a module's
# abundance in a taxon, in one sample or summed over all samples (sample = ""). Highest first; with the share of the
# table's total abundance they hold.
chordLinks <- function(abundance, sample = "", taxa = 15, modules = 15) {
  samples <- if (nzchar(sample)) sample else sampleColumns(abundance)
  value <- rowSums(as.matrix(abundance[samples]))
  links <- data.frame(taxon = abundance$Taxon, module = abundance$Module, value = value)[value > 0, ]
  top <- function(names, n) {
    totals <- sort(tapply(links$value, names, sum), decreasing = TRUE)
    names(totals)[seq_len(min(n, length(totals)))]
  }
  topTaxa <- top(links$taxon, taxa)
  topModules <- top(links$module, modules)
  shown <- links[links$taxon %in% topTaxa & links$module %in% topModules, ]
  shown <- shown[order(match(shown$taxon, topTaxa), match(shown$module, topModules)), ]
  list(
    links = shown,
    taxa = topTaxa[topTaxa %in% shown$taxon],
    modules = topModules[topModules %in% shown$module],
    share = if (nrow(links) > 0) sum(shown$value) / sum(links$value) else 0
  )
}
