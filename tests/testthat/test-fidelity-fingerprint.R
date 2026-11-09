# Fidelity fingerprint: 87 numbers from one fixed synthetic signal, covering the
# tier-1 R6 methods, the direct/batch/ultra entry points, Ltas, Intensity, DTW,
# PCA and TextGrid. It exists because a change to DSP arithmetic or to a unit/enum
# mapping shows up as a moved number long before any hand-written expectation
# notices: the Ltas energy mean was off by 1e3 and the Intensity "energy" mean was
# the median (3e-6 relative), and both sat unseen in the suite.
#
# Values were recorded on macOS arm64 with the audit's fixes applied and checked
# against Linux x86-64 values: every row agrees to rtol 1e-6 except the three
# rows with their own tolerance below (a quantity near zero, and two that go
# through a threaded/accumulating path whose last digits depend on the platform).
# To re-record after an INTENDED change:
#   Rscript tests/testthat/fingerprint/golden.R | grep -v '^simd\.\|GOLDEN_END' \
#     > tests/testthat/fingerprint/expected.tsv
# and explain every moved key in NEWS.

read_tsv_kv <- function(lines) {
  lines <- lines[grepl("\t", lines, fixed = TRUE)]
  parts <- strsplit(lines, "\t", fixed = TRUE)
  setNames(vapply(parts, `[`, "", 2L), vapply(parts, `[`, "", 1L))
}

# key -> c(mode, tolerance); everything else is relative 1e-6 (or absolute 1e-12).
tolerance <- list(
  sound.mean = c("abs", 1e-12),
  # Windows (MinGW) lands 4% off the recorded Linux/macOS value (0.3488 vs 0.3633).
  gne.mean = c("rel", if (.Platform$OS.type == "windows") 6e-2 else 1e-2),
  formantpath.f1_at_0.5 = c("rel", 1e-3))

run_fingerprint <- function() {
  script <- file.path(tempdir(), "fingerprint-child.R")
  writeLines(c(
    sprintf('.libPaths(c("%s", .libPaths()))',
      dirname(getNamespaceInfo("pladdrr", "path"))),
    sprintf('source("%s", chdir = FALSE)',
      testthat::test_path("fingerprint", "golden.R"))), script)
  suppressWarnings(system2(file.path(R.home("bin"), "Rscript"), shQuote(script),
    stdout = TRUE, stderr = FALSE))
}

test_that("every fingerprint row produces a number", {
  skip_on_cran()
  got <- read_tsv_kv(run_fingerprint())
  got <- got[!grepl("^simd\\.", names(got))]
  dead <- got[grepl("^(ERR|NA|NONFINITE)", got)]
  expect_length(dead, 0L)
  if (length(dead)) fail(paste("dead rows:", paste(names(dead), collapse = ", ")))
})

test_that("the fingerprint matches the recorded values", {
  skip_on_cran()
  expected <- read_tsv_kv(readLines(test_path("fingerprint", "expected.tsv")))
  got <- read_tsv_kv(run_fingerprint())
  got <- got[!grepl("^simd\\.", names(got))]
  expect_setequal(names(got), names(expected))
  for (key in intersect(names(expected), names(got))) {
    a <- as.numeric(got[[key]]); b <- as.numeric(expected[[key]])
    tol <- tolerance[[key]]
    if (is.null(tol)) tol <- c("rel", 1e-6)
    diff <- abs(a - b)
    ok <- if (tol[[1]] == "abs") diff <= as.numeric(tol[[2]]) else
      diff <= 1e-12 || diff / max(abs(a), abs(b)) <= as.numeric(tol[[2]])
    expect_true(isTRUE(ok), info = sprintf("%s: got %s, recorded %s",
      key, got[[key]], expected[[key]]))
  }
})
