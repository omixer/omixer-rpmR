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
                ),

        # Make a function that can test to see if the data is consistent.
        # This is not called if you have an initialize function defined!
        validity = function(object) {
			# Could validate by checking files exist
                return(TRUE)
        }
)

# create a method to get the name fo a given module
setGeneric(name="getNames",
		def=function(theObject, x){
			standardGeneric("getNames")
		}
)

setMethod(f = "getNames",
		signature = "ModuleDB",
		definition = function(theObject, x) {
			if(nrow(theObject@module.names) == 0) {
				theObject@module.names <- read.table(
						file.path(theObject@directory, theObject@module.names.file),
						row.names=1,
						sep="\t",
						header=F, 
						as.is=T)
			}
			idx <- which(rownames(theObject@module.names) == x)
			if(length(idx) > 0 ){
				return(theObject@module.names[idx,1])
			}
			return(NA)
		}
)


setGeneric(name="getHierarchy",
		def=function(theObject, x, level){
			standardGeneric("getHierarchy")
		}
)

setMethod(f="getHierarchy",
		signature="ModuleDB",
		definition=function(theObject, x, level){
			if(nrow(theObject@hierarchy) == 0) {
				theObject@hierarchy <- read.table(
						file.path(theObject@directory, theObject@hierarchy.file),
						row.names=1,
						sep="\t",
						header=F, 
						as.is=T)
			}
			idx <- which(rownames(theObject@hierarchy) == x)
			if(length(idx) > 0 ){
				return(theObject@hierarchy[idx, level])	
			}
			return(NA)
		}
)