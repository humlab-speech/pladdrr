# helper-windows-crash-probe.R
#
# Windows crash isolation for test bodies that abort R silently under MSVC
# (Rtools gcc 13/14). Praat's vendored DSP paths (PowerCepstrum trend
# fitting / peak prominence / smoothing, voice_report on an empty
# PointProcess, direct Rcpp-Module calls) can kill the whole R process during
# Windows R CMD check. Historically these tests were `skip_on_os("windows")`,
# which hid the aborts: the Windows job went green while real crashes went
# unexercised.
#
# `probe_test()` replaces `test_that()` for those bodies:
#   * non-Windows platforms: the body runs inline, exactly as before;
#   * Windows: the body runs inside an isolated child R process (base R
#     Rscript via system2 -- deliberately not callr, to avoid an undeclared
#     test dependency). If the child aborts (nonzero exit) -- or any
#     expectation fails -- the parent test FAILS with the child's status and
#     output, and the rest of the suite survives.
#
# The child runs the body inside testthat::test_that(), which exits non-zero
# on both assertion failures and R aborts, so the probe reports the true state
# instead of silently skipping.
#
# Local verification override (machinery test without Windows):
#   PLADDRR_FORCE_WINDOWS_PROBE=true Rscript -e '...'

probe_test <- function(desc, code, preamble = NULL) {
  expr <- substitute(code)
  env <- parent.frame()
  test_that(desc, {
    windows_crash_probe(desc, expr, preamble, env = env)
  })
}

windows_crash_probe <- function(desc, code_expr, preamble = NULL, env = parent.frame()) {
  force(desc)
  if (!isTRUE(as.logical(Sys.getenv("PLADDRR_FORCE_WINDOWS_PROBE", "false"))) &&
      .Platform$OS.type != "windows") {
    eval(code_expr, envir = env)
    return(invisible(TRUE))
  }

  body <- deparse1(code_expr, collapse = "\n")
  pre <- paste(preamble, collapse = "\n")
  script <- tempfile(fileext = ".R")
  writeLines(c(
    "library(testthat)",
    "library(pladdrr)",
    pre,
    sprintf("testthat::test_that(%s, {\n%s\n})", deparse(desc), body)
  ), script)
  on.exit(unlink(script), add = TRUE)

  # Base-R child process: Rscript + system2. A child that aborts (MSVC crash)
  # or fails its expectations exits non-zero; system2 surfaces that as the
  # 'status' attribute.
  rscript <- file.path(R.home("bin"), "Rscript")
  out <- suppressWarnings(system2(rscript, shQuote(script), stdout = TRUE, stderr = TRUE))
  status <- attr(out, "status")
  if (is.null(status)) status <- 0L
  detail <- paste(out, collapse = "\n")
  testthat::expect_equal(
    status, 0L,
    info = sprintf(
      "Windows crash probe '%s' exited with status %s. This is a REAL abort or failure in pladdrr C++ on Windows -- fix the crash, do not skip the test. Child output:\n%s",
      desc, status, detail
    )
  )
  invisible(TRUE)
}
