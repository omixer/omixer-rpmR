#' Run omixer-rpm from a web interface
#'
#' Starts a Shiny app in the browser: upload a KO table, choose the module database and the options of [rpm()], then
#' browse and download the module abundance and coverage tables, and explore them in interactive charts.
#'
#' The app needs packages that are not installed with omixerRpm:
#' `install.packages(c("shiny", "bslib", "DT", "ggplot2", "plotly", "r2d3"))`.
#'
#' @param ... Passed on to [shiny::runApp()], e.g. `port` or `launch.browser`.
#' @seealso [rpm()]
#' @examples
#' \dontrun{
#' runShinyRpm()
#' }
#' @export
runShinyRpm <- function(...) {
  # the app's packages are only suggested, so only users of the app install them
  needed <- c("shiny", "bslib", "DT", "ggplot2", "plotly", "r2d3")
  missing <- Filter(function(p) !requireNamespace(p, quietly = TRUE), needed)
  if (length(missing) > 0) {
    stop(
      "runShinyRpm() needs the packages ", paste(missing, collapse = ", "), ". Install them with ",
      "install.packages(c(\"", paste(missing, collapse = "\", \""), "\"))"
    )
  }
  shiny::runApp(system.file("shiny", package = "omixerRpm"), ...)
}
