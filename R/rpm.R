#' Metabolic module profiling
#'
#' Runs omixer-rpm on KEGG KO profiles: the abundance and coverage of each module per sample (or per taxon of a
#' sample).
#'
#' @param x A data.frame or the path of a tab-separated file: KO profiles, one column per sample, after the KO column
#'   (and the taxon column before it, see `annotation`). A HUMAnN table must be a file path.
#' @param minimum.coverage The coverage (0 to 1) a module needs to be reported; -1 (default) learns it from the data.
#' @param score.estimator How a module's abundance is estimated from its steps: `"median"` (default), `"average"`,
#'   `"sum"` or `"min"`.
#' @param annotation The input format: `1` (default) KOs only; `2` taxon, then KO; `"humann"` a HUMAnN KO table
#'   (`humann_regroup_table --groups uniref90_ko`, optionally renormalized and joined), per taxon from its stratified
#'   rows, or per sample with `ignore.taxonomy = TRUE` or without strata.
#' @param module.db A [ModuleDB]; default the gut metabolic modules ([loadDefaultDB()]).
#' @param threads The number of threads; profiles are scored in parallel.
#' @param normalize.by.length Count the unobserved steps of a module: `"sum"` and `"average"` are divided by its number
#'   of steps, and `"median"` includes them as 0 (a median of 0 becomes the lowest observed step score).
#' @param distribute Experimental: divide the abundance of a KO shared by N modules by N.
#' @param java.mem The maximum Java heap, in GB; default Java's own.
#' @param complex.rule When a complex step (KOs written K1,K2 in the database) is present: `"any"` (default) when at
#'   least one subunit is observed, `"all"` only when every subunit is.
#' @param ignore.taxonomy For input per taxon (annotation 2, or a stratified HUMAnN table): one result per sample
#'   instead of per taxon. HUMAnN tables use their community totals.
#' @return A [Modules] object: the abundance and coverage of the modules (rows) per sample (columns), their key columns
#'   (Module, or Taxon and Module), the database and the coverage cutoff (`@cutoff`). [asDataFrame()] turns it into a
#'   table.
#' @section Java:
#' omixer-rpm needs Java 21 or newer. `rpm()` runs `JAVA_HOME/bin/java` when `JAVA_HOME` is set, otherwise `java` from
#' the `PATH`, e.g. `Sys.setenv(JAVA_HOME = "/path/to/jdk-21")`.
#' @author Youssef Darzi
#' @seealso [asDataFrame()], [loadDB()], [runShinyRpm()]
#' @examples
#' \dontrun{
#' # check.names = FALSE keeps the sample names as they are
#' dat <- read.table("matrix.tsv", header = TRUE, sep = "\t", check.names = FALSE)
#' mods <- rpm(dat, minimum.coverage = 0.3)
#' # or from the file
#' mods <- rpm("matrix.tsv", minimum.coverage = 0.3)
#' getNames(loadDefaultDB(), mods@annotation$Module)
#' # a HUMAnN KO table: per taxon, or per sample
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

  # check.names = FALSE: the sample names as in the input (read.table() would turn S-1 into S.1 and 1A into X1A)
  abundance <- read.table(file.path(out.dir, "modules.tsv"), sep = "\t", header = TRUE, check.names = FALSE)
  coverage <- read.table(file.path(out.dir, "modules-coverage.tsv"), sep = "\t", header = TRUE, check.names = FALSE)

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
