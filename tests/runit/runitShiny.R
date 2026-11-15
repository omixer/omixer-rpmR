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
