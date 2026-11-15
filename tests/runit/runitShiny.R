library(omixerRpm)

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

# the charts and the long table of a run per taxon, through the server as the browser uses them
test.shinyCharts <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    return()
  }
  path <- normalizePath("data/species_matrix.tsv")
  mods <- rpm(path, annotation = 2)
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

    # the long table: one row per reported module of a sample, with both values from the tables
    long <- read.delim(output$download_long, check.names = FALSE)
    checkEquals(colnames(long), c("Sample", "Taxon", "Module", "Description", "Abundance", "Coverage"))
    checkEquals(nrow(long), sum(mods@coverage > 0))
    checkTrue(all(long$Coverage > 0))
    row <- long[long$Sample == "s06a", ][1, ]
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

    # the value under the pointer
    session$setInputs(taxa_hover = list(x = 1, y = 0.01))
    checkTrue(grepl("^s06a, Faecalibacterium prausnitzii: ", output$taxa_value))
    session$setInputs(cutoff_hover = list(x = results()$cutoff, y = 0))
    checkTrue(grepl(sprintf("Cutoff %s keeps", format(results()$cutoff)), output$cutoff_value, fixed = TRUE))
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
    checkEquals(results()$cutoff, 0.3)
    checkTrue(!results()$automatic)
  })
}

# every input and output of the server has one place on the page
test.shinyPage <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    return()
  }
  dir <- system.file("shiny", package = "omixerRpm")
  app <- new.env()
  for (file in list.files(file.path(dir, "R"), full.names = TRUE)) {
    sys.source(file, app)
  }
  sys.source(file.path(dir, "app.R"), app, chdir = TRUE)
  html <- as.character(htmltools::renderTags(app$ui)$html)
  # the id attributes (not data-tabsetid and the like)
  ids <- regmatches(html, gregexpr('(?<![-\\w])id="[^"]+"', html, perl = TRUE))[[1]]
  checkTrue(!anyDuplicated(ids), paste("duplicated ids:", paste(unique(ids[duplicated(ids)]), collapse = ", ")))
  for (id in c(
    "download_long", "download_abundance", "download_coverage", "abundance", "coverage", "heatmap",
    "heatmap_value", "heatmap_measure", "heatmap_rows", "taxa_panel", "cutoff", "cutoff_value"
  )) {
    checkTrue(sprintf('id="%s"', id) %in% ids, id)
  }
}
