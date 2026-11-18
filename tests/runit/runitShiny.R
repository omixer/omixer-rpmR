library(omixerRpm)

# the app's code (app.R and R/), for the functions the server uses: testServer() only shows the server's own values
appCode <- function() {
  dir <- system.file("shiny", package = "omixerRpm")
  app <- new.env()
  for (file in list.files(file.path(dir, "R"), full.names = TRUE)) {
    sys.source(file, app)
  }
  sys.source(file.path(dir, "app.R"), app, chdir = TRUE)
  app
}

# runs the app's server on an uploaded file, as the browser would, and returns this session's tables (NULL on error)
shinyTables <- function(file, ...) {
  tables <- NULL
  # testServer runs in the app's directory
  path <- normalizePath(file)
  shiny::testServer(system.file("shiny", package = "omixerRpm"), {
    session$setInputs(
      input_file = data.frame(
        name = basename(path), size = file.size(path), type = "",
        datapath = path
      ),
      annotation = "1", ignore_taxonomy = FALSE, module_db = "GMMs.v1.07",
      automatic_coverage = TRUE, minimum_coverage = 0.3, score_estimator = "median",
      complex_rule = "any", normalize_by_length = FALSE, distribute = FALSE
    )
    session$setInputs(...)
    session$setInputs(run = 1)
    tables <<- results()
  })
  tables
}

# the app gives the same tables as rpm() with the same options
test.shinyOptions <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    return()
  }
  tables <- shinyTables("data/matrix.tsv",
    automatic_coverage = FALSE, minimum_coverage = 0.66,
    score_estimator = "average", normalize_by_length = TRUE, distribute = TRUE, complex_rule = "all"
  )
  mods <- rpm("data/matrix.tsv",
    minimum.coverage = 0.66, score.estimator = "average", normalize.by.length = TRUE,
    distribute = TRUE, complex.rule = "all"
  )
  checkEquals(tables$abundance[, c("S1", "S2")], mods@abundance)
  checkEquals(tables$coverage[, c("S1", "S2")], mods@coverage)
  checkEquals(tables$abundance$Module, mods@annotation$Module)
  checkEquals(tables$abundance$Description[1], getNames(loadDefaultDB(), mods@annotation$Module[1]))

  # the defaults: automatic cutoff
  tables <- shinyTables("data/matrix.tsv")
  checkEquals(tables$abundance[, c("S1", "S2")], rpm("data/matrix.tsv")@abundance)
}

test.shinyTaxa <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    return()
  }
  tables <- shinyTables("data/species_matrix.tsv", annotation = "2", automatic_coverage = FALSE)
  checkEquals(colnames(tables$coverage)[1:3], c("Taxon", "Module", "Description"))
  checkEquals(nrow(tables$coverage), 284)

  # HUMAnN, per taxon and per sample
  tables <- shinyTables("data/humann_ko.tsv", annotation = "humann", automatic_coverage = FALSE)
  checkEquals(colnames(tables$abundance)[1:2], c("Taxon", "Module"))
  tables <- shinyTables("data/humann_ko.tsv",
    annotation = "humann", automatic_coverage = FALSE,
    ignore_taxonomy = TRUE
  )
  checkEquals(colnames(tables$abundance)[1:3], c("Module", "Description", "S1"))
}

# an omixer-rpm error leaves no tables (the app shows the message)
test.shinyError <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    return()
  }
  checkTrue(is.null(shinyTables("data/species_matrix.tsv", annotation = "1", automatic_coverage = FALSE)))
}

# the charts and the merged table of a run per taxon, through the server as the browser uses them
test.shinyCharts <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    return()
  }
  path <- normalizePath("data/species_matrix.tsv")
  mods <- rpm(path, annotation = 2)
  app <- appCode()
  shiny::testServer(system.file("shiny", package = "omixerRpm"), {
    session$setInputs(
      input_file = data.frame(name = "species.tsv", size = 1, type = "", datapath = path),
      annotation = "2", ignore_taxonomy = FALSE, module_db = "GMMs.v1.07", automatic_coverage = TRUE,
      minimum_coverage = 0.3, score_estimator = "median", complex_rule = "any", normalize_by_length = FALSE,
      distribute = FALSE, heatmap_measure = "abundance", heatmap_rows = 10, run = 1
    )
    # the learned cutoff of the run, and the distribution it was learned from: a coverage of it
    checkEquals(results()$cutoff, mods@cutoff)
    checkTrue(results()$automatic)
    checkTrue(results()$cutoff %in% distribution()$coverage)
    checkTrue(!is.unsorted(distribution()$kept))

    # the merged table: one row per reported module of a sample, with both values from the tables
    merged <- read.delim(output$download_merged, check.names = FALSE)
    checkEquals(colnames(merged), c("Sample", "Taxon", "Module", "Description", "Abundance", "Coverage"))
    checkEquals(nrow(merged), sum(mods@coverage > 0))
    checkTrue(all(merged$Coverage > 0))
    row <- merged[merged$Sample == "s06a", ][1, ]
    table <- results()$abundance
    checkEquals(row$Abundance, table$s06a[table$Taxon == row$Taxon & table$Module == row$Module])

    # the heatmap: the 10 rows with the highest mean, log10 of the abundance
    checkEquals(dim(heatmap()), c(10, 2))
    checkEquals(max(heatmap(), na.rm = TRUE), log10(max(as.matrix(mods@abundance))))
    session$setInputs(heatmap_measure = "coverage")
    checkTrue(all(heatmap() <= 1, na.rm = TRUE))

    # the taxa of a module: 8 taxa and the rest, their shares sum to 1 in each sample
    session$setInputs(taxa_module = "MF0073")
    checkEquals(nrow(taxa()$shares), 9)
    checkEquals(rownames(taxa()$shares)[9], "Other taxa")
    checkEquals(unname(colSums(taxa()$shares)), c(1, 1))
    module <- as.matrix(table[table$Module == "MF0073", c("s06a", "s06b")])
    checkEquals(unname(colSums(taxa()$abundance)), unname(colSums(module)))

    # the interactive charts, with the values as tooltips
    tooltips <- function(chart) unlist(lapply(plotly::plotly_build(chart)$x$data, `[[`, "text"))
    taxaTips <- tooltips(app$interactive(app$taxaChart(taxa(), "MF0073"), legend = "reversed"))
    checkTrue(any(grepl("^s06a<br>Faecalibacterium prausnitzii: [0-9.]+%<br>abundance ", taxaTips)))
    cutoffTips <- tooltips(app$interactive(app$coverageChart(distribution(), results()$cutoff, TRUE)))
    checkTrue(any(grepl(sprintf("Cutoff %s keeps", signif(results()$cutoff, 3)), cutoffTips, fixed = TRUE)))
    heatmapTips <- tooltips(app$interactive(app$heatmapChart(heatmap(), log = FALSE, "coverage")))
    checkTrue(any(grepl(paste0("^s06a<br>", rownames(heatmap())[1], "<br>"), heatmapTips)))
    for (chart in c("heatmap", "taxa", "cutoff")) {
      checkTrue(!is.null(output[[chart]]), chart)
    }
  })
}

# without taxa, the Taxa tab explains what it needs
test.shinyChartsWithoutTaxa <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    return()
  }
  path <- normalizePath("data/matrix.tsv")
  shiny::testServer(system.file("shiny", package = "omixerRpm"), {
    session$setInputs(
      input_file = data.frame(name = "matrix.tsv", size = 1, type = "", datapath = path),
      annotation = "1", ignore_taxonomy = FALSE, module_db = "GMMs.v1.07", automatic_coverage = FALSE,
      minimum_coverage = 0.3, score_estimator = "median", complex_rule = "any", normalize_by_length = FALSE,
      distribute = FALSE, run = 1
    )
    checkTrue(grepl("need results per taxon", output$taxa_panel$html, fixed = TRUE))
    checkTrue(grepl("need results per taxon", output$chord_panel$html, fixed = TRUE))
    checkEquals(results()$cutoff, 0.3)
    checkTrue(!results()$automatic)
  })
}

# every input and output of the server has one place on the page
test.shinyPage <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    return()
  }
  html <- as.character(htmltools::renderTags(appCode()$ui)$html)
  # the id attributes (not data-tabsetid and the like)
  ids <- regmatches(html, gregexpr('(?<![-\\w])id="[^"]+"', html, perl = TRUE))[[1]]
  checkTrue(!anyDuplicated(ids), paste("duplicated ids:", paste(unique(ids[duplicated(ids)]), collapse = ", ")))
  for (id in c(
    "download_merged", "download_abundance", "download_coverage", "abundance", "coverage", "heatmap_chart",
    "heatmap_measure", "heatmap_rows", "taxa_panel", "chord_panel", "cutoff"
  )) {
    checkTrue(sprintf('id="%s"', id) %in% ids, id)
  }
}

# the links between the taxa and modules with the highest abundance, summed over the samples or of one sample
test.shinyChord <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    return()
  }
  path <- normalizePath("data/species_matrix.tsv")
  app <- appCode()
  shiny::testServer(system.file("shiny", package = "omixerRpm"), {
    session$setInputs(
      input_file = data.frame(name = "species.tsv", size = 1, type = "", datapath = path),
      annotation = "2", ignore_taxonomy = FALSE, module_db = "GMMs.v1.07", automatic_coverage = FALSE,
      minimum_coverage = 0.3, score_estimator = "median", complex_rule = "any", normalize_by_length = FALSE,
      distribute = FALSE, run = 1
    )
    table <- results()$abundance
    session$setInputs(chord_sample = "", chord_taxa = 15, chord_modules = 15)
    links <- chord()$links
    checkEquals(length(chord()$taxa), 15)
    checkEquals(length(chord()$modules), 15)
    checkTrue(all(links$taxon %in% chord()$taxa & links$module %in% chord()$modules))
    checkTrue(chord()$share > 0 && chord()$share <= 1)
    # a link: the module's abundance in the taxon, summed over the samples
    row <- table$Taxon == links$taxon[1] & table$Module == links$module[1]
    checkEquals(links$value[1], table$s06a[row] + table$s06b[row])
    # the taxa with the highest total come first
    totals <- sort(tapply(table$s06a + table$s06b, table$Taxon, sum), decreasing = TRUE)
    checkEquals(chord()$taxa[1], names(totals)[1])

    # one sample
    session$setInputs(chord_sample = "s06b", chord_taxa = 5, chord_modules = 5)
    links <- chord()$links
    row <- table$Taxon == links$taxon[1] & table$Module == links$module[1]
    checkEquals(links$value[1], table$s06b[row])
    checkTrue(length(chord()$taxa) <= 5 && length(chord()$modules) <= 5)
    checkTrue(grepl(chord()$modules[1], output$chord_key$html, fixed = TRUE))

    # the d3 chart's data: the taxa then the modules, a symmetric matrix of the links
    data <- app$chordData(chord(), chordModuleNames())
    taxa <- length(chord()$taxa)
    checkEquals(data$kinds, rep(c("taxon", "module"), c(taxa, length(chord()$modules))))
    checkEquals(data$matrix, t(data$matrix))
    first <- chord()$links[1, ]
    checkEquals(data$matrix[match(first$taxon, chord()$taxa), taxa + match(first$module, chord()$modules)], first$value)
    checkEquals(data$names[taxa + 1], chordModuleNames()[1])
    checkTrue(!is.null(output$chord))
  })
}
