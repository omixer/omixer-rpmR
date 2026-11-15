#' Bundled module databases
#'
#' `listDB()` lists the module databases bundled with the package, `loadDB()` loads one of them and `loadDefaultDB()`
#' loads the default, the gut metabolic modules GMMs.v1.07.
#'
#' @param name A database name, as listed by `listDB()`.
#' @return `listDB()` returns the database names; `loadDB()` and `loadDefaultDB()` return a [ModuleDB].
#' @author Youssef Darzi
#' @examples
#' listDB()
#' db <- loadDB("GBMs.v1.0")
#' getNames(db, "MGB001")
#' @export
loadDB <- function(name) {
  db.path <- system.file("extdata", package = "omixerRpm")
  db <- ModuleDB(directory = db.path, modules = paste0(name, ".txt"), module.names.file = paste0(name, ".names"))
  db@module.names <- .readDbTable(db, db@module.names.file)
  message("Loaded ", name)
  db
}
