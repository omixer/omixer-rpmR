\name{runShinyRpm}
\alias{runShinyRpm}
\title{
Run omixer-rpm from a web interface
}
\description{
Starts a Shiny app in the browser: upload a KO table, choose the module database and the options of \code{rpm},
then browse and download the module abundance and coverage tables.
}
\usage{
runShinyRpm(...)
}
\arguments{
  \item{...}{
Passed on to \code{shiny::runApp}, e.g. \code{port} or \code{launch.browser}.
}
}
\details{
The app needs the packages shiny, bslib and DT, which are not installed with omixerRpm:
\code{install.packages(c("shiny", "bslib", "DT"))}.
}
\seealso{
\code{\link{rpm}}
}
\examples{
\dontrun{
runShinyRpm()
}
}
