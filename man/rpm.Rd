\name{rpm}
\alias{rpm}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
%%  ~~function to do ... ~~
Metabolic module profiling for gut microbiome samples
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
Generates metabolic module profiles from metagenomic samples.
}
\usage{
rpm(x, minimum.coverage = -1, score.estimator = "median", 
    annotation = 1, module.db = NULL, threads = 1, normalize.by.length = FALSE, distribute = FALSE, java.mem = NULL)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{x}{
A data.frame or a file path containing functional profiles with KEGG KO annotation. Taxonomic annotation could be included as well.
See annotation for more info on the formating
}
  \item{minimum.coverage}{
The minimum pathway coverage to consider a module present.
If set to -1 the threshold is guessed from the data. Otherwise the value should be between 0 and 1 [0, 1].
By default it is set to -1.
}
  \item{score.estimator}{
One of [median|average|sum|min] to estimate the abundance of the module. Default is median.
}
  \item{annotation}{
Data annotation. Use 1 for KEGG KO annotation only or 2 for taxonomic followed by KO annotation.
}
  \item{module.db}{
A ModuleDB object to locate the database files. If omitted the GMMS database from Vieira-Silva, et al 2016 Nat Microbiol (doi:10.1038/nmicrobiol.2016.88)
will be used by default.
}
  \item{threads}{
The number of threads to use when mapping KOs onto modules. If > 1, each different thread will handle one sample at a time, therefore the number
of threads should never be larger than the number of samples.
}
  \item{normalize.by.length}{
Divide module score by its length. When combined with a median estimator, missing reactions (score = 0 )
are included when estimating the median. If the estimated score equals zero then it is replaced by
the minimum observed reaction score. If this option is specified, score calculation is based only on
the number of observed reactions 
} 
  \item{distribute}{
Experimental feature - When an ortholog is shared by N modules then its abundance is divided by N.
}
  \item{java.mem}{
The maximum amount of memory (in Gb) to allocate for the underlying omixer-rpm.jar tool. Value is an Integer comprised between 1 and the RAM size.
} 

}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of 'comp1'}
%%  \item{comp2 }{Description of 'comp2'}
%% ...
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
%%  ~~who you are~~
Youssef Darzi
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
\dontrun{
# read a functional profile matrix into R or create it inside R
dat <- read.table("matrix.tsv", header=T, sep="\t")
# Run the module mapping on the loaded table.
mods <- rpm(dat, minimum.coverage=0.3, annotation = 1)
# alternatively run the mapping without loading the table into R.
mods <- rpm("matrix.tsv", minimum.coverage=0.3, annotation = 1)
# Load the default mapping database
db <- loadDefaultDB()
# get the name of the first predicted module
getNames(db, mods@annotation[1,]) 
}
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }% use one of  RShowDoc("KEYWORDS")
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
