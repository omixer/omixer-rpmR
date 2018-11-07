\name{ModuleDB}
\alias{ModuleDB}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
%%  ~~function to do ... ~~
Module database locator.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
A simple object to locate the files of a module database.
}
\usage{
ModuleDB(directory, modules, hierarchy.file, module.names.file)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{directory}{
The path to the directory containing all the module database files
}
  \item{modules}{
The name of the module definition file in the database. Defaults to modules.list.
The file should follow the KEGG format for module definition
}
  \item{hierarchy.file}{
The name of the module hierarchy definition file in the database. Defaults to hierarchy.tsv
}
  \item{module.names.file}{
The name of the module names file in the database. Defaults to modules.names
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
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or do  help(data=index)  for the standard data sets.

## The function is currently defined as
function (x, minimum.coverage = -1) 
{
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }% use one of  RShowDoc("KEYWORDS")
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
