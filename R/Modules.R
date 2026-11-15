Modules <- setClass(
        # Set the name for the class
        "Modules",

        # Define the slots
        slots = c(
                coverage = "data.frame",
                abundance = "data.frame",
				annotation = "data.frame",
				db="ModuleDB"
                ),

        # Set the default values for the slots. (optional)
        prototype = list(
				coverage = NULL,
				abundance = NULL,
				annotation = NULL,
				db = NULL
                ),

        # abundance and coverage hold the same modules and samples
        validity = function(object) {
                if(!is.null(object@coverage) && !is.null(object@abundance)) {
                    if(!all(dim(object@coverage) == dim(object@abundance))){
						return("Abundance and Coverage matrices are not of equal length")	
					}
                }
                return(TRUE)
        }
)


setGeneric(name="asDataFrame",
		def=function(theObject, type){
			standardGeneric("asDataFrame")
		}
)

setMethod(f = "asDataFrame",
		signature = "Modules",
		definition = function(theObject, type) {
			# the key columns ((Taxon,) Module), the module description, then one column per sample
			cbind(theObject@annotation, Description = getNames(theObject@db, theObject@annotation$Module),
			      slot(theObject, type))
		}
)