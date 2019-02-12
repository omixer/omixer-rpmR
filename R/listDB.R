listDB <- function() {
	db.path <- system.file("extdata", package = "omixerRpm")
	db.list = gsub(".txt", "", dir(db.path, pattern=".txt"))
	db.list
}