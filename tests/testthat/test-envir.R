drake_context("envir")

test_with_dir("prune_envir in full build", {
  # drake_plan with lots of nested deps This will fail if
  # prune_envir() doesn't work.
  datasets <- drake_plan(x = 1, y = 2, z = 3)
  methods <- drake_plan(
    a = dataset__,
    b = dataset__,
    c = dataset__
  )
  analyses <- plan_analyses(methods, datasets)
  heuristics <- drake_plan(
    s = c(dataset__, analysis__),
    t = analysis__)
  summaries <- plan_summaries(
    heuristics,
    datasets = datasets,
    analyses = analyses,
    gather = c("rbind", "rbind")
  )
  output <- drake_plan(
    final1 = mean(s) + mean(t),
    final2 = mean(s) - mean(t),
    waitforme = c(a_x, c_y, s_b_x, t_a_z),
    waitformetoo = c(waitforme, y)
  )
  plan <- rbind(datasets, analyses, summaries, output)

  # set up a workspace to test prune_envir()
  # set verbose to TRUE to see log of loading
  config <- drake_config(
    plan,
    targets = plan$target,
    envir = new.env(parent = globalenv()),
    verbose = FALSE
  )

  # actually run
  testrun(config)
  expect_true(all(plan$target %in% cached()))

  # Check that the right things are loaded and the right things
  # are discarded
  remove(list = ls(config$envir), envir = config$envir)
  expect_equal(ls(config$envir), character(0))
  prune_envir(datasets$target, config)
  expect_equal(ls(config$envir), character(0))
  prune_envir(analyses$target, config)
  expect_equal(ls(config$envir), c("x", "y", "z"))
  prune_envir("waitforme", config)

  # keep y around for waitformetoo
  expect_equal(
    ls(config$envir),
    c("a_x", "c_y", "s_b_x", "t_a_z", "y")
  )
})
