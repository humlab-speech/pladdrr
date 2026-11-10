# R CMD check --as-cran exports _R_CHECK_LIMIT_CORES_ and CRAN's timing check
# notes any example whose CPU time exceeds 2.5x its elapsed time. The default
# thread pool used every core, so the CPPS examples ran at 4-6x. The automatic
# default must therefore follow the variable the way parallel:::.check_ncores
# does. The pool size is read once per process, so each case is a child process.

child_with <- function(value, code) {
  # NA means genuinely unset: the child inherits the parent's environment, so
  # the variable is removed here (R CMD check --as-cran exports it as TRUE).
  # The variable goes through Sys.setenv/unsetenv, not system2(env=): on Windows
  # system2 pastes env into the command line instead of the child's environment.
  old <- Sys.getenv("_R_CHECK_LIMIT_CORES_", NA)
  on.exit(if (is.na(old)) Sys.unsetenv("_R_CHECK_LIMIT_CORES_") else
    Sys.setenv("_R_CHECK_LIMIT_CORES_" = old), add = TRUE)
  if (is.na(value)) Sys.unsetenv("_R_CHECK_LIMIT_CORES_") else
    Sys.setenv("_R_CHECK_LIMIT_CORES_" = value)
  system2(file.path(R.home("bin"), "Rscript"), c("-e", shQuote(code)),
    stdout = TRUE, stderr = FALSE)
}

processors_with <- function(value) {
  out <- child_with(value,
    "suppressMessages(library(pladdrr)); cat('P=', pladdrr_threads()$max_threads, '\\n')")
  as.integer(sub(".*P= *", "", grep("P=", out, value = TRUE)))
}

test_that("an NA value really leaves the variable unset in the child", {
  skip_on_cran()
  code <- "cat('U=', is.na(Sys.getenv('_R_CHECK_LIMIT_CORES_', NA)), '\\n')"
  expect_match(child_with(NA, code), "U= TRUE")
  expect_match(child_with("", code), "U= FALSE")
})

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
  old <- Sys.getenv("_R_CHECK_LIMIT_CORES_", NA)
  on.exit(if (is.na(old)) Sys.unsetenv("_R_CHECK_LIMIT_CORES_") else
    Sys.setenv("_R_CHECK_LIMIT_CORES_" = old), add = TRUE)
  Sys.setenv("_R_CHECK_LIMIT_CORES_" = "TRUE")
  out <- system2(file.path(R.home("bin"), "Rscript"),
    c("-e", shQuote("suppressMessages(library(pladdrr)); pladdrr_threads(4); cat('P=', pladdrr_threads()$max_threads, '\\n')")),
    stdout = TRUE, stderr = FALSE)
  expect_identical(as.integer(sub(".*P= *", "", grep("P=", out, value = TRUE))), 4L)
})
