\name{ModuleDB}
\alias{ModuleDB}
\alias{ModuleDB-class}
\alias{getNames}
\alias{getNames,ModuleDB-method}
\alias{getHierarchy}
\alias{getHierarchy,ModuleDB-method}
\title{
Module database
}
\description{
Locates the files of a module database: the module definitions, the module names and, optionally, a module
hierarchy. \code{getNames} and \code{getHierarchy} look up modules in it.
}
\usage{
ModuleDB(...)
\S4method{getNames}{ModuleDB}(theObject, x)
\S4method{getHierarchy}{ModuleDB}(theObject, x, level)
}
\arguments{
  \item{...}{
The slots: \code{directory}, the directory of the database files; \code{modules}, the module definition file
(default module.list); \code{module.names.file}, a tab-separated file of module id and name (default module.names);
\code{hierarchy.file}, a tab-separated file of module id and hierarchy levels (default hierarchy.tsv; none is
bundled).
}
  \item{theObject}{
A \code{ModuleDB}.
}
  \item{x}{
Module ids.
}
  \item{level}{
The hierarchy level (column of the hierarchy file).
}
}
\value{
\code{ModuleDB} returns the database; \code{getNames} the names of the modules, \code{getHierarchy} their hierarchy
level; NA for a module that is not in the file.
}
\author{
Youssef Darzi
}
\seealso{
\code{\link{loadDB}} for the bundled databases.
}
\examples{
\dontrun{
db <- ModuleDB(directory = "/path/to/moduledb/", modules = "GBMs.v1.0.txt", module.names.file = "GBMs.v1.0.names")
# Serotonin synthesis I
getNames(db, "MGB001")
}
}
