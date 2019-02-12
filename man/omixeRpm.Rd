\name{omixerRpm-package}
\alias{omixerRpm-package}
\alias{omixerRpm}
\docType{package}
\title{
\packageTitle{omixerRpm}
}
\description{
\packageDescription{omixerRpm}
}
\details{

The DESCRIPTION file:
\packageDESCRIPTION{omixerRpm}
\packageIndices{omixerRpm}
~~ An overview of how to use the package, including the most important ~~
~~ functions ~~

}
\author{
\packageAuthor{omixerRpm}

Maintainer: \packageMaintainer{omixerRpm}
}
\references{
~~ Literature or other references for background information ~~
omixerRpm was developed as part of GOmixer. If you use omixerRpm in your work please cite: 

Darzi, et al. Towards biome-specific analysis of meta-omics data, The ISME journal, 2015. http://www.nature.com/articles/ismej2015188

In case you use the bundled GMMs database, please also cite Vieira-Silva, et al. Species-function relationships shape ecological properties 
of the human gut microbiome, Nature Microbiology, 2016 .http://www.nature.com/articles/nmicrobiol201688

}
\keyword{ package , microbiome, gut, metagenomics, metabolic pathways }
\seealso{
~~ Optional links to other man pages, e.g. ~~
~~ \code{\link[<pkg>:<pkg>-package]{<pkg>}} ~~
}
\examples{
\dontrun{
# read a functional profile matrix into R or create it inside R. Please note that row.names should not be used while reading the matrix. 
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
