loadDefaultDB <- function() {
	gmms.db.path <- system.file("extdata", package = "omixerRpm")
	gmms.db <- ModuleDB(directory = gmms.db.path, modules = "GMMs.v1.07.txt")
	print("Loaded GMMs.v1.07.txt")
	gmms.db
}