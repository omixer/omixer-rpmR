#' Module profiles
#'
#' The result of [rpm()]: the abundance and coverage of the modules per sample. `asDataFrame()` gives one of them as a
#' table with the module descriptions. `Modules(...)` makes one from its slots, given by name.
#'
#' @slot abundance,coverage data.frames of the modules (rows) per sample (columns).
#' @slot annotation The key columns of the rows (Module, or Taxon and Module).
#' @slot db The [ModuleDB] of the modules.
#' @author Youssef Darzi
#' @examples
#' \dontrun{
#' mods <- rpm("matrix.tsv", minimum.coverage = 0.3)
#' coverage <- asDataFrame(mods, "coverage")
#' }
#' @rdname Modules
#' @export
Modules <- setClass(
  "Modules",
  slots = c(
    coverage = "data.frame",
    abundance = "data.frame",
    annotation = "data.frame",
    db = "ModuleDB"
  ),
  prototype = list(
    coverage = NULL,
    abundance = NULL,
    annotation = NULL,
    db = NULL
  ),
  # abundance and coverage hold the same modules and samples
  validity = function(object) {
    if (!is.null(object@coverage) && !is.null(object@abundance)) {
      if (!all(dim(object@coverage) == dim(object@abundance))) {
        return("Abundance and Coverage matrices are not of equal length")
      }
    }
    TRUE
  }
)

#' @rdname Modules
#' @param theObject A `Modules` object.
#' @param type `"abundance"` or `"coverage"`.
#' @return `asDataFrame()` returns a data.frame: the key columns, the module Description, then one column per sample.
#' @export
setGeneric(name = "asDataFrame", def = function(theObject, type) {
  standardGeneric("asDataFrame")
})

#' @rdname Modules
#' @export
setMethod(f = "asDataFrame", signature = "Modules", definition = function(theObject, type) {
  # the key columns ((Taxon,) Module), the module description, then one column per sample
  cbind(theObject@annotation,
    Description = getNames(theObject@db, theObject@annotation$Module),
    slot(theObject, type)
  )
})
