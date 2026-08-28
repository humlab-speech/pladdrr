# Helper: skip parallel-batch tests on CRAN, but run them under covr so the
# parallel code paths are measured. covr does not set NOT_CRAN, so the plain
# skip_on_cran() would also skip them during coverage measurement even though
# they execute in CI (NOT_CRAN=true).

skip_parallel_on_cran <- function() {
  in_covr <- requireNamespace("covr", quietly = TRUE) && covr::in_covr()
  skip_if(!identical(Sys.getenv("NOT_CRAN"), "true") && !in_covr)
}
