% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/make.R
\name{make_imports}
\alias{make_imports}
\title{Just make the imports.}
\usage{
make_imports(config)
}
\arguments{
\item{config}{a configuration list returned by \code{\link{config}()}}
}
\value{
The master internal configuration list
used by \code{\link{make}()}.
}
\description{
Imports are non-targets that the targets
in your workflow plan data frame (see \code{\link{drake_plan}()})
may depend on.
Imports could be files in storage, functions, or generic objects
in your workspace or environment.
}
\examples{
\dontrun{
test_with_dir("Quarantine side effects.", {
load_basic_example() # Get the code with drake_example("basic").
# Generate the master internal configuration list.
con <- drake_config(my_plan)
# Just cache the imports, do not build any targets.
make_imports(config = con)
# Just make the targets
make_targets(config = con)
})
}
}
\seealso{
\code{\link{make}}, \code{\link{config}},
\code{\link{make_targets}}
}
