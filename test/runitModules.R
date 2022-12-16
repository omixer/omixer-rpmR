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

test.callOptions <- {
	# check default
	mods <- rpm("test/matrix.tsv", annotation = 1, minimum.coverage=0.66)
	checkEquals(mods@abundance[which(mods@annotation == 'MF0004'), "S1"], 5457.398359)

	# check with length normalization
	mods <- rpm("test/matrix.tsv", annotation = 1, minimum.coverage=0.66, normalize.by.length = TRUE)
	checkEquals(mods@abundance[which(mods@annotation == 'MF0004'), "S1"], 708.5907183)
	
	# check with length normalization AND --Xdistribute
	mods <- rpm("test/matrix.tsv", annotation = 1, minimum.coverage=0.66, normalize.by.length = TRUE, distribute = TRUE)
	checkEquals(mods@abundance[which(mods@annotation == 'MF0004'), "S1"], 236.1969061)
}

# See code comments
test.moduleDbAnnotation <- function() {
	# Setup the default module database.
	db <- loadDefaultDB()
	# check getNames returns the correct annotation
	checkEquals(getNames(db, "MF0010"), "sucrose degradation I")
}


test.asDataFrame <- {
	# check default
	mods <- rpm("test/matrix.tsv", annotation = 1, minimum.coverage=0.3)
	coverage <- asDataFrame(mods, "coverage")
	print(coverage)
	checkEquals(nrow(coverage), 96)
	checkEquals(ncol(coverage), 4)
	checkEquals(as.character(coverage[1, "Description"]), "glyoxylate bypass")
	checkEquals(as.character(coverage[96, "Description"]), "maltose degradation")
}


test.moduleDbList <- function() {
	# List available databases.
	db <- listDB()
	# check getNames returns the correct annotation
	checkEquals(db[1], "GBMs.v1.0")
	checkEquals(db[2], "GMMs.v1.07")
}

# See code comments
test.moduleDbLoad <- function() {
	# Setup the default module database.
	db <- loadDB("GMMs.v1.07")
	# check getNames returns the correct annotation
	checkEquals(getNames(db, "MF0010"), "sucrose degradation I")
}

test.handleMalformedInput <- function() {
	# expect a NumberFormat exception for the wrong annotation value
	checkException(rpm("test/species_matrix.tsv", annotation = 1, minimum.coverage = 0.3))
}
