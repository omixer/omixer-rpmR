# Starts the Shiny app (inst/shiny). shiny, bslib and DT are only suggested, so only users of the app install them.
runShinyRpm <- function(...) {
  missing <- Filter(function(p) !requireNamespace(p, quietly = TRUE), c("shiny", "bslib", "DT"))
  if (length(missing) > 0) {
    stop("runShinyRpm() needs the packages ", paste(missing, collapse = ", "), ". Install them with ",
         "install.packages(c(\"", paste(missing, collapse = "\", \""), "\"))")
  }
  shiny::runApp(system.file("shiny", package = "omixerRpm"), ...)
}
