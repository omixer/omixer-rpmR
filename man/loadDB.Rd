\name{loadDB}
\alias{loadDB}
\alias{loadDefaultDB}
\alias{listDB}
\title{
Bundled module databases
}
\description{
\code{listDB} lists the module databases bundled with the package, \code{loadDB} loads one of them and
\code{loadDefaultDB} loads the default, the gut metabolic modules GMMs.v1.07.
}
\usage{
listDB()
loadDB(name)
loadDefaultDB()
}
\arguments{
  \item{name}{
A database name, as listed by \code{listDB}.
}
}
\value{
\code{listDB} returns the database names; \code{loadDB} and \code{loadDefaultDB} return a \code{\link{ModuleDB}}.
}
\author{
Youssef Darzi
}
\examples{
listDB()
db <- loadDB("GBMs.v1.0")
getNames(db, "MGB001")
}
