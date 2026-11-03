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
	# Test annotation is properly set; modules follow the database order
	checkEquals(getNames(db, mods@annotation[1,]), "arabinoxylan degradation")
	
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
	# modules follow the database order
	checkEquals(as.character(coverage[1, "Description"]), "arabinoxylan degradation")
	checkEquals(as.character(coverage[96, "Description"]), "mucin degradation")
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

# One subunit of the complexes K01184,K01213 (MF0003) and K02786,K02787,K02788 (MF0007) is observed
test.complexRule <- function() {
	db <- loadDB("GMMs.v1.07")
	dat <- data.frame(entry = c("K01184", "K01176", "K02787"), S1 = 1)

	# default (any): a complex step is present when at least one subunit is observed
	mods <- rpm(dat, minimum.coverage = 0.1, module.db = db)
	checkEquals(sort(mods@annotation[, 1]), c("MF0003", "MF0005", "MF0007"))
	checkEquals(mods@coverage[which(mods@annotation == "MF0003"), "S1"], 0.5)

	# all: every subunit is required, so only MF0005 (no complex) is left
	mods <- rpm(dat, minimum.coverage = 0.1, module.db = db, complex.rule = "all")
	checkEquals(mods@annotation[, 1], "MF0005")
	checkEquals(mods@coverage[1, "S1"], 1 / 3)
}

test.invalidComplexRule <- function() {
	checkException(rpm("test/matrix.tsv", annotation = 1, minimum.coverage = 0.3, complex.rule = "fraction"))
}

# A HUMAnN KO table (humann_regroup_table, humann_rename_table): MF0003 is K01051, then K01184,K01213 or K18650.
# B. fragilis has both steps, unclassified only K01051; special rows and KO names are ignored, and the
# _Abundance-RPKs suffix is removed from the sample names
test.humann <- function() {
	db <- loadDB("GMMs.v1.07")

	# per taxon (stratified rows only)
	mods <- rpm("test/humann_ko.tsv", annotation = "humann", minimum.coverage = 0.3, module.db = db)
	checkEquals(colnames(mods@annotation), c("Taxon", "Module"))
	checkEquals(colnames(mods@abundance), c("S1", "S2"))
	fragilis <- which(mods@annotation$Taxon == "g__Bacteroides.s__Bacteroides_fragilis" & mods@annotation$Module == "MF0003")
	checkEquals(mods@coverage[fragilis, "S1"], 1)
	checkEquals(mods@abundance[fragilis, "S1"], 3.5)
	unclassified <- which(mods@annotation$Taxon == "unclassified" & mods@annotation$Module == "MF0003")
	checkEquals(mods@coverage[unclassified, "S1"], 0.5)

	# per sample (community totals only, never added to their strata)
	mods <- rpm("test/humann_ko.tsv", annotation = "humann", minimum.coverage = 0.3, module.db = db, ignore.taxonomy = TRUE)
	checkEquals(colnames(mods@annotation), "Module")
	checkEquals(mods@annotation$Module, "MF0003")
	checkEquals(unlist(mods@abundance[1, ]), c(S1 = 4.5, S2 = 3.5))

	# a table read into R is refused: read.table() turns its first data row into the header
	dat <- read.table("test/humann_ko.tsv", header = TRUE, sep = "\t")
	checkException(rpm(dat, annotation = "humann", minimum.coverage = 0.3, module.db = db))

	# a table without strata (humann --remove-stratified-output) gives one result per sample
	totals <- tempfile(fileext = ".tsv")
	writeLines(grep("|", readLines("test/humann_ko.tsv"), fixed = TRUE, invert = TRUE, value = TRUE), totals)
	mods <- rpm(totals, annotation = "humann", minimum.coverage = 0.3, module.db = db)
	checkEquals(colnames(mods@annotation), "Module")
	checkEquals(unlist(mods@abundance[1, ]), c(S1 = 4.5, S2 = 3.5))
}

test.humannDirectoryRejected <- function() {
	checkException(rpm("test", annotation = "humann", minimum.coverage = 0.3))
}

test.ignoreTaxonomy <- function() {
	# a taxon matrix per sample: one row per module, as for annotation 1
	mods <- rpm("test/species_matrix.tsv", annotation = 2, minimum.coverage = 0.3, ignore.taxonomy = TRUE)
	checkEquals(colnames(mods@annotation), "Module")
	checkEquals(anyDuplicated(mods@annotation$Module), 0)
	checkEquals(ncol(mods@abundance), 2)
}
