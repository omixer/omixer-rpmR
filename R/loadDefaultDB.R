loadDefaultDB <- function() {
	gmms.db.path <- system.file("extdata", package = "omixerRpm")
	gmms.db <- ModuleDB(directory = gmms.db.path, modules = "GMMs.v1.07.txt", module.names.file="GMMs.v1.07.names")
	print("Loaded GMMs v1.07")
	gmms.db
}