#' @title List the targets that are out of date.
#' @description Outdated targets will be rebuilt in the next
#' \code{\link{make}()}.
#' @details \code{outdated()} is sensitive to the alternative triggers
#' described at
#' \url{https://github.com/wlandau-lilly/drake/blob/master/vignettes/debug.Rmd#test-with-triggers}. # nolint
#' For example, even if \code{outdated(...)} shows everything up to date,
#' \code{outdated(..., trigger = "always")} will show
#' all targets out of date.
#' You must use a fresh \code{config} argument with an up-to-date
#' \code{config$targets} element that was never modified by hand.
#' If needed, rerun \code{\link{drake_config}()} early and often.
#' See the details in the help file for \code{\link{drake_config}()}.
#' @export
#' @seealso \code{\link{missed}}, \code{\link{drake_plan}},
#' \code{\link{make}}, \code{\link{vis_drake_graph}}
#' @return Character vector of the names of outdated targets.
#' @param config option internal runtime parameter list of
#' \code{\link{make}(...)},
#' produced with \code{\link{drake_config}()}.
#' You must use a fresh \code{config} argument with an up-to-date
#' \code{config$targets} element that was never modified by hand.
#' If needed, rerun \code{\link{drake_config}()} early and often.
#' See the details in the help file for \code{\link{drake_config}()}.
#' @param make_imports logical, whether to make the imports first.
#' Set to \code{FALSE} to save some time and risk obsolete output.
#' @examples
#' \dontrun{
#' test_with_dir("Quarantine side effects.", {
#' load_basic_example() # Get the code with drake_example("basic").
#' # Recopute the config list early and often to have the
#' # most current information. Do not modify the config list by hand.
#' config <- drake_config(my_plan)
#' outdated(config = config) # Which targets are out of date?
#' config <- make(my_plan) # Run the projects, build the targets.
#' # Now, everything should be up to date (no targets listed).
#' outdated(config = config)
#' # outdated() is sensitive to triggers.
#' # See the "debug" vignette for more on triggers.
#' config$trigger <- "always"
#' outdated(config = config)
#' })
#' }
outdated <-  function(config, make_imports = TRUE){
  do_prework(config = config, verbose_packages = config$verbose)
  if (make_imports){
    make_imports(config = config)
  }
  first_targets <- next_stage(config = config)
  later_targets <- downstream_nodes(
    from = first_targets,
    graph = config$graph,
    jobs = config$jobs
  )
  c(first_targets, later_targets) %>%
    as.character %>%
    unique %>%
    sort
}

#' @title Report any import objects required by your drake_plan
#' plan but missing from your workspace.
#' @description Checks your workspace/environment and
#' file system.
#' @export
#' @seealso \code{\link{outdated}}
#' @return Character vector of names of missing objects and files.
#'
#' @param config internal runtime parameter list of
#' \code{\link{make}(...)},
#' produced by both \code{\link{drake_config}()} and \code{\link{make}()}.
#'
#' @examples
#' \dontrun{
#' test_with_dir("Quarantine side effects.", {
#' config <- load_basic_example() # Get the code with drake_example("basic").
#' missed(config) # All the imported files and objects should be present.
#' rm(reg1) # Remove an import dependency from you workspace.
#' missed(config) # Should report that reg1 is missing.
#' })
#' }
missed <- function(config){
  imports <- setdiff(V(config$graph)$name, config$plan$target)
  is_missing <- lightly_parallelize(
    X = imports,
    FUN = function(x){
      missing_import(x, envir = config$envir)
    },
    jobs = config$jobs
  ) %>%
    as.logical
  if (!any(is_missing)){
    return(character(0))
  }
  imports[is_missing]
}
