# tests/testthat/test-xptr-constructor-class.R
# The `.xptr` constructor door (F-REVIEW-001-01, the follow-up the fix/001 review
# filed). fix/001 made matrix_read() and pitchtier_from_file() refuse a text file
# whose "Object class" line names another class, but the R6 constructors take an
# external pointer from R without asking where it came from:
#   Matrix(.xptr = <TextGrid pointer>)$get_minimum()
#   PitchTier(.xptr = <Matrix pointer>)$get_minimum()
# re-interpreted the foreign object as their own type, so the first field read
# was out-of-bounds and killed the R session (SIGSEGV, exit status 139) -- no
# tryCatch can catch that. The refusal is the same Thing_isa test the readers use
# (src/praat_xptr_utils.h:require_praat_class), run in the Rcpp module
# constructor that reinterprets the pointer.

.xptr_matrix <- function() matrix_create_simple(3, 4)
.xptr_textgrid <- function()
  TextGrid(path = system.file("extdata/test.TextGrid", package = "pladdrr"))

test_that("Matrix(.xptr = ) refuses an external pointer that is not a Matrix", {
  # Construction alone never used to crash (nothing dereferences the pointer
  # yet), which is exactly why the guard belongs here rather than in a method.
  expect_error(Matrix(.xptr = .xptr_textgrid()$.xptr),
    class = "pladdrr_input_error")
  cond <- tryCatch(Matrix(.xptr = .xptr_textgrid()$.xptr), error = function(e) e)
  expect_s3_class(cond, "pladdrr_input_error")
  expect_match(conditionMessage(cond), "Not a Matrix")
  expect_match(conditionMessage(cond), "found TextGrid")
  expect_identical(cond$routine, "Matrix")
  expect_identical(cond$param, ".xptr")
  # Explicit with_pladdrr_errors() must stay idempotent on an already classed
  # condition (R/error-classes.R rethrows untagged conditions untouched).
  expect_error(with_pladdrr_errors(Matrix(.xptr = .xptr_textgrid()$.xptr)),
    class = "pladdrr_input_error")
})

test_that("PitchTier(.xptr = ) refuses an external pointer that is not a PitchTier", {
  expect_error(PitchTier(.xptr = .xptr_matrix()$.xptr),
    class = "pladdrr_input_error")
  cond <- tryCatch(PitchTier(.xptr = .xptr_matrix()$.xptr), error = function(e) e)
  expect_s3_class(cond, "pladdrr_input_error")
  expect_match(conditionMessage(cond), "Not a PitchTier")
  expect_match(conditionMessage(cond), "found Matrix")
  expect_identical(cond$routine, "PitchTier")
  expect_identical(cond$param, ".xptr")
})

test_that("querying a wrong-class object no longer kills the session (subprocess)", {
  # The fatal half has to be measured out of process: on an unfixed build the
  # child dies with signal 11 (system2 status 139) and prints nothing, which no
  # in-suite expectation could report.
  doors <- list(
    matrix_from_textgrid = "obj <- Matrix(.xptr = tg$.xptr)",
    pitchtier_from_matrix = "obj <- PitchTier(.xptr = mx$.xptr)"
  )
  for (probe in names(doors)) {
    script <- file.path(tempdir(), paste0("xptr_door_", probe, ".R"))
    writeLines(c(
      "library(pladdrr)",
      'tg <- TextGrid(path = system.file("extdata/test.TextGrid", package = "pladdrr"))',
      "mx <- matrix_create_simple(3, 4)",
      "seen <- \"none\"",
      'status <- tryCatch({',
      doors[[probe]],
      '  obj$get_minimum()                       # <- the field read that used to be fatal',
      '  "NO-ERROR"',
      '}, pladdrr_input_error = function(e) { seen <<- "input_error"; "input_error" },',
      '   error = function(e) { seen <<- conditionMessage(e); "other-error" })',
      sprintf('cat(sprintf("XPTR-PROBE %s STATUS=%%s SEEN=%%s\\n", status, seen))',
        probe)
    ), script)
    out <- suppressWarnings(system2(file.path(R.home("bin"), "Rscript"),
      shQuote(script), stdout = TRUE, stderr = TRUE))
    status <- attr(out, "status"); if (is.null(status)) status <- 0L
    hit <- grep("^XPTR-PROBE", out, value = TRUE)
    # Child must report, not die: a pre-fix build segfaults before the line.
    expect_identical(status, 0L)
    expect_length(hit, 1L)
    expect_match(hit[1], "STATUS=input_error SEEN=input_error")
  }
})

test_that("a right-class pointer still builds, with its values", {
  mx <- .xptr_matrix()
  mx$set_value(2, 3, 7)
  same <- Matrix(.xptr = mx$.xptr)
  expect_equal(same$get_sum(), 7)
  expect_identical(same$get_number_of_rows(), 3L)

  tier <- PitchTier(0, 1)
  tier$add_point(0.5, 150)
  file <- tempfile(fileext = ".PitchTier")
  tier$save(file)
  loaded <- pladdrr:::pitchtier_from_file(file)
  expect_equal(loaded$get_value_at_time(0.5), 150)
})

test_that("subclasses are still accepted (Thing_isa, not class equality)", {
  # Ltas and Sound are Matrix subclasses in Praat's semantic chain
  # (Thing_implement (Vector, Matrix)), and fix/001 keeps their *files* loadable
  # as Matrix; the door must stay as permissive as the reader or legitimate
  # transfers break. What is asserted here is "not refused by the class guard",
  # not that the numbers are meaningful -- reading a Sound's fields as a Matrix
  # is the subclass-tolerance hole fix/001 documented, and this test must not be
  # read as blessing the values.
  ltas <- Sound$create_tone(220, 0.2, 16000)$to_ltas()
  expect_no_error(Matrix(.xptr = ltas$.xptr))
  snd <- Sound$create_tone(220, 0.2, 16000)
  expect_no_error(Matrix(.xptr = snd$.xptr))
})

test_that("Sound/Ltas-named text files still load as Matrix (reader tolerance)", {
  # Derived from the committed good fixture, line 2 only, as the fix/001 fixtures
  # are made. "Ltas 2" is the class line pladdrr's own Ltas writer produces.
  as_class <- function(cls) {
    lines <- readLines(test_path("fixtures/reader-class-guard",
      "matrix-good.matrix"))
    lines[[2]] <- sprintf('Object class = "%s"', cls)
    path <- tempfile(fileext = ".matrix")
    writeLines(lines, path)
    path
  }
  expect_equal(matrix_read(as_class("Ltas 2"))$get_sum(), 78)
  expect_no_error(matrix_read(as_class("Sound")))
})

test_that("an object built by conversion still reaches its own class", {
  # PointProcess -> PitchTier is the one transfer that lands on a PitchTier from
  # somewhere else than the file reader.
  pp <- PointProcess(0, 1)
  pp$add_point(0.2)
  pp$add_point(0.4)
  tier <- pp$upto_pitch_tier(600)
  expect_s3_class(tier, "PitchTier")
  expect_identical(tier$get_number_of_points(), 2L)
  expect_equal(tier$get_minimum(), 600)
})
