# x is a dataframe or a valid file path
# Add the Description of modules as a data object
rpm <- function(x, minimum.coverage=-1, score.estimator="median", annotation = 1, module.db = NULL, threads = 1,
		normalize.by.length = FALSE, distribute = FALSE, java.mem=NULL) {
	# link to the GMMs executable and DB
	rpm.exec <- system.file("java", "omixer-rpm.jar", package = "omixerRpm")
	if(is.null(module.db)) {
		module.db.path <- system.file("extdata", package = "omixerRpm")
		module.db <- ModuleDB(directory = module.db.path, modules = "GMMs.v1.07.txt")
	}
	
	# Prepare output directories
	out.dir <- tempfile()
	dir.create(out.dir)
	
	# Is x a file or a data.frame
	if(!is.character(x)) {
		# write samples for processing with the GMMs
		in.dir <- tempfile()
		dir.create(in.dir)
		input <- file.path(in.dir, "input.tsv")
		write.table(x, input, col.names=T, row.names=F, quote=F, sep="\t")		
	} else {
		input <- x
	}

	# Compiling the command
	command <- "java -server"
	
	if(!is.null(java.mem)){
		command <- paste(command, paste0("-Xmx", java.mem, "G"))
	}
	
	command <- paste(command , "-jar", rpm.exec, 
			"-c" , minimum.coverage,
			"-s", score.estimator,
			"-d", file.path(module.db@directory, module.db@modules),
			"-i", input,
			"-o", out.dir,
			"-a", annotation,
			"-t", threads,
			"-e", 2) 
	if( normalize.by.length == TRUE) { 
		command <-paste(command, "-n")
	}
	
	if( distribute == TRUE) { 
		command <-paste(command, "--Xdistribute")
	}
	
	# Run the module mapping 
	tryCatch({
				system(command)
			},
			error = function (e) {
				print(geterrmessage())
				stop(e)
	})

	abundance <- read.table(file.path(out.dir, "modules.tsv"), sep="\t", header=TRUE)
	coverage <- read.table(file.path(out.dir, "modules-coverage.tsv"), sep="\t", header=TRUE)
	
	annotation.df <- NULL
	
	if (annotation == 1){
		# ortohology only 
		abundance.colnames <- colnames(abundance)
		annotation.df <- as.data.frame(abundance[, 1])
		abundance <- as.data.frame(abundance[, -c(1)])
		coverage <- as.data.frame(coverage[, -c(1)])
		colnames(annotation.df) <- abundance.colnames[1]
		colnames(abundance) <- abundance.colnames[2:length(abundance.colnames)]
		colnames(coverage) <- abundance.colnames[2:length(abundance.colnames)]
	} else if (annotation == 2) {
		# orthology and taxonomy
		abundance.colnames <- colnames(abundance)
		annotation.df <- as.data.frame(abundance[, c(1, 2)])
		abundance <- as.data.frame(abundance[, -c(1, 2)])
		coverage <- as.data.frame(coverage[, -c(1, 2)])
		colnames(annotation.df) <- abundance.colnames[1:2]
		colnames(abundance) <- abundance.colnames[3:length(abundance.colnames)]
		colnames(coverage) <- abundance.colnames[3:length(abundance.colnames)]
	}
	
	Modules(abundance=abundance, coverage=coverage, annotation=annotation.df) 
}