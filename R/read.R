#' @title Read and return a drake target or import from the cache.
#' @description Does not delete the item from the cache.
#' @seealso \code{\link{loadd}}, \code{\link{cached}},
#' \code{\link{built}}, \code{link{imported}}, \code{\link{drake_plan}},
#' \code{\link{make}}
#' @export
#' @return The cached value of the \code{target}.
#' @param target If \code{character_only} is \code{TRUE},
#' \code{target} is a character string naming the object to read.
#' Otherwise, \code{target} is an unquoted symbol with the name of the
#' object. Note: \code{target} could be the name of an imported object.
#' @param character_only logical, whether \code{name} should be treated
#' as a character or a symbol
#' (just like \code{character.only} in \code{\link{library}()}).
#' @param path Root directory of the drake project,
#' or if \code{search} is \code{TRUE}, either the
#' project root or a subdirectory of the project.
#' @param search logical. If \code{TRUE}, search parent directories
#' to find the nearest drake cache. Otherwise, look in the
#' current working directory only.
#' @param cache optional drake cache. See code{\link{new_cache}()}.
#' If \code{cache} is supplied,
#' the \code{path} and \code{search} arguments are ignored.
#' @param namespace character scalar,
#' name of an optional storr namespace to read from.
#' @param verbose whether to print console messages
#' @examples
#' \dontrun{
#' test_with_dir("Quarantine side effects.", {
#' load_basic_example() # Get the code with drake_example("basic").
#' make(my_plan) # Run the project, build the targets.
#' readd(reg1) # Return imported object 'reg1' from the cache.
#' readd(small) # Return targets 'small' from the cache.
#' readd("large", character_only = TRUE) # Return 'large' from the cache.
#' # For external files, only the fingerprint/hash is stored.
#' readd("'report.md'")
#' })
#' }
readd <- function(
  target,
  character_only = FALSE,
  path = getwd(),
  search = TRUE,
  cache = drake::get_cache(path = path, search = search, verbose = verbose),
  namespace = NULL,
  verbose = TRUE
){
  # if the cache is null after trying get_cache:
  if (is.null(cache)){
    stop("cannot find drake cache.")
  }
  if (!character_only){
    target <- as.character(substitute(target))
  }
  if (is.null(namespace)){
    namespace <- cache$default_namespace
  }
  cache$get(target, namespace = namespace)
}

#' @title Load multiple targets or imports from the drake cache.
#' @description Loads the object(s) into the
#' current workspace (or \code{envir} if given). Defaults
#' to loading the whole cache if arguments \code{...}
#' and \code{list} are not set
#' (or all the imported objects if in addition
#' imported_only is \code{TRUE}).
#' @seealso \code{\link{cached}}, \code{\link{built}},
#' \code{\link{imported}}, \code{\link{drake_plan}}, \code{\link{make}},
#' @export
#' @return \code{NULL}
#'
#' @param ... targets to load from the cache, as names (unquoted)
#' or character strings (quoted). Similar to \code{...} in
#' \code{\link{remove}(...)}.
#'
#' @param list character vector naming targets to be loaded from the
#' cache. Similar to the \code{list} argument of \code{\link{remove}()}.
#'
#' @param imported_only logical, whether only imported objects
#' should be loaded.
#'
#' @param cache optional drake cache. See code{\link{new_cache}()}.
#' If \code{cache} is supplied,
#' the \code{path} and \code{search} arguments are ignored.
#'
#' @param path Root directory of the drake project,
#' or if \code{search} is \code{TRUE}, either the
#' project root or a subdirectory of the project.
#'
#' @param search logical. If \code{TRUE}, search parent directories
#' to find the nearest drake cache. Otherwise, look in the
#' current working directory only.
#'
#' @param namespace character scalar,
#' name of an optional storr namespace to load from.
#'
#' @param envir environment to load objects into. Defaults to the
#' calling environment (current workspace).
#'
#' @param jobs number of parallel jobs for loading objects. On
#' non-Windows systems, the loading process for multiple objects
#' can be lightly parallelized via \code{parallel::mclapply()}.
#' just set jobs to be an integer greater than 1. On Windows,
#' \code{jobs} is automatically demoted to 1.
#'
#' @param verbose logical, whether to print console messages
#'
#' @param deps logical, whether to load any cached
#' dependencies of the targets
#' instead of the targets themselves.
#' This is useful if you know your
#' target failed and you want to debug the command in an interactive
#' session with the dependencies in your workspace.
#' One caveat: to find the dependencies,
#' \code{\link{loadd}()} uses information that was stored
#' in a \code{\link{drake_config}()} list and cached
#' during the last \code{\link{make}()}.
#' That means you need to have already called \code{\link{make}()}
#' if you set \code{deps} to \code{TRUE}.
#'
#' @param lazy logical, whether to lazy load with
#' \code{delayedAssign()} rather than the more eager
#' \code{assign()}.
#'
#' @examples
#' \dontrun{
#' test_with_dir("Quarantine side effects.", {
#' load_basic_example() # Get the code with drake_example("basic").
#' make(my_plan) # Run the projects, build the targets.
#' loadd(small) # Load target 'small' into your workspace.
#' small
#' # For many targets, you can parallelize loadd()
#' # using the 'jobs' argument.
#' loadd(list = c("small", "large"), jobs = 2)
#' # Load the dependencies of the target, coef_regression2_small
#' loadd(coef_regression2_small, deps = TRUE)
#' # Load all the imported objects/functions.
#' loadd(imported_only = TRUE)
#' # Load everything, including built targets.
#' # Be sure your computer has enough memory.
#' loadd()
#' })
#' }
loadd <- function(
  ...,
  list = character(0),
  imported_only = FALSE,
  path = getwd(),
  search = TRUE,
  cache = drake::get_cache(path = path, search = search, verbose = verbose),
  namespace = NULL,
  envir = parent.frame(),
  jobs = 1,
  verbose = 1,
  deps = FALSE,
  lazy = FALSE
){
  if (is.null(cache)){
    stop("cannot find drake cache.")
  }
  force(envir)
  dots <- match.call(expand.dots = FALSE)$...
  targets <- targets_from_dots(dots, list)
  if (!length(targets)){
    targets <- cache$list(namespace = cache$default_namespace)
  }
  if (imported_only){
    plan <- read_drake_plan(cache = cache)
    targets <- imported_only(targets = targets, plan = plan, jobs = jobs)
  }
  if (!length(targets)){
    stop("no targets to load.")
  }
  if (deps){
    config <- read_drake_config(cache = cache)
    targets <- dependencies(targets = targets, config = config)
    exists <- lightly_parallelize(
      X = targets,
      FUN = cache$exists,
      jobs = jobs
    ) %>%
      unlist
    targets <- targets[exists]
  }
  lightly_parallelize(
    X = targets, FUN = load_target, cache = cache,
    namespace = namespace, envir = envir,
    verbose = verbose, lazy = lazy
  )
  invisible()
}

load_target <- function(target, cache, namespace, envir, verbose, lazy){
  if (lazy){
    lazy_load_target(
      target = target,
      cache = cache,
      namespace = namespace,
      envir = envir,
      verbose = verbose
    )
  } else {
    eager_load_target(
      target = target,
      cache = cache,
      namespace = namespace,
      envir = envir,
      verbose = verbose
    )
  }
}

eager_load_target <- function(target, cache, namespace, envir, verbose){
  value <- readd(
    target,
    character_only = TRUE,
    cache = cache,
    namespace = namespace,
    verbose = verbose
  )
  assign(x = target, value = value, envir = envir)
  local <- environment()
  rm(value, envir = local)
  invisible()
}

lazy_load_target <- function(target, cache, namespace, envir, verbose){
  eval_env <- environment()
  delayedAssign(
    x = target,
    value = readd(
      target,
      character_only = TRUE,
      cache = cache,
      namespace = namespace,
      verbose = verbose
    ),
    eval.env = eval_env,
    assign.env = envir
  )
}

#' @title Read the cached \code{\link{drake_config}()}
#' list from the last \code{\link{make}()}.
#' @description See \code{\link{drake_config}()} for more information
#' about drake's internal runtime configuration parameter list.
#' @seealso \code{\link{make}}
#' @export
#' @return The cached master internal configuration list
#' of the last \code{\link{make}()}.
#' @param cache optional drake cache. See code{\link{new_cache}()}.
#' If \code{cache} is supplied,
#' the \code{path} and \code{search} arguments are ignored.
#' @param path Root directory of the drake project,
#' or if \code{search} is \code{TRUE}, either the
#' project root or a subdirectory of the project.
#' @param search logical. If \code{TRUE}, search parent directories
#' to find the nearest drake cache. Otherwise, look in the
#' current working directory only.
#' @param verbose whether to print console messages
#' @param jobs number of jobs for light parallelism.
#' Supports 1 job only on Windows.
#' @param envir Optional environment to fill in if
#' \code{config$envir} was not cached. Defaults to your workspace.
#' @examples
#' \dontrun{
#' test_with_dir("Quarantine side effects.", {
#' load_basic_example() # Get the code with drake_example("basic").
#' make(my_plan) # Run the project, build the targets.
#' # Retrieve the master internal configuration list from the cache.
#' read_drake_config()
#' })
#' }
read_drake_config <- function(
  path = getwd(),
  search = TRUE,
  cache = NULL,
  verbose = 1,
  jobs = 1,
  envir = parent.frame()
){
  force(envir)
  if (is.null(cache)) {
    cache <- get_cache(path = path, search = search, verbose = verbose)
  }
  if (is.null(cache)) {
    stop("cannot find drake cache.")
  }
  keys <- cache$list(namespace = "config")
  out <- lightly_parallelize(
    X = keys,
    FUN = function(item){
      cache$get(key = item, namespace = "config")
    },
    jobs = jobs
  )
  names(out) <- keys
  if (is.null(out$envir)){
    out$envir <- envir
  }
  out
}

#' @title Read the workflow plan
#' from your last attempted call to \code{\link{make}()}.
#' @description Uses the cache.
#' @seealso \code{\link{read_drake_config}}
#' @export
#' @return A workflow plan data frame.
#' @param cache optional drake cache. See code{\link{new_cache}()}.
#' If \code{cache} is supplied,
#' the \code{path} and \code{search} arguments are ignored.
#' @param path Root directory of the drake project,
#' or if \code{search} is \code{TRUE}, either the
#' project root or a subdirectory of the project.
#' @param search logical. If \code{TRUE}, search parent directories
#' to find the nearest drake cache. Otherwise, look in the
#' current working directory only.
#' @param verbose whether to print console messages
#' @examples
#' \dontrun{
#' test_with_dir("Quarantine side effects.", {
#' load_basic_example() # Get the code with drake_example("basic").
#' make(my_plan) # Run the project, build the targets.
#' read_drake_plan() # Retrieve the workflow plan data frame from the cache.
#' })
#' }
read_drake_plan <- function(
  path = getwd(),
  search = TRUE,
  cache = NULL,
  verbose = TRUE
){
  if (is.null(cache)){
    cache <- get_cache(path = path, search = search, verbose = verbose)
  }
  if (is.null(cache)){
    stop("cannot find drake cache.")
  }
  if (cache$exists(key = "plan", namespace = "config")){
    cache$get(key = "plan", namespace = "config")
  } else {
    drake_plan()
  }
}

#' @title Read the igraph dependency network
#' from your last attempted call to \code{\link{make}()}.
#' @description For more user-friendly graphing utilities,
#' see \code{\link{vis_drake_graph}()}
#' and related functions.
#' @seealso \code{\link{vis_drake_graph}}, \code{\link{read_drake_config}}
#' @export
#' @return An \code{igraph} object representing the dependency
#' network of the workflow.
#' @param cache optional drake cache. See code{\link{new_cache}()}.
#' If \code{cache} is supplied,
#' the \code{path} and \code{search} arguments are ignored.
#' @param path Root directory of the drake project,
#' or if \code{search} is \code{TRUE}, either the
#' project root or a subdirectory of the project.
#' @param search logical. If \code{TRUE}, search parent directories
#' to find the nearest drake cache. Otherwise, look in the
#' current working directory only.
#' @param verbose logical, whether to print console messages
#' @param ... arguments to \code{visNetwork()} via
#' \code{\link{vis_drake_graph}()}
#' @examples
#' \dontrun{
#' test_with_dir("Quarantine side effects.", {
#' load_basic_example() # Get the code with drake_example("basic").
#' make(my_plan) # Run the project, build the targets.
#' # Retrieve the igraph network from the cache.
#' g <- read_drake_graph()
#' class(g) # "igraph"
#' })
#' }
read_drake_graph <- function(
  path = getwd(),
  search = TRUE,
  cache = NULL,
  verbose = 1,
  ...
){
  if (is.null(cache)){
    cache <- get_cache(path = path, search = search, verbose = verbose)
  }
  if (is.null(cache)){
    stop("cannot find drake cache.")
  }
  if (cache$exists(key = "graph", namespace = "config")){
    cache$get(key = "graph", namespace = "config")
  } else {
    make_empty_graph()
  }
}

#' @title Read the metadata of a target or import.
#' @description The metadata helps determine if the
#' target is up to date or outdated. The metadata of imports
#' is used to compute the metadata of targets.
#' @details Target metadata is computed
#' with \code{drake_meta()} and then
#' \code{drake:::finish_meta()}.
#' This metadata corresponds
#' to the state of the target immediately after it was built
#' or imported in the last \code{\link{make}()} that
#' did not skip it.
#' The exception to this is the \code{$missing} element
#' of the metadata, which indicates if the target/import
#' was missing just \emph{before} it was built.
#' @seealso \code{\link{dependency_profile}}, \code{\link{make}}
#' @export
#' @return The cached master internal configuration list
#' of the last \code{\link{make}()}.
#' @param targets character vector, names of the targets
#' to get metadata. If \code{NULL}, all metadata is collected.
#' @param cache optional drake cache. See code{\link{new_cache}()}.
#' If \code{cache} is supplied,
#' the \code{path} and \code{search} arguments are ignored.
#' @param path Root directory of the drake project,
#' or if \code{search} is \code{TRUE}, either the
#' project root or a subdirectory of the project.
#' @param search logical. If \code{TRUE}, search parent directories
#' to find the nearest drake cache. Otherwise, look in the
#' current working directory only.
#' @param verbose whether to print console messages
#' @param jobs number of jobs for light parallelism.
#' Supports 1 job only on Windows.
#' @examples
#' \dontrun{
#' test_with_dir("Quarantine side effects.", {
#' load_basic_example() # Get the code with drake_example("basic").
#' make(my_plan) # Run the project, build the targets.
#' # Retrieve the build decision metadata for one target.
#' read_drake_meta(targets = "small")
#' # Retrieve the build decision metadata for all targets,
#' # parallelizing over 2 jobs.
#' read_drake_meta(jobs = 2)
#' })
#' }
read_drake_meta <- function(
  targets = NULL,
  path = getwd(),
  search = TRUE,
  cache = NULL,
  verbose = 1,
  jobs = 1
){
  if (is.null(cache)) {
    cache <- get_cache(path = path, search = search, verbose = verbose)
  }
  if (is.null(cache)) {
    stop("cannot find drake cache.")
  }
  if (is.null(targets)){
    targets <- cache$list(namespace = "meta")
  } else {
    targets <- parallel_filter(
      x = targets,
      f = function(target){
        cache$exists(key = target, namespace = "meta")
      },
      jobs = jobs
    )
  }
  out <- lightly_parallelize(
    X = targets,
    FUN = function(target){
      cache$get(key = target, namespace = "meta")
    },
    jobs = jobs
  )
  names(out) <- targets
  if (length(out) == 1){
    out <- out[[1]]
  }
  out
}
