# F-api-03: as.matrix() had only two methods (Matrix, Polygon). For every other
# class R's default fired: it put a dim on the 2-element wrapper list (.xptr,
# .cpp) and kept the S3 class, so is.matrix() said TRUE, nothing errored, and
# print() on the result died inside the class's own print(). The fix is one
# fallback method on the shared PraatObject class that delegates to $as_matrix()
# or raises a classed pladdrr_input_error.

# Objects whose class really has a working $as_matrix().
.make_matrix_objects <- function() {
  sound <- Sound$create_tone(frequency = 440, duration = 0.3,
    sampling_rate = 16000)
  list(
    Sound = sound,
    Pitch = sound$to_pitch(),
    Intensity = sound$to_intensity(),
    Spectrogram = sound$to_spectrogram(),
    Ltas = sound$to_ltas()
  )
}

# Objects whose class has no $as_matrix() at all.
.make_no_matrix_objects <- function() {
  sound <- Sound$create_tone(frequency = 440, duration = 0.3,
    sampling_rate = 16000)
  list(
    Formant = sound$to_formant_keepall(),
    PointProcess = sound$to_point_process_periodic_cc(),
    Manipulation = sound$to_manipulation(),
    TextGrid = TextGrid(system.file("extdata", "test.TextGrid",
      package = "pladdrr"))
  )
}

test_that("as.matrix() returns the object's own matrix, not a dim-ed wrapper", {
  objects <- .make_matrix_objects()
  for (cls in names(objects)) {
    x <- objects[[cls]]
    expect_true(is.function(x$as_matrix), info = cls)
    expected <- x$as_matrix()
    m <- as.matrix(x)
    expect_true(is.matrix(m), info = cls)
    expect_identical(dim(m), dim(expected), info = cls)
    # bit-for-bit the same numbers as the object's own accessor
    expect_identical(m, expected, info = cls)
    # the junk object kept the S3 class, so print() died on it
    expect_false(inherits(m, cls), info = cls)
    expect_false(inherits(m, "PraatObject"), info = cls)
  }
})

test_that("as.matrix() dimensions match the object's own reported dimensions", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.3,
    sampling_rate = 16000)
  pitch <- sound$to_pitch()
  expect_identical(nrow(as.matrix(pitch)), pitch$get_number_of_frames())
  spectrogram <- sound$to_spectrogram()
  expect_identical(dim(as.matrix(spectrogram)),
    c(spectrogram$get_number_of_frequency_bins(),
      spectrogram$get_number_of_time_bins()))
})

test_that("as.matrix() on a class without $as_matrix() raises a typed error", {
  objects <- .make_no_matrix_objects()
  for (cls in names(objects)) {
    x <- objects[[cls]]
    expect_true(is.null(x$as_matrix), info = cls)
    cond <- tryCatch({
      as.matrix(x)
      NULL
    }, pladdrr_input_error = function(e) e)
    expect_true(inherits(cond, "pladdrr_input_error"), info = cls)
    expect_equal(cond$routine, "as.matrix", info = cls)
    expect_identical(cond$param, "x")  # the failing formal is the object
    # the message names the class and points at a working alternative
    expect_match(conditionMessage(cond), cls, fixed = TRUE, info = cls)
    # ...and points only at a conversion this class really has: Manipulation
    # has no as.data.frame() method, so offering it there sent users into R's
    # own untagged "cannot coerce class" error (fix/013 review).
    has_df <- !is.null(utils::getS3method("as.data.frame", cls, optional = TRUE))
    if (has_df) {
      expect_match(conditionMessage(cond), "as.data.frame", fixed = TRUE,
        info = cls)
    } else {
      expect_no_match(conditionMessage(cond), "as.data.frame", fixed = TRUE,
        info = cls)
      expect_match(conditionMessage(cond), "accessors", fixed = TRUE,
        info = cls)
    }
    # the old silent junk must be gone
    expect_false(is.matrix(tryCatch(as.matrix(x), error = function(e) NULL)),
      info = cls)
  }
})

test_that("as.matrix.PraatMatrix and as.matrix.Polygon keep their own methods", {
  matrix_object <- PraatMatrix(numberOfRows = 3, numberOfColumns = 4)
  polygon_object <- Polygon(x = c(0, 1, 1, 0), y = c(0, 0, 1, 1))

  expect_identical(
    utils::getS3method("as.matrix", "PraatMatrix", envir = asNamespace("pladdrr")),
    pladdrr:::as.matrix.PraatMatrix)
  expect_identical(
    utils::getS3method("as.matrix", "Polygon", envir = asNamespace("pladdrr")),
    pladdrr:::as.matrix.Polygon)

  expect_identical(as.matrix(matrix_object), matrix_object$as_matrix())
  expect_identical(as.matrix(polygon_object), polygon_object$as_matrix())
  expect_true(is.matrix(as.matrix(matrix_object)))
  expect_true(is.matrix(as.matrix(polygon_object)))
  expect_false(inherits(as.matrix(matrix_object), "PraatMatrix"))
  expect_false(inherits(as.matrix(polygon_object), "Polygon"))
})

test_that("as.matrix on a pladdrr Matrix never reaches the 'Matrix' package method", {
  skip_if_not_installed("Matrix")
  matrix_object <- PraatMatrix(numberOfRows = 2, numberOfColumns = 3)
  matrix_object$set_value(1, 2, 7)

  expect_identical(class(matrix_object)[1], "PraatMatrix")
  expect_s3_class(matrix_object, "PraatMatrix")
  # pladdrr must not own the S3 slot the Matrix package registers
  expect_false("as.matrix.Matrix" %in% ls(asNamespace("pladdrr")))

  loadNamespace("Matrix")
  out <- as.matrix(matrix_object)
  expect_true(is.matrix(out))
  expect_equal(out[1, 2], 7)
})
