#' Module profiles
#'
#' The result of [rpm()]: the abundance and coverage of the modules per sample. `asDataFrame()` gives one of them as a
#' table with the module descriptions, or both merged into one table. `Modules(...)` makes one from its slots, given
#' by name.
#'
#' @slot abundance,coverage data.frames of the modules (rows) per sample (columns).
#' @slot annotation The key columns of the rows (Module, or Taxon and Module).
#' @slot db The [ModuleDB] of the modules.
#' @slot cutoff The coverage cutoff of the run: the given `minimum.coverage`, or the one learned from the data; NA when
#'   no module was observed.
#' @author Youssef Darzi
#' @examples
#' \dontrun{
#' mods <- rpm("matrix.tsv", minimum.coverage = 0.3)
#' coverage <- asDataFrame(mods, "coverage")
#' # one row per sample and reported module, with its abundance and coverage
#' merged <- asDataFrame(mods, "merged")
#' }
#' @rdname Modules
#' @export
Modules <- setClass(
  "Modules",
  slots = c(
    coverage = "data.frame",
    abundance = "data.frame",
    annotation = "data.frame",
    db = "ModuleDB",
    cutoff = "numeric"
  ),
  prototype = list(
    coverage = NULL,
    abundance = NULL,
    annotation = NULL,
    db = NULL,
    cutoff = NA_real_
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
#' @param type `"abundance"`, `"coverage"` or `"merged"`.
#' @return `asDataFrame()` returns a data.frame. For `"abundance"` and `"coverage"`: the key columns ((Taxon,) Module),
#'   the module Description, then one column per sample. For `"merged"`: one row per sample and reported module, with
#'   the columns Sample, the key columns, Description, Abundance and Coverage; a module below the cutoff in a sample
#'   (coverage 0) is left out.
#' @export
setGeneric(name = "asDataFrame", def = function(theObject, type) {
  standardGeneric("asDataFrame")
})

#' @rdname Modules
#' @export
setMethod(f = "asDataFrame", signature = "Modules", definition = function(theObject, type) {
  # the key columns ((Taxon,) Module) and the module description
  keys <- cbind(theObject@annotation, Description = getNames(theObject@db, theObject@annotation$Module))
  if (identical(type, "merged")) {
    return(.merged(theObject, keys))
  }
  cbind(keys, slot(theObject, type))
})

# the rows of every sample one after the other, with the abundance and coverage of each; a module below the cutoff in
# a sample is 0 in both, and left out
.merged <- function(theObject, keys) {
  merged <- do.call(rbind, lapply(colnames(theObject@abundance), function(sample) {
    data.frame(
      Sample = rep(sample, nrow(keys)), keys, Abundance = theObject@abundance[[sample]],
      Coverage = theObject@coverage[[sample]], check.names = FALSE, row.names = NULL
    )
  }))
  merged <- merged[merged$Coverage > 0, , drop = FALSE]
  rownames(merged) <- NULL
  merged
}
