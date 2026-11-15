library(omixerRpm)

# Ensures correct number of modules and samples is returned
test.moduleMapping <- function() {
  # Test for data.frame, KO only annotation
  dat <- read.table("data/matrix.tsv", header = T, sep = "\t")
  mods <- rpm(dat, minimum.coverage = 0.3, annotation = 1)
  checkEquals(nrow(mods@coverage), 96)
  checkEquals(nrow(mods@abundance), 96)
  checkEquals(ncol(mods@abundance), 2)
  db <- loadDefaultDB()
  # Test annotation is properly set; modules follow the database order
  checkEquals(getNames(db, mods@annotation[1, ]), "arabinoxylan degradation")

  # Test for an input file with KO, taxonomic annotation
  taxon.mods <- rpm("data/species_matrix.tsv", annotation = 2, minimum.coverage = 0.3)
  checkEquals(nrow(taxon.mods@coverage), 284)
  checkEquals(ncol(taxon.mods@coverage), 2)
}

test.callOptions <- function() {
  # check default
  mods <- rpm("data/matrix.tsv", annotation = 1, minimum.coverage = 0.66)
  checkEquals(mods@abundance[which(mods@annotation == "MF0004"), "S1"], 5457.398359)

  # check with length normalization
  mods <- rpm("data/matrix.tsv", annotation = 1, minimum.coverage = 0.66, normalize.by.length = TRUE)
  checkEquals(mods@abundance[which(mods@annotation == "MF0004"), "S1"], 708.5907183)

  # check with length normalization AND --Xdistribute
  mods <- rpm("data/matrix.tsv", annotation = 1, minimum.coverage = 0.66, normalize.by.length = TRUE, distribute = TRUE)
  checkEquals(mods@abundance[which(mods@annotation == "MF0004"), "S1"], 236.1969061)
}

test.moduleDbAnnotation <- function() {
  # Setup the default module database.
  db <- loadDefaultDB()
  # check getNames returns the correct annotation
  checkEquals(getNames(db, "MF0010"), "sucrose degradation I")
  # several modules at once; NA for an unknown module
  checkEquals(
    getNames(db, c("MF0010", "unknown", "MF0001")),
    c("sucrose degradation I", NA, "arabinoxylan degradation")
  )
  # a database made with ModuleDB() reads the names from its file
  db <- ModuleDB(
    directory = system.file("extdata", package = "omixerRpm"), modules = "GMMs.v1.07.txt",
    module.names.file = "GMMs.v1.07.names"
  )
  checkEquals(getNames(db, "MF0010"), "sucrose degradation I")
}


test.asDataFrame <- function() {
  # check default
  mods <- rpm("data/matrix.tsv", annotation = 1, minimum.coverage = 0.3)
  coverage <- asDataFrame(mods, "coverage")
  checkEquals(nrow(coverage), 96)
  checkEquals(ncol(coverage), 4)
  # modules follow the database order
  checkEquals(as.character(coverage[1, "Description"]), "arabinoxylan degradation")
  checkEquals(as.character(coverage[96, "Description"]), "mucin degradation")
  checkEquals(colnames(coverage), c("Module", "Description", "S1", "S2"))

  # per taxon: the Taxon and Module columns are kept
  coverage <- asDataFrame(rpm("data/species_matrix.tsv", annotation = 2, minimum.coverage = 0.3), "coverage")
  checkEquals(colnames(coverage)[1:3], c("Taxon", "Module", "Description"))

  # a database made with ModuleDB(): same table
  db <- ModuleDB(
    directory = system.file("extdata", package = "omixerRpm"), modules = "GMMs.v1.07.txt",
    module.names.file = "GMMs.v1.07.names"
  )
  checkEquals(
    asDataFrame(rpm("data/matrix.tsv", minimum.coverage = 0.3, module.db = db), "coverage"),
    asDataFrame(mods, "coverage")
  )
}


test.moduleDbList <- function() {
  # List available databases.
  db <- listDB()
  checkEquals(db[1], "GBMs.v1.0")
  checkEquals(db[2], "GMMs.v1.07")
}

test.moduleDbLoad <- function() {
  # Setup the default module database.
  db <- loadDB("GMMs.v1.07")
  # check getNames returns the correct annotation
  checkEquals(getNames(db, "MF0010"), "sucrose degradation I")
}

test.handleMalformedInput <- function() {
  # a taxon matrix given as annotation 1
  checkException(rpm("data/species_matrix.tsv", annotation = 1, minimum.coverage = 0.3))
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
  checkException(rpm("data/matrix.tsv", annotation = 1, minimum.coverage = 0.3, complex.rule = "fraction"))
}

# A HUMAnN KO table (humann_regroup_table, humann_rename_table): MF0003 is K01051, then K01184,K01213 or K18650.
# B. fragilis has both steps, unclassified only K01051; special rows and KO names are ignored, and the
# _Abundance-RPKs suffix is removed from the sample names
test.humann <- function() {
  db <- loadDB("GMMs.v1.07")

  # per taxon (stratified rows only)
  mods <- rpm("data/humann_ko.tsv", annotation = "humann", minimum.coverage = 0.3, module.db = db)
  checkEquals(colnames(mods@annotation), c("Taxon", "Module"))
  checkEquals(colnames(mods@abundance), c("S1", "S2"))
  fragilis <- which(
    mods@annotation$Taxon == "g__Bacteroides.s__Bacteroides_fragilis" & mods@annotation$Module == "MF0003"
  )
  checkEquals(mods@coverage[fragilis, "S1"], 1)
  checkEquals(mods@abundance[fragilis, "S1"], 3.5)
  unclassified <- which(mods@annotation$Taxon == "unclassified" & mods@annotation$Module == "MF0003")
  checkEquals(mods@coverage[unclassified, "S1"], 0.5)

  # per sample (community totals only, never added to their strata)
  mods <- rpm("data/humann_ko.tsv",
    annotation = "humann", minimum.coverage = 0.3, module.db = db, ignore.taxonomy = TRUE
  )
  checkEquals(colnames(mods@annotation), "Module")
  checkEquals(mods@annotation$Module, "MF0003")
  checkEquals(unlist(mods@abundance[1, ]), c(S1 = 4.5, S2 = 3.5))

  # a table read into R is refused: read.table() turns its first data row into the header
  dat <- read.table("data/humann_ko.tsv", header = TRUE, sep = "\t")
  checkException(rpm(dat, annotation = "humann", minimum.coverage = 0.3, module.db = db))

  # a table without strata (humann --remove-stratified-output) gives one result per sample
  totals <- tempfile(fileext = ".tsv")
  writeLines(grep("|", readLines("data/humann_ko.tsv"), fixed = TRUE, invert = TRUE, value = TRUE), totals)
  mods <- rpm(totals, annotation = "humann", minimum.coverage = 0.3, module.db = db)
  checkEquals(colnames(mods@annotation), "Module")
  checkEquals(unlist(mods@abundance[1, ]), c(S1 = 4.5, S2 = 3.5))
}

test.humannDirectoryRejected <- function() {
  checkException(rpm("data", annotation = "humann", minimum.coverage = 0.3))
}

test.ignoreTaxonomy <- function() {
  # a taxon matrix per sample: one row per module, as for annotation 1
  mods <- rpm("data/species_matrix.tsv", annotation = 2, minimum.coverage = 0.3, ignore.taxonomy = TRUE)
  checkEquals(colnames(mods@annotation), "Module")
  checkEquals(anyDuplicated(mods@annotation$Module), 0)
  checkEquals(ncol(mods@abundance), 2)
}

# the cutoff of the run: the given one, or the learned one
test.cutoff <- function() {
  checkEquals(rpm("data/matrix.tsv", minimum.coverage = 0.3)@cutoff, 0.3)
  learned <- rpm("data/matrix.tsv")@cutoff
  checkTrue(learned > 0 && learned <= 1)
  # the learned cutoff is the one omixer-rpm applies: the same modules as with that fixed cutoff
  checkEquals(rpm("data/matrix.tsv")@annotation, rpm("data/matrix.tsv", minimum.coverage = learned)@annotation)
  # no module observed: no cutoff
  checkTrue(is.na(rpm(data.frame(entry = "K99999", S1 = 1))@cutoff))
}

# a failed run stops with omixer-rpm's own message
test.errorMessage <- function() {
  message <- tryCatch(rpm("data/species_matrix.tsv", annotation = 1, minimum.coverage = 0.3),
    error = conditionMessage
  )
  checkTrue(grepl("species_matrix.tsv, line 2: ", message, fixed = TRUE))
  checkTrue(grepl("is not KO<TAB>one abundance per sample", message, fixed = TRUE))
  checkTrue(!grepl("ERROR - ", message, fixed = TRUE))

  # a command line error
  message <- tryCatch(rpm("data/matrix.tsv", annotation = 1, minimum.coverage = 0.3, complex.rule = "fraction"),
    error = conditionMessage
  )
  checkTrue(grepl("fraction", message, fixed = TRUE))
}

test.pathWithSpaces <- function() {
  dir <- file.path(tempfile(), "a folder")
  dir.create(dir, recursive = TRUE)
  file.copy("data/matrix.tsv", file.path(dir, "my matrix.tsv"))
  mods <- rpm(file.path(dir, "my matrix.tsv"), annotation = 1, minimum.coverage = 0.66)
  checkEquals(mods@abundance[which(mods@annotation == "MF0004"), "S1"], 5457.398359)
}

# runs code with the given PATH and JAVA_HOME, then restores them
withJava <- function(path, java.home, code) {
  saved <- Sys.getenv(c("PATH", "JAVA_HOME"), unset = NA)
  on.exit({
    Sys.setenv(PATH = saved[["PATH"]])
    if (is.na(saved[["JAVA_HOME"]])) Sys.unsetenv("JAVA_HOME") else Sys.setenv(JAVA_HOME = saved[["JAVA_HOME"]])
  })
  Sys.setenv(PATH = path)
  if (is.na(java.home)) Sys.unsetenv("JAVA_HOME") else Sys.setenv(JAVA_HOME = java.home)
  code
}

test.javaNotFound <- function() {
  message <- withJava(tempdir(), NA, tryCatch(rpm("data/matrix.tsv", annotation = 1), error = conditionMessage))
  checkTrue(grepl("Java was not found", message, fixed = TRUE))
}

# JAVA_HOME/bin/java runs, even when java is not on the PATH
test.javaHome <- function() {
  java.home <- dirname(dirname(normalizePath(Sys.which("java"))))
  mods <- withJava(tempdir(), java.home, rpm("data/matrix.tsv", annotation = 1, minimum.coverage = 0.66))
  checkEquals(mods@abundance[which(mods@annotation == "MF0004"), "S1"], 5457.398359)

  # a JAVA_HOME without java: the PATH is used
  mods <- withJava(Sys.getenv("PATH"), tempdir(), rpm("data/matrix.tsv", annotation = 1, minimum.coverage = 0.66))
  checkEquals(mods@abundance[which(mods@annotation == "MF0004"), "S1"], 5457.398359)
}

# JAVA_HOME comes before the PATH: a fake java there is the one that runs
test.javaHomeFirst <- function() {
  if (.Platform$OS.type == "windows") {
    return()
  }
  java.home <- file.path(tempfile(), "fake jdk")
  dir.create(file.path(java.home, "bin"), recursive = TRUE)
  java <- file.path(java.home, "bin", "java")
  writeLines(c("#!/bin/sh", "echo 'the fake java ran'", "exit 1"), java)
  Sys.chmod(java, "755")
  message <- withJava(Sys.getenv("PATH"), java.home, tryCatch(rpm("data/matrix.tsv", annotation = 1),
    error = conditionMessage
  ))
  checkTrue(grepl("the fake java ran", message, fixed = TRUE))
}
