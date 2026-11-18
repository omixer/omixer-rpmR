# The app's charts. Each *Chart() function returns a ggplot2 chart (also usable on its own, e.g. in a paper); the app
# shows it with plotly::ggplotly(tooltip = "text"), so the `text` aesthetic is the tooltip. The chord diagram is d3
# (chord.js), fed by chordData().

ink <- list(
  primary = "#0b0b0b", secondary = "#52514e", muted = "#898781", grid = "#e1e0d9", axis = "#c3c2b7",
  surface = "#ffffff", missing = "#f0efec"
)
# categorical slots in their fixed order (validated: adjacent pairs colorblind-safe), and the neutral for the rest
series <- c("#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300", "#6250d6", "#e34948")
other <- "#898781"
# sequential blue, light (low) to dark (high)
ramp <- c(
  "#cde2fb", "#b7d3f6", "#9ec5f4", "#86b6ef", "#6da7ec", "#5598e7", "#3987e5", "#2a78d6", "#256abf",
  "#1c5cab", "#184f95", "#104281", "#0d366b"
)

# hairline grid, recessive axes, text in the ink colours
chartTheme <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", colour = ink$primary),
      plot.subtitle = ggplot2::element_text(colour = ink$secondary),
      plot.title.position = "plot",
      axis.text = ggplot2::element_text(colour = ink$muted),
      axis.title = ggplot2::element_text(colour = ink$secondary),
      legend.text = ggplot2::element_text(colour = ink$secondary),
      legend.title = ggplot2::element_text(colour = ink$secondary),
      panel.grid.major = ggplot2::element_line(colour = ink$grid, linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank()
    )
}

emptyChart <- function(message) {
  ggplot2::ggplot() +
    ggplot2::annotate("text", x = 0, y = 0, label = message, colour = ink$secondary) +
    ggplot2::theme_void()
}

shorten <- function(labels, width) {
  ifelse(nchar(labels) > width, paste0(substr(labels, 1, width - 1), "…"), labels)
}

# the x axis labels: vertical sample names, left out above 60 samples (the tooltips name them)
sampleAxis <- function(samples) {
  if (samples <= 60) {
    ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5)
  } else {
    ggplot2::element_blank()
  }
}

# the module observations kept at each coverage cutoff (coverageDistribution()), and the cutoff of the run
coverageChart <- function(points, cutoff, automatic) {
  if (nrow(points) == 0) {
    return(emptyChart("No module was observed."))
  }
  ascending <- points[order(points$coverage), ]
  ascending$text <- sprintf("Cutoff %s keeps %d module observations", signif(ascending$coverage, 3), ascending$kept)
  # below the lowest observed coverage, every observation is kept
  step <- data.frame(coverage = c(0, ascending$coverage), kept = c(max(points$kept), ascending$kept))
  top <- max(points$kept) * 1.08
  chart <- ggplot2::ggplot(ascending, ggplot2::aes(coverage, kept)) +
    ggplot2::geom_step(data = step, direction = "vh", colour = series[1], linewidth = 0.7) +
    # ggplot2 does not know the `text` aesthetic (only plotly reads it) and would warn on every chart
    suppressWarnings(ggplot2::geom_point(ggplot2::aes(text = text),
      shape = 21, fill = series[1], colour = ink$surface, size = 3, stroke = 1
    )) +
    ggplot2::scale_x_continuous("Coverage cutoff", limits = c(0, 1), breaks = seq(0, 1, 0.2), expand = c(0, 0.01)) +
    ggplot2::scale_y_continuous("Module observations kept", limits = c(0, top), expand = c(0, 0)) +
    ggplot2::labs(
      title = "Module observations kept at each coverage cutoff",
      subtitle = if (automatic) "The learned cutoff is the coverage at the largest jump in observations kept"
    ) +
    chartTheme()
  if (!is.na(cutoff)) {
    label <- sprintf("%s %s", if (automatic) "learned cutoff" else "cutoff", format(cutoff))
    # beside the line, just below the top (plotly centres text on its position)
    chart <- chart +
      ggplot2::geom_vline(xintercept = cutoff, colour = ink$secondary, linewidth = 0.3) +
      ggplot2::annotate("text",
        x = cutoff + 0.01 + 0.012 * nchar(label) / 2, y = top * 0.96, label = label, colour = ink$primary
      )
  }
  chart
}

# rows (modules) by samples of a heatmapMatrix(), one blue from light (low) to dark (high); grey where a module is
# not reported. Abundance is on a log10 scale, coverage from 0 to 1.
heatmapChart <- function(values, log, title) {
  if (nrow(values) == 0 || all(is.na(values))) {
    return(emptyChart("No module is reported."))
  }
  cells <- data.frame(
    row = factor(rep(rownames(values), times = ncol(values)), levels = rev(rownames(values))),
    sample = factor(rep(colnames(values), each = nrow(values)), levels = colnames(values)),
    value = as.vector(values)
  )
  shown <- if (log) signif(10^cells$value, 4) else signif(cells$value, 3)
  cells$text <- sprintf(
    "%s<br>%s<br>%s", cells$sample, cells$row, ifelse(is.na(cells$value), "not reported", as.character(shown))
  )
  scale <- if (log) {
    ggplot2::scale_fill_gradientn("Abundance",
      colours = ramp, na.value = ink$missing,
      labels = function(breaks) format(signif(10^breaks, 2), big.mark = ",", scientific = FALSE, trim = TRUE)
    )
  } else {
    ggplot2::scale_fill_gradientn("Coverage", colours = ramp, na.value = ink$missing, limits = c(0, 1))
  }
  ggplot2::ggplot(cells, ggplot2::aes(sample, row, fill = value, text = text)) +
    ggplot2::geom_tile(colour = if (length(values) <= 3600) ink$surface else NA, linewidth = 0.6) +
    scale +
    ggplot2::scale_y_discrete(labels = function(labels) shorten(labels, 60)) +
    ggplot2::labs(title = title, subtitle = "Grey: not reported in that sample", x = NULL, y = NULL) +
    chartTheme() +
    ggplot2::theme(panel.grid.major = ggplot2::element_blank(), axis.text.x = sampleAxis(ncol(values)))
}

# each taxon's share of a module's per-taxon abundance, per sample (taxonShares()); the largest taxa in fixed
# colours from the bottom of the bar, the rest grey on top
taxaChart <- function(taxa, title) {
  shares <- taxa$shares
  if (ncol(shares) == 0 || nrow(shares) == 0) {
    return(emptyChart("No taxon carries this module."))
  }
  segments <- data.frame(
    taxon = factor(rep(rownames(shares), times = ncol(shares)), levels = rownames(shares)),
    sample = factor(rep(colnames(shares), each = nrow(shares)), levels = colnames(shares)),
    share = as.vector(shares), abundance = as.vector(taxa$abundance)
  )
  segments$text <- sprintf(
    "%s<br>%s: %.1f%%<br>abundance %g", segments$sample, segments$taxon, 100 * segments$share,
    signif(segments$abundance, 4)
  )
  fills <- stats::setNames(
    ifelse(rownames(shares) == "Other taxa", other, series[seq_len(nrow(shares))]), rownames(shares)
  )
  # bars at most about 24px wide on a chart about 900px wide
  width <- min(0.6, 24 / (900 / ncol(shares)))
  ggplot2::ggplot(segments, ggplot2::aes(sample, share, fill = taxon, text = text)) +
    ggplot2::geom_col(
      position = ggplot2::position_stack(reverse = TRUE), width = width, colour = ink$surface, linewidth = 0.4
    ) +
    ggplot2::scale_fill_manual(NULL, values = fills, guide = ggplot2::guide_legend(reverse = TRUE)) +
    ggplot2::scale_y_continuous(labels = function(x) paste0(100 * x, "%"), limits = c(0, 1), expand = c(0, 0)) +
    ggplot2::labs(
      title = title, x = NULL, y = NULL,
      subtitle = "Share of each taxon in the sum of the module's per-taxon abundances"
    ) +
    chartTheme() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(), axis.text.x = sampleAxis(ncol(shares)))
}

# the data of the d3 chord diagram (chord.js) for a chordLinks() result: the taxa then the modules, a symmetric matrix
# of the module's abundance in the taxon, labels for the circle and names for the tooltips
chordData <- function(chord, moduleNames) {
  sectors <- c(chord$taxa, chord$modules)
  matrix <- matrix(0, length(sectors), length(sectors), dimnames = list(sectors, sectors))
  links <- chord$links
  matrix[cbind(links$taxon, links$module)] <- links$value
  matrix[cbind(links$module, links$taxon)] <- links$value
  list(
    kinds = rep(c("taxon", "module"), c(length(chord$taxa), length(chord$modules))),
    labels = shorten(sectors, 28),
    names = c(chord$taxa, moduleNames),
    matrix = unname(matrix)
  )
}

# the colours of chord.js
chordColours <- list(
  taxon = ink$axis, module = ink$secondary, link = series[1], faded = ink$grid, text = ink$secondary,
  title = ink$primary, surface = ink$surface
)
