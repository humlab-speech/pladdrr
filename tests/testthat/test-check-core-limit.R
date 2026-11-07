# R CMD check --as-cran exports _R_CHECK_LIMIT_CORES_ and CRAN's timing check
# notes any example whose CPU time exceeds 2.5x its elapsed time. The default
# thread pool used every core, so the CPPS examples ran at 4-6x. The automatic
# default must therefore follow the variable the way parallel:::.check_ncores
# does. The pool size is read once per process, so each case is a child process.

processors_with <- function(value) {
  env <- if (is.na(value)) character() else paste0("_R_CHECK_LIMIT_CORES_=", value)
  out <- system2(file.path(R.home("bin"), "Rscript"),
    c("-e", shQuote("suppressMessages(library(pladdrr)); cat('P=', pladdrr_threads()$max_threads, '\\n')")),
    stdout = TRUE, stderr = FALSE, env = env)
  as.integer(sub(".*P= *", "", grep("P=", out, value = TRUE)))
}

test_that("the automatic thread cap is two under R CMD check", {
  skip_on_cran()
  for (v in c("TRUE", "true", "warn", "1")) {
    expect_identical(processors_with(v), 2L, info = v)
  }
})

test_that("the cap does not apply when the variable is unset, empty or false", {
  skip_on_cran()
  skip_if(parallel::detectCores() < 3, "needs three or more CPUs to tell 2 from all")
  unlimited <- processors_with(NA)
  expect_gt(unlimited, 2L)
  expect_identical(processors_with("false"), unlimited)
  expect_identical(processors_with("FALSE"), unlimited)
  expect_identical(processors_with(""), unlimited)
})

test_that("an explicit pladdrr_threads(n) still beats the check limit", {
  skip_on_cran()
  skip_if(parallel::detectCores() < 4, "needs four or more CPUs")
  out <- system2(file.path(R.home("bin"), "Rscript"),
    c("-e", shQuote("suppressMessages(library(pladdrr)); pladdrr_threads(4); cat('P=', pladdrr_threads()$max_threads, '\\n')")),
    stdout = TRUE, stderr = FALSE, env = "_R_CHECK_LIMIT_CORES_=TRUE")
  expect_identical(as.integer(sub(".*P= *", "", grep("P=", out, value = TRUE))), 4L)
})
