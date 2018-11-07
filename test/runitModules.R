library(omixerRpm)

# Ensures correct number of modules and samples is returned 
test.moduleMapping <- function (){
	# Test for data.frame, KO only annotation
	dat <- read.table("test/matrix.tsv", header=T, sep="\t")
	mods <- rpm(dat, minimum.coverage=0.3, annotation = 1)
	checkEquals(nrow(mods@coverage), 96)
	checkEquals(nrow(mods@abundance), 96)
	checkEquals(ncol(mods@abundance), 2)
	db <- loadDefaultDB()
	# Test annotation is properly set
	checkEquals(getNames(db, mods@annotation[1,]), "glyoxylate bypass")
	
	# Test for an input file with KO, taxonomic annotation
	taxon.mods <- rpm("test/species_matrix.tsv", annotation = 2, minimum.coverage=0.3)
	checkEquals(nrow(taxon.mods@coverage), 284)
	checkEquals(ncol(taxon.mods@coverage), 2)
}

# See code comments
test.moduleDbAnnotation <- function() {
	# Setup the module database. This is an alternative to loadDefaultDB()
	db <- ModuleDB(directory = "./inst/extdata", modules = "GMMs.v1.07.txt")
	# check getNames returns the correct annotation
	checkEquals(getNames(db, "MF0010"), "sucrose degradation I")
}