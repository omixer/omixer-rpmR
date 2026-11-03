# x is a dataframe or a valid file path
# Add the Description of modules as a data object
rpm <- function(x, minimum.coverage = -1, score.estimator = "median", annotation = 1, module.db = NULL, threads = 1,
                normalize.by.length = FALSE, distribute = FALSE, java.mem = NULL, complex.rule = "any",
                ignore.taxonomy = FALSE) {
  # link to the GMMs executable and DB
  rpm.exec <- system.file("java", "omixer-rpm.jar", package = "omixerRpm")
  if (is.null(module.db)) {
    module.db <- loadDefaultDB()
  }

  # Prepare output directories
  out.dir <- tempfile()
  dir.create(out.dir)

  # a HUMAnN table's header starts with #, which read.table() treats as a comment: the first data row then becomes
  # the header, so samples and values are lost before rpm() sees them. omixer-rpm reads the file itself instead.
  if (annotation == "humann" && !is.character(x)) {
    stop("annotation = \"humann\" needs the path of the HUMAnN table, not a data.frame: read.table() drops its ",
         "header line (it starts with #), so the first row of data would be lost. Pass the file path to rpm().")
  }

  # Is x a file or a data.frame
  if (!is.character(x)) {
    # write samples for processing with the GMMs
    in.dir <- tempfile()
    dir.create(in.dir)
    input <- file.path(in.dir, "input.tsv")
    write.table(x, input, col.names = T, row.names = F, quote = F, sep = "\t")
  } else {
    input <- x
  }

  # Compiling the command
  command <- "java -server"

  if (!is.null(java.mem)) {
    command <- paste(command, paste0("-Xmx", java.mem, "G"))
  }

  command <- paste(command, "-jar", rpm.exec,
                   "-c", minimum.coverage,
                   "-s", score.estimator,
                   "-d", file.path(module.db@directory, module.db@modules),
                   "-i", input,
                   "-o", out.dir,
                   "-a", annotation,
                   "-t", threads,
                   "-e", 2,
                   "--complex-rule", complex.rule)
  if (normalize.by.length == TRUE) {
    command <- paste(command, "-n")
  }

  if (distribute == TRUE) {
    command <- paste(command, "--Xdistribute")
  }

  # one result per sample instead of per taxon of a sample (annotation 2, or a stratified HUMAnN table)
  if (ignore.taxonomy == TRUE) {
    command <- paste(command, "--ignore-taxonomic-info")
  }

  # Run the module mapping
  tryCatch({
    status <- system(command)
    if (status != 0) {
      stop("The execution of Omixer-RPM returned a non-zero exit status. Refer to the exception output for details.")
    }
  },
    warning = function(e) {
      print(e)
      if (e$message == "error in running command") {
        stop(e)
      }
    },
    error = function(e) {
      print(geterrmessage())
      stop(e)
    }
  )

  # omixer-rpm 2.0 exits with a non-zero status on errors (1.x did not); kept as a safety net
  if (!file.exists(file.path(out.dir, "modules.tsv"))) {
    stop("Omixer-RPM did not produce any output. See the error message above.")
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