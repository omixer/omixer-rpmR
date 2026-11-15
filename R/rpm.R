#' Metabolic module profiling for gut microbiome samples
#'
#' Generates metabolic module profiles from metagenomic samples.
#'
#' @param x A data.frame or a file path containing functional profiles with KEGG KO annotation. Taxonomic annotation
#'   could be included as well. See `annotation` for more info on the formatting. A HUMAnN table (annotation
#'   `"humann"`) must be given as a file path: its header starts with #, which `read.table()` drops, so a data.frame
#'   is refused.
#' @param minimum.coverage The minimum pathway coverage to consider a module present. If set to -1 the threshold is
#'   guessed from the data. Otherwise the value should be between 0 and 1. By default it is set to -1.
#' @param score.estimator One of `"median"`, `"average"`, `"sum"` or `"min"` to estimate the abundance of the module.
#'   Default is median.
#' @param annotation Data annotation. Use 1 for KEGG KO annotation only or 2 for taxonomic followed by KO annotation.
#'   Use `"humann"` for a HUMAnN gene family table regrouped to KOs (`humann_regroup_table --groups uniref90_ko`),
#'   optionally renormalized and joined into one table (`humann_join_tables`): results are per taxon from its
#'   stratified rows (KO|taxon, unclassified included), or per sample from its community totals with
#'   `ignore.taxonomy = TRUE`; a table without strata gives results per sample. Rows such as UNMAPPED and UNGROUPED
#'   and KO names are ignored, and sample names lose HUMAnN's _Abundance suffix.
#' @param module.db A [ModuleDB] object to locate the database files. If omitted the GMMs database from Vieira-Silva,
#'   et al 2016 Nat Microbiol (doi:10.1038/nmicrobiol.2016.88) will be used by default.
#' @param threads The number of threads to use when mapping KOs onto modules. If > 1, each different thread will
#'   handle one sample at a time, therefore the number of threads should never be larger than the number of samples.
#' @param normalize.by.length Divide module score by its length. When combined with a median estimator, missing
#'   reactions (score = 0) are included when estimating the median. If the estimated score equals zero then it is
#'   replaced by the minimum observed reaction score. If this option is specified, score calculation is based only on
#'   the number of observed reactions.
#' @param distribute Experimental feature - When an ortholog is shared by N modules then its abundance is divided by
#'   N.
#' @param java.mem The maximum amount of memory (in Gb) to allocate for the underlying omixer-rpm.jar tool. Value is an
#'   Integer comprised between 1 and the RAM size.
#' @param complex.rule How a complex step (subunits written K1,K2 in the module database) counts when only some
#'   subunits are observed. `"any"` (default): the step is present when at least one subunit is observed, since a
#'   missing subunit is more often unsampled than absent. `"all"`: the step is present only when every subunit is
#'   observed; otherwise it gets no coverage and no abundance.
#' @param ignore.taxonomy For taxon-annotated input (annotation 2, or a stratified HUMAnN table), infer the modules of
#'   each whole sample instead of each taxon of a sample. For HUMAnN tables, the community total rows are used (never
#'   added to their strata).
#' @return A [Modules] object: the abundance and coverage of the modules (rows) per sample (columns), their key columns
#'   (Module, or Taxon and Module for results per taxon), the module database and the coverage cutoff (`@cutoff`, the
#'   learned one with `minimum.coverage = -1`). [asDataFrame()] turns it into one
#'   table with the module descriptions.
#' @section Java:
#' omixer-rpm needs Java 21 or newer. `rpm()` runs `JAVA_HOME/bin/java` when the environment variable `JAVA_HOME`
#' points to a Java installation, and otherwise `java` from the `PATH`. Set it for a session with
#' `Sys.setenv(JAVA_HOME = "/path/to/jdk-21")`, or for good in `~/.Renviron`.
#' @author Youssef Darzi
#' @seealso [asDataFrame()], [loadDB()], [runShinyRpm()]
#' @examples
#' \dontrun{
#' # read a functional profile matrix into R or create it inside R. Please note that row.names should not be used
#' # while reading the matrix.
#' dat <- read.table("matrix.tsv", header = TRUE, sep = "\t")
#' # Run the module mapping on the loaded table.
#' mods <- rpm(dat, minimum.coverage = 0.3, annotation = 1)
#' # alternatively run the mapping without loading the table into R.
#' mods <- rpm("matrix.tsv", minimum.coverage = 0.3, annotation = 1)
#' # Load the default mapping database
#' db <- loadDefaultDB()
#' # get the name of the first predicted module
#' getNames(db, mods@annotation[1, ])
#' # a HUMAnN KO table: per taxon, or per sample with ignore.taxonomy
#' mods <- rpm("ko.tsv", annotation = "humann")
#' mods <- rpm("ko.tsv", annotation = "humann", ignore.taxonomy = TRUE)
#' }
#' @export
rpm <- function(x, minimum.coverage = -1, score.estimator = "median", annotation = 1, module.db = NULL, threads = 1,
                normalize.by.length = FALSE, distribute = FALSE, java.mem = NULL, complex.rule = "any",
                ignore.taxonomy = FALSE) {
  rpm.exec <- system.file("java", "omixer-rpm.jar", package = "omixerRpm")
  if (is.null(module.db)) {
    module.db <- loadDefaultDB()
  }

  out.dir <- tempfile()
  dir.create(out.dir)
  on.exit(unlink(out.dir, recursive = TRUE), add = TRUE)

  # a HUMAnN table's header starts with #, which read.table() treats as a comment: the first data row then becomes
  # the header, so samples and values are lost before rpm() sees them. omixer-rpm reads the file itself instead.
  if (annotation == "humann" && !is.character(x)) {
    stop(
      "annotation = \"humann\" needs the path of the HUMAnN table, not a data.frame: read.table() drops its ",
      "header line (it starts with #), so the first row of data would be lost. Pass the file path to rpm()."
    )
  }

  # a data.frame is written to a file for omixer-rpm
  if (!is.character(x)) {
    input <- tempfile(fileext = ".tsv")
    on.exit(unlink(input), add = TRUE)
    write.table(x, input, col.names = TRUE, row.names = FALSE, quote = FALSE, sep = "\t")
  } else {
    input <- x
  }

  java <- .javaCommand()
  if (!nzchar(java)) {
    stop("Java was not found: omixer-rpm needs Java 21 or newer, in JAVA_HOME or on the PATH.")
  }

  # the java arguments, one element each, so that paths with spaces stay one argument
  args <- if (is.null(java.mem)) character(0) else paste0("-Xmx", java.mem, "G")
  args <- c(
    args, "-jar", rpm.exec,
    "-c", minimum.coverage,
    "-s", score.estimator,
    "-d", file.path(module.db@directory, module.db@modules),
    "-i", input,
    "-o", out.dir,
    "-a", annotation,
    "-t", threads,
    "-e", 2,
    "--complex-rule", complex.rule
  )
  if (isTRUE(normalize.by.length)) {
    args <- c(args, "-n")
  }
  if (isTRUE(distribute)) {
    args <- c(args, "--Xdistribute")
  }
  # one result per sample instead of per taxon of a sample (annotation 2, or a stratified HUMAnN table)
  if (isTRUE(ignore.taxonomy)) {
    args <- c(args, "--ignore-taxonomic-info")
  }

  # omixer-rpm writes its log and error messages to the console: collected in a file, shown once it has finished,
  # and its errors become the message of the R error
  log.file <- tempfile(fileext = ".log")
  on.exit(unlink(log.file), add = TRUE)
  status <- system2(java, shQuote(args), stdout = log.file, stderr = log.file)
  log <- readLines(log.file, warn = FALSE)
  writeLines(log)
  if (status != 0) {
    stop(.runError(log, status), call. = FALSE)
  }

  abundance <- read.table(file.path(out.dir, "modules.tsv"), sep = "\t", header = TRUE)
  coverage <- read.table(file.path(out.dir, "modules-coverage.tsv"), sep = "\t", header = TRUE)

  # the key columns, from the output itself: Taxon and Module for results per taxon (annotation 2, or a stratified
  # HUMAnN table without ignore.taxonomy), Module alone otherwise
  keys <- if (colnames(abundance)[1] == "Taxon") c(1, 2) else 1
  annotation.df <- abundance[, keys, drop = FALSE]
  abundance <- abundance[, -keys, drop = FALSE]
  coverage <- coverage[, -keys, drop = FALSE]

  Modules(abundance = abundance, coverage = coverage, annotation = annotation.df, db = module.db, cutoff = .cutoff(log))
}

# the coverage cutoff of a run, from omixer-rpm's "Coverage cutoff: 0.6" line; NA for "none (no module observed)"
.cutoff <- function(log) {
  line <- grep("Coverage cutoff: ", log, fixed = TRUE, value = TRUE)
  value <- suppressWarnings(as.numeric(sub(".*Coverage cutoff: ", "", line)))
  if (length(value) == 1) value else NA_real_
}

# the java to run: JAVA_HOME/bin/java when JAVA_HOME holds one (as Gradle and Maven do), else java from the PATH;
# "" when there is none
.javaCommand <- function() {
  java.home <- Sys.getenv("JAVA_HOME")
  if (nzchar(java.home)) {
    java <- file.path(java.home, "bin", if (.Platform$OS.type == "windows") "java.exe" else "java")
    if (file.exists(java)) {
      return(java)
    }
  }
  unname(Sys.which("java"))
}

# the message of a failed run: omixer-rpm's ERROR lines without their timestamp and source, or the last line of its
# output when it failed before logging (e.g. a Java older than 21)
.runError <- function(log, status) {
  errors <- sub("^.*:ERROR - [^|]*\\| ", "", grep(":ERROR - ", log, value = TRUE))
  if (length(errors) == 0) {
    lines <- log[nzchar(trimws(log))]
    errors <- lines[length(lines)]
  }
  if (any(grepl("UnsupportedClassVersionError", log))) {
    errors <- c(errors, "omixer-rpm needs Java 21 or newer.")
  }
  paste(c(paste0("Omixer-RPM failed (exit status ", status, "):"), errors), collapse = "\n")
}
