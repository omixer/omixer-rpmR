#' Module database
#'
#' Locates the files of a module database: the module definitions, the module names and, optionally, a module
#' hierarchy. `ModuleDB(...)` makes one from its slots, given by name; `getNames()` and `getHierarchy()` look up
#' modules in it.
#'
#' @slot directory The directory of the database files.
#' @slot modules The module definition file (default module.list).
#' @slot module.names.file A tab-separated file of module id and name (default module.names).
#' @slot hierarchy.file A tab-separated file of module id and hierarchy levels (default hierarchy.tsv; none is
#'   bundled).
#' @slot module.names,hierarchy Their content, read when needed.
#' @author Youssef Darzi
#' @seealso [loadDB()] for the bundled databases.
#' @examples
#' \dontrun{
#' db <- ModuleDB(directory = "/path/to/moduledb/", modules = "GBMs.v1.0.txt", module.names.file = "GBMs.v1.0.names")
#' # Serotonin synthesis I
#' getNames(db, "MGB001")
#' }
#' @rdname ModuleDB
#' @export
ModuleDB <- setClass(
  "ModuleDB",
  slots = c(
    directory = "character",
    modules = "character",
    hierarchy = "data.frame",
    module.names = "data.frame",
    hierarchy.file = "character",
    module.names.file = "character"
  ),
  prototype = list(
    directory = ".",
    modules = "module.list",
    hierarchy.file = "hierarchy.tsv",
    module.names.file = "module.names"
  )
)

# a tab-separated file of the database: the module id (row names), then its values
.readDbTable <- function(theObject, file) {
  read.table(file.path(theObject@directory, file), row.names = 1, sep = "\t", header = FALSE, as.is = TRUE)
}

# the module names: loaded by loadDB(), read from their file for a database made with ModuleDB()
.moduleNames <- function(theObject) {
  if (nrow(theObject@module.names) == 0) {
    return(.readDbTable(theObject, theObject@module.names.file))
  }
  theObject@module.names
}

#' @rdname ModuleDB
#' @param theObject A `ModuleDB`.
#' @param x Module ids.
#' @return `getNames()` returns the names of the modules, `getHierarchy()` their hierarchy level; NA for a module that
#'   is not in the file.
#' @export
setGeneric(name = "getNames", def = function(theObject, x) {
  standardGeneric("getNames")
})

#' @rdname ModuleDB
#' @export
setMethod(f = "getNames", signature = "ModuleDB", definition = function(theObject, x) {
  names <- .moduleNames(theObject)
  names[match(as.character(x), rownames(names)), 1]
})

#' @rdname ModuleDB
#' @param level The hierarchy level (column of the hierarchy file).
#' @export
setGeneric(name = "getHierarchy", def = function(theObject, x, level) {
  standardGeneric("getHierarchy")
})

#' @rdname ModuleDB
#' @export
setMethod(f = "getHierarchy", signature = "ModuleDB", definition = function(theObject, x, level) {
  hierarchy <- theObject@hierarchy
  if (nrow(hierarchy) == 0) {
    hierarchy <- .readDbTable(theObject, theObject@hierarchy.file)
  }
  hierarchy[match(as.character(x), rownames(hierarchy)), level]
})
