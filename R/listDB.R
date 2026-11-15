listDB <- function() {
	db.path <- system.file("extdata", package = "omixerRpm")
	db.list <- sub("\\.txt$", "", dir(db.path, pattern = "\\.txt$"))
	db.list
}