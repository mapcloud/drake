#' @title Load the basic example from \code{drake_example("basic")}
#' @description Use \code{\link{drake_example}('basic')} to get the code
#' for the basic example. The included R script is a detailed,
#' heavily-commented walkthrough. The quickstart vignette at
#' \url{https://github.com/wlandau-lilly/drake/blob/master/vignettes/quickstart.Rmd} # nolint
#' and \url{https://wlandau-lilly.github.io/drake/articles/quickstart.html}
#' also walks through the basic example.
#' @details This function also writes/overwrites
#' the file, \code{report.Rmd}.
#' @export
#' @return A \code{\link{drake_config}()} configuration list.
#' @param envir The environment to load the example into.
#' Defaults to your workspace.
#' For an insulated workspace,
#' set \code{envir = new.env(parent = globalenv())}.
#' @param cache Optional \code{storr} cache to use.
#' @param report_file where to write the report file \code{report.Rmd}.
#' @param to deprecated, where to write the dynamic report source file
#' \code{report.Rmd}
#' @param overwrite logical, whether to overwrite an
#' existing file \code{report.Rmd}
#' @param verbose logical, whether to print console messages.
#' @param force logical, whether to force the loading of a
#' non-back-compatible cache from a previous version of drake.
#' @examples
#' \dontrun{
#' test_with_dir("Quarantine side effects.", {
#' # Populate your workspace and write 'report.Rmd'.
#' load_basic_example() # Get the code: drake_example("basic")
#' # Check the dependencies of an imported function.
#' deps(reg1)
#' # Check the dependencies of commands in the workflow plan.
#' deps(my_plan$command[1])
#' deps(my_plan$command[4])
#' # Plot the interactive network visualization of the workflow.
#' config <- drake_config(my_plan)
#' vis_drake_graph(config)
#' # Run the workflow to build all the targets in the plan.
#' make(my_plan)
#' # Remove the whole cache.
#' clean(destroy = TRUE)
#' # Clean up the imported file.
#' unlink('report.Rmd')
#' })
#' }
load_basic_example <- function(
  envir = parent.frame(),
  cache = NULL,
  report_file = "report.Rmd",
  overwrite = FALSE,
  to = report_file,
  verbose = TRUE,
  force = FALSE
){
  if (to != report_file){
    warning(
      "In load_basic_example(), argument 'to' is deprecated. ",
      "Use 'report_file' instead."
    )
  }

  eval(parse(text = "base::require(drake, quietly = TRUE)"))
  eval(parse(text = "base::require(knitr, quietly = TRUE)"))

  # User-defined functions
  envir$simulate <- function(n) {
    data.frame(x = stats::rnorm(n), y = rpois(n, 1))
  }

  envir$reg1 <- function(d) {
    lm(y ~ +x, data = d)
  }

  envir$reg2 <- function(d) {
    d$x2 <- d$x ^ 2
    lm(y ~ x2, data = d)
  }

  # construct workflow plan

  # remove 'undefinded globals' errors in R CMD check
  large <- small <-
    simulate <- knit <- my_knit <- report_dependencies <-
    reg1 <- reg2 <- coef_regression2_small <- NULL

  datasets <- drake_plan(small = simulate(5), large = simulate(50))

  methods <- drake_plan(list = c(
    regression1 = "reg1(dataset__)",
    regression2 = "reg2(dataset__)"))

  # Same as evaluate_plan(methods, wildcard = 'dataset__',
  #   values = datasets$output).
  analyses <- plan_analyses(methods, datasets = datasets)

  summary_types <- drake_plan(list = c(
    summ = "suppressWarnings(summary(analysis__))",
    coef = "coefficients(analysis__)"))

  # plan_summaries() also uses evaluate_plan(): once with expand = TRUE,
  # once with expand = FALSE
  # skip 'gather' (drake_plan my_plan is more readable)
  results <- plan_summaries(summary_types, analyses, datasets, gather = NULL)

  # External file targets and dependencies should be
  # single-quoted.  Use double quotes to remove any special
  # meaning from character strings.  Single quotes inside
  # imported functions are ignored, so this mechanism only
  # works inside the drake_plan my_plan data frame.  WARNING:
  # drake cannot track entire directories (folders).
  report <- drake_plan(report.md = knit("report.Rmd", quiet = TRUE),
    file_targets = TRUE, strings_in_dots = "filenames")

  # Row order doesn't matter in the drake_plan my_plan.
  envir$my_plan <- rbind(report, datasets,
    analyses, results)

  # Write the R Markdown source for a dynamic knitr report
  report <- system.file(
    file.path("examples", "basic", "report.Rmd"),
    package = "drake",
    mustWork = TRUE
  )
  if (file.exists(report_file) & overwrite){
    warning("Overwriting file 'report.Rmd'.")
  }
  file.copy(from = report, to = report_file, overwrite = overwrite)
  invisible(drake_config(
    plan = envir$my_plan,
    envir = envir,
    cache = cache,
    force = force,
    verbose = verbose
  ))
}
