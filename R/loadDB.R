loadDB <- function(name) {
	db.path <- system.file("extdata", package = "omixerRpm")
	db <- ModuleDB(directory = db.path, modules = paste0(name, ".txt"), module.names.file=paste0(name, ".names"))
	db@module.names <- read.table(
			file.path(db@directory, db@module.names.file),
			row.names=1,
			sep="\t",
			header=F, 
			as.is=T)
	print(paste("Loaded", name))
	db
}