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

        # Make a function that can test to see if the data is consistent.
        # This is not called if you have an initialize function defined!
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
			
			# create table with module_id, module_description, modules abundances
			the.data.frame <- cbind(theObject@annotation, theObject@db@module.names[as.character(theObject@annotation$Module), ], slot(theObject, type))
			# update colnames
			colnames(the.data.frame)[2] <- "Description"
			return(the.data.frame)
		}
)