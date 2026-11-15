\name{Modules}
\alias{Modules}
\alias{Modules-class}
\alias{asDataFrame}
\alias{asDataFrame,Modules-method}
\title{
Module profiles
}
\description{
The result of \code{\link{rpm}}: the abundance and coverage of the modules per sample. \code{asDataFrame} gives one
of them as a table with the module descriptions.
}
\usage{
Modules(...)
\S4method{asDataFrame}{Modules}(theObject, type)
}
\arguments{
  \item{...}{
The slots: \code{abundance} and \code{coverage}, data.frames of the modules (rows) per sample (columns);
\code{annotation}, the key columns of the rows (Module, or Taxon and Module); \code{db}, the \code{\link{ModuleDB}}.
}
  \item{theObject}{
A \code{Modules} object.
}
  \item{type}{
"abundance" or "coverage".
}
}
\value{
\code{asDataFrame} returns a data.frame: the key columns, the module Description, then one column per sample.
}
\author{
Youssef Darzi
}
\examples{
\dontrun{
mods <- rpm("matrix.tsv", minimum.coverage = 0.3)
coverage <- asDataFrame(mods, "coverage")
}
}
