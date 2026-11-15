loadDB <- function(name) {
	db.path <- system.file("extdata", package = "omixerRpm")
	db <- ModuleDB(directory = db.path, modules = paste0(name, ".txt"), module.names.file=paste0(name, ".names"))
	db@module.names <- .readDbTable(db, db@module.names.file)
	message("Loaded ", name)
	db
}
