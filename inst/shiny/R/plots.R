# The app's charts, in base graphics (no packages beyond R). Each draws one plot region whose user coordinates the
# hover handlers in app.R read: x and y in data units.

ink <- list(
  primary = "#0b0b0b", secondary = "#52514e", muted = "#898781", grid = "#e1e0d9", axis = "#c3c2b7",
  surface = "#ffffff", missing = "#f0efec"
)
# categorical slots in their fixed order (validated: adjacent pairs colorblind-safe), and the neutral for the rest
series <- c("#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300", "#6250d6", "#e34948")
other <- "#898781"
# sequential blue, light (low) to dark (high)
ramp <- grDevices::colorRampPalette(c(
  "#cde2fb", "#b7d3f6", "#9ec5f4", "#86b6ef", "#6da7ec", "#5598e7", "#3987e5", "#2a78d6", "#256abf",
  "#1c5cab", "#184f95", "#104281", "#0d366b"
))(64)

chartPar <- function(mar) {
  graphics::par(
    mar = mar, family = "sans", las = 1, fg = ink$axis, col.axis = ink$muted, col.lab = ink$secondary,
    cex.axis = 0.85, mgp = c(2.6, 0.5, 0), tcl = -0.25, xpd = FALSE
  )
}

# title and subtitle, left-aligned above the plot region
chartTitle <- function(title, subtitle = NULL) {
  graphics::mtext(title, side = 3, line = if (is.null(subtitle)) 0.8 else 1.9, adj = 0, font = 2, col = ink$primary)
  if (!is.null(subtitle)) {
    graphics::mtext(subtitle, side = 3, line = 0.7, adj = 0, cex = 0.85, col = ink$secondary)
  }
}

emptyChart <- function(message) {
  op <- chartPar(c(1, 1, 1, 1))
  on.exit(graphics::par(op))
  graphics::plot.new()
  graphics::text(0.5, 0.5, message, col = ink$secondary)
}

# the margin, in lines, that labels need
labelLines <- function(labels, cex = 0.8) {
  max(graphics::strwidth(labels, units = "inches", cex = cex)) / graphics::par("csi")
}

shorten <- function(labels, width) {
  ifelse(nchar(labels) > width, paste0(substr(labels, 1, width - 1), "…"), labels)
}

# horizontal hairlines at the y ticks, and the y axis labels
yGrid <- function(at, labels = at) {
  graphics::abline(h = at, col = ink$grid, lwd = 1)
  graphics::axis(2, at = at, labels = labels, lwd = 0)
}

# A1: the module observations kept at each coverage cutoff, and the cutoff of the run
plotCoverage <- function(points, cutoff, automatic) {
  if (nrow(points) == 0) {
    return(emptyChart("No module was observed."))
  }
  op <- chartPar(c(4, 4.5, 4, 2))
  on.exit(graphics::par(op))
  top <- max(points$kept) * 1.08
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, 1), ylim = c(0, top), xaxs = "i", yaxs = "i")
  yGrid(pretty(c(0, max(points$kept))))
  graphics::axis(1, at = seq(0, 1, 0.2), lwd = 0, lwd.ticks = 1, col.ticks = ink$axis)
  graphics::abline(h = 0, col = ink$axis)
  graphics::title(xlab = "Coverage cutoff", ylab = "Module observations kept")
  ascending <- points[order(points$coverage), ]
  graphics::lines(c(0, ascending$coverage), c(max(points$kept), ascending$kept), type = "S", lwd = 2, col = series[1])
  graphics::points(ascending$coverage, ascending$kept, pch = 21, bg = series[1], col = ink$surface, cex = 1.3, lwd = 2)
  if (!is.na(cutoff)) {
    graphics::segments(cutoff, 0, cutoff, top, col = ink$secondary, lwd = 1)
    graphics::text(cutoff, top, sprintf(" %s %s", if (automatic) "learned cutoff" else "cutoff", format(cutoff)),
      adj = c(0, 1.4), col = ink$primary, cex = 0.85
    )
  }
  chartTitle(
    "Module observations kept at each coverage cutoff",
    if (automatic) {
      "The learned cutoff is the coverage at the largest jump in observations kept"
    } else {
      "A module observation is a module with coverage > 0 in a sample (or a taxon of a sample)"
    }
  )
}

# A2: rows (modules) by samples, one blue from light (low) to dark (high); grey where a module is not reported
plotHeatmap <- function(values, title, log) {
  if (nrow(values) == 0 || all(is.na(values))) {
    return(emptyChart("No module is reported."))
  }
  labels <- shorten(rownames(values), 60)
  showColumns <- ncol(values) <= 60
  left <- labelLines(labels) + 1
  bottom <- if (showColumns) labelLines(colnames(values)) + 1.5 else 1.5
  op <- chartPar(c(bottom, left, 4.2, 1))
  on.exit(graphics::par(op))
  n <- nrow(values)
  m <- ncol(values)
  # abundance: the range of the data (log10); coverage: always 0 to 1
  range <- if (log) range(values, na.rm = TRUE) else c(0, 1)
  scaled <- if (diff(range) > 0) (values - range[1]) / diff(range) else values * 0 + 1
  fills <- ifelse(is.na(scaled), ink$missing, ramp[1 + round(scaled * (length(ramp) - 1))])
  graphics::plot.new()
  graphics::plot.window(xlim = c(0.5, m + 0.5), ylim = c(0.5, n + 0.5), xaxs = "i", yaxs = "i")
  x <- rep(seq_len(m), each = n)
  y <- rep(n:1, times = m)
  gap <- if (n <= 60 && m <= 60) ink$surface else NA
  graphics::rect(x - 0.5, y - 0.5, x + 0.5, y + 0.5, col = fills, border = gap, lwd = 2)
  graphics::axis(2, at = n:1, labels = labels, lwd = 0, cex.axis = 0.8, col.axis = ink$secondary)
  if (showColumns) {
    graphics::axis(1, at = seq_len(m), labels = colnames(values), lwd = 0, las = 2, cex.axis = 0.8)
  }
  # the scale, under the title: a gradient bar with its range, then a swatch for "not reported"
  graphics::par(xpd = NA)
  inch <- diff(graphics::par("usr")[1:2]) / graphics::par("pin")[1]
  barX <- graphics::par("usr")[1] + c(0, 2.2) * inch
  barY <- graphics::grconvertY(graphics::par("usr")[4], "user", "inches") + c(0.24, 0.34)
  barY <- graphics::grconvertY(barY, "inches", "user")
  steps <- seq(barX[1], barX[2], length.out = length(ramp) + 1)
  graphics::rect(steps[-length(steps)], barY[1], steps[-1], barY[2], col = ramp, border = NA)
  ticks <- if (log) seq(ceiling(range[1]), floor(range[2])) else pretty(range, n = 3)
  ticks <- unique(c(range[1], ticks[ticks > range[1] & ticks < range[2]], range[2]))
  tickX <- barX[1] + (ticks - range[1]) / max(diff(range), 1e-12) * diff(barX)
  shown <- if (log) 10^ticks else ticks
  graphics::text(tickX, barY[1], format(signif(shown, 2), big.mark = ",", drop0trailing = TRUE, trim = TRUE),
    pos = 1, offset = 0.25, cex = 0.7, col = ink$muted
  )
  missingX <- barX[2] + c(0.3, 0.42) * inch
  graphics::rect(missingX[1], barY[1], missingX[2], barY[2], col = ink$missing, border = ink$axis)
  graphics::text(missingX[2], mean(barY), " not reported", adj = 0, cex = 0.75, col = ink$muted)
  graphics::mtext(title, side = 3, line = 2.6, adj = 0, font = 2, col = ink$primary)
}

# A3: each taxon's share of the module's per-taxon abundance, per sample; the `top` taxa in fixed colors, the rest grey
plotTaxa <- function(shares, title) {
  if (ncol(shares) == 0 || nrow(shares) == 0) {
    return(emptyChart("No taxon carries this module."))
  }
  n <- nrow(shares)
  m <- ncol(shares)
  fills <- ifelse(rownames(shares) == "Other taxa", other, series[seq_len(n)])
  names <- shorten(rownames(shares), 32)
  showColumns <- m <= 60
  right <- labelLines(names) + 3
  bottom <- if (showColumns) labelLines(colnames(shares)) + 1.5 else 1.5
  op <- chartPar(c(bottom, 4.5, 4, right))
  on.exit(graphics::par(op))
  graphics::plot.new()
  graphics::plot.window(xlim = c(0.5, m + 0.5), ylim = c(0, 1), xaxs = "i", yaxs = "i")
  yGrid(seq(0, 1, 0.25), paste0(seq(0, 100, 25), "%"))
  # half a bar: at most 12px (24px bars), at most 35% of a sample's slot
  width <- min(0.35, 0.125 * diff(graphics::par("usr")[1:2]) / graphics::par("pin")[1])
  for (sample in seq_len(m)) {
    tops <- cumsum(shares[, sample])
    graphics::rect(sample - width, tops - shares[, sample], sample + width, tops,
      col = fills, border = ink$surface, lwd = 2
    )
  }
  graphics::abline(h = 0, col = ink$axis)
  if (showColumns) {
    graphics::axis(1, at = seq_len(m), labels = colnames(shares), lwd = 0, las = 2, cex.axis = 0.8)
  }
  # legend in the right margin, in stacking order (top of the bar first)
  rows <- rev(seq_len(n))
  graphics::legend(graphics::grconvertX(1, "npc", "user"), 1,
    legend = names[rows], fill = fills[rows], border = NA, bty = "n",
    cex = 0.8, text.col = ink$secondary, xpd = NA, y.intersp = 1.3
  )
  chartTitle(title, "Share of each taxon in the sum of the module's per-taxon abundances")
}
