# tests/testthat/test-reader-class-guard.R
# A Praat text file names its own C++ class in line 2 ("Object class = ...").
# matrix_read() and pitchtier_from_file() used to reinterpret whatever object
# that line asked for as a Matrix / PitchTier, which is layout confusion: an
# uncatchable segfault or silently wrong numbers (F-security-01). The fixtures
# are files pladdrr wrote itself; the *-as-* variants differ in line 2 only.

mat_fix <- function(file) test_path("fixtures/reader-class-guard", file)

# The `*-as-*` fixtures are not Praat output: they are the good files with the
# `Object class = ` line rewritten, which is what makes them "a valid header
# naming a class the body does not match". Pinned here so a fixture cannot rot
# into something that differs in more than line 2 (which would quietly stop
# testing the guard).
expect_as_variant_is_line_two_only <- function(variant, original) {
  a <- readLines(mat_fix(variant))
  b <- readLines(mat_fix(original))
  expect_identical(length(a), length(b))
  expect_identical(a[3:100], b[3:100])   # everything below the header
  expect_match(a[2], "^Object class = ")
}

test_that("the wrong-class fixtures differ from the good files in line 2 only", {
  expect_as_variant_is_line_two_only(
    "matrix-as-pitch.matrix", "matrix-good.matrix")
  expect_as_variant_is_line_two_only(
    "matrix-as-textgrid.matrix", "matrix-good.matrix")
  expect_as_variant_is_line_two_only(
    "matrix-as-vector.matrix", "matrix-good.matrix")
  expect_as_variant_is_line_two_only(
    "pitchtier-as-matrix.pitchtier", "pitchtier-good.pitchtier")
  expect_as_variant_is_line_two_only(
    "pitchtier-as-stylpitch.pitchtier", "pitchtier-good.pitchtier")
})

test_that("matrix_read rejects a file whose object is another class", {
  # A perfectly valid PitchTier file: used to load, report garbage dimensions,
  # and segfault the R session (uncatchable, exit status 139) on the first
  # value query.
  expect_error(
    {
      bad <- matrix_read(mat_fix("pitchtier-good.pitchtier"))
      bad$get_value(1, 1)
    },
    "not a Matrix"
  )
  expect_error(matrix_read(mat_fix("pitchtier-good.pitchtier")),
    "File is not a Matrix: .*pitchtier-good.pitchtier \\(found PitchTier\\)")
})

test_that("pitchtier_from_file rejects a file whose object is another class", {
  # The mirror case, which segfaulted as well.
  expect_error(
    {
      bad <- pladdrr:::pitchtier_from_file(mat_fix("matrix-good.matrix"))
      bad$get_value_at_time(0.5)
    },
    "not a PitchTier"
  )
  expect_error(pladdrr:::pitchtier_from_file(mat_fix("matrix-good.matrix")),
    "File is not a PitchTier: .*matrix-good.matrix \\(found Matrix\\)")
})

test_that("files naming a class whose reader rejects the body still error", {
  # Praat's own reader for the named class fails on the mismatched body before
  # the guard is reached; what matters is that this stays a catchable error.
  expect_error({
    bad <- matrix_read(mat_fix("matrix-as-pitch.matrix"))
    bad$get_value(1, 1)
  })
  expect_error({
    bad <- matrix_read(mat_fix("matrix-as-textgrid.matrix"))
    bad$get_value(1, 1)
  })
  expect_error({
    bad <- pladdrr:::pitchtier_from_file(mat_fix("pitchtier-as-matrix.pitchtier"))
    bad$get_value_at_time(0.5)
  })
})

test_that("correct-class files keep reading with the same values", {
  m <- matrix_read(mat_fix("matrix-good.matrix"))
  expect_identical(m$get_number_of_rows(), 3L)
  expect_identical(m$get_number_of_columns(), 4L)
  expect_equal(m$get_value(1, 1), 1)
  expect_equal(m$get_value(3, 3), 11)
  expect_equal(m$get_value(3, 4), 12)
  expect_equal(as.matrix(m), matrix(1:12, nrow = 3, ncol = 4, byrow = TRUE))
  expect_equal(m$get_sum(), 78)

  tier <- pladdrr:::pitchtier_from_file(mat_fix("pitchtier-good.pitchtier"))
  expect_identical(tier$get_number_of_points(), 3L)
  expect_equal(tier$get_value_at_time(0.5), 150)
  expect_equal(tier$get_minimum(), 100)
  expect_equal(tier$get_maximum(), 150)
})

test_that("class names Praat cannot resolve at all still give a caught error", {
  # No Matrix subclass is a readable class in this build ("Vector", "Cepstrum",
  # "Cepstrogram", ...), so those fail before the class guard is reached.
  expect_error(matrix_read(mat_fix("matrix-as-vector.matrix")))
})

test_that("a legacy class name for the same class is still accepted", {
  # "StylPitch" is the pre-1996 name of PitchTier; Thing_isa() (rather than
  # string equality on the class line) accepts it, so old files keep loading.
  pladdrr::praat_init()   # registers the Praat class table, aliases included
  tier <- pladdrr:::pitchtier_from_file(mat_fix("pitchtier-as-stylpitch.pitchtier"))
  expect_identical(tier$get_number_of_points(), 3L)
  expect_equal(tier$get_value_at_time(0.5), 150)
})

test_that("the rejection is the package's tagged input error", {
  # inst/agents/AGENT_GUIDE.md's typed-error contract: errors raised in C++
  # carry a `[pladdrr_input_error:routine:param]` tag that
  # with_pladdrr_errors() turns into a classed condition. A bare Rcpp::stop()
  # here would leave this one error uncatchable by class.
  expect_error(matrix_read(mat_fix("pitchtier-good.pitchtier")),
    "\\[pladdrr_input_error:matrix_read:path\\]")
  expect_error(pladdrr:::pitchtier_from_file(mat_fix("matrix-good.matrix")),
    "\\[pladdrr_input_error:pitchtier_from_file:path\\]")
  caught <- NULL
  expect_error(with_pladdrr_errors(matrix_read(mat_fix("pitchtier-good.pitchtier"))),
    "not a Matrix")
  tryCatch(
    with_pladdrr_errors(matrix_read(mat_fix("pitchtier-good.pitchtier"))),
    pladdrr_input_error = function(e) { caught <<- e; invisible(NULL) }
  )
  expect_s3_class(caught, "pladdrr_input_error")
  expect_identical(caught$routine, "matrix_read")
})
