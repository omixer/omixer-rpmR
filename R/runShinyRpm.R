#' Run omixer-rpm from a web interface
#'
#' Starts a Shiny app in the browser: upload a KO table, choose the module database and the options of [rpm()], then
#' browse and download the module abundance and coverage tables.
#'
#' The app needs the packages shiny, bslib and DT, which are not installed with omixerRpm:
#' `install.packages(c("shiny", "bslib", "DT"))`. The "Taxa × modules" chart also needs circlize
#' (`install.packages("circlize")`); without it, that tab says so and the rest of the app works.
#'
#' @param ... Passed on to [shiny::runApp()], e.g. `port` or `launch.browser`.
#' @seealso [rpm()]
#' @examples
#' \dontrun{
#' runShinyRpm()
#' }
#' @export
runShinyRpm <- function(...) {
  # shiny, bslib and DT are only suggested, so only users of the app install them
  missing <- Filter(function(p) !requireNamespace(p, quietly = TRUE), c("shiny", "bslib", "DT"))
  if (length(missing) > 0) {
    stop(
      "runShinyRpm() needs the packages ", paste(missing, collapse = ", "), ". Install them with ",
      "install.packages(c(\"", paste(missing, collapse = "\", \""), "\"))"
    )
  }
  shiny::runApp(system.file("shiny", package = "omixerRpm"), ...)
}
