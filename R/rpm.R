# x is a data.frame or the path of the input file
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
    stop("annotation = \"humann\" needs the path of the HUMAnN table, not a data.frame: read.table() drops its ",
         "header line (it starts with #), so the first row of data would be lost. Pass the file path to rpm().")
  }

  # a data.frame is written to a file for omixer-rpm
  if (!is.character(x)) {
    input <- tempfile(fileext = ".tsv")
    on.exit(unlink(input), add = TRUE)
    write.table(x, input, col.names = T, row.names = F, quote = F, sep = "\t")
  } else {
    input <- x
  }

  if (Sys.which("java") == "") {
    stop("Java was not found: omixer-rpm needs Java 21 or newer on the PATH.")
  }

  # the java arguments, one element each, so that paths with spaces stay one argument
  args <- if (is.null(java.mem)) character(0) else paste0("-Xmx", java.mem, "G")
  args <- c(args, "-jar", rpm.exec,
            "-c", minimum.coverage,
            "-s", score.estimator,
            "-d", file.path(module.db@directory, module.db@modules),
            "-i", input,
            "-o", out.dir,
            "-a", annotation,
            "-t", threads,
            "-e", 2,
            "--complex-rule", complex.rule)
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
  status <- system2("java", shQuote(args), stdout = log.file, stderr = log.file)
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

  Modules(abundance = abundance, coverage = coverage, annotation = annotation.df, db = module.db)
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
