loadDB <- function(name) {
	db.path <- system.file("extdata", package = "omixerRpm")
	db <- ModuleDB(directory = db.path, modules = paste0(name, ".txt"), module.names.file=paste0(name, ".names"))
	print(paste("Loaded", name))
	db
}