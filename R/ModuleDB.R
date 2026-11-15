ModuleDB <- setClass(
        # Set the name for the class
        "ModuleDB",

        # Define the slots
        slots = c(
                directory = "character",
                modules = "character",
				hierarchy = "data.frame",
				module.names = "data.frame",
				hierarchy.file = "character",
				module.names.file = "character"
                ),

        # Set the default values for the slots. (optional)
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

# the names of the given modules, NA for a module without name
setGeneric(name="getNames",
		def=function(theObject, x){
			standardGeneric("getNames")
		}
)

setMethod(f = "getNames",
		signature = "ModuleDB",
		definition = function(theObject, x) {
			names <- .moduleNames(theObject)
			names[match(as.character(x), rownames(names)), 1]
		}
)


# the given level of the hierarchy of the given modules, NA for a module without hierarchy
setGeneric(name="getHierarchy",
		def=function(theObject, x, level){
			standardGeneric("getHierarchy")
		}
)

setMethod(f="getHierarchy",
		signature="ModuleDB",
		definition=function(theObject, x, level){
			hierarchy <- theObject@hierarchy
			if (nrow(hierarchy) == 0) {
				hierarchy <- .readDbTable(theObject, theObject@hierarchy.file)
			}
			hierarchy[match(as.character(x), rownames(hierarchy)), level]
		}
)
