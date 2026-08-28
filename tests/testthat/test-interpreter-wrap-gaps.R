# tests/testthat/test-interpreter-wrap-gaps.R
# Coverage gap-fill for R/praat-interpreter-wrapper.R: .wrap_praat_object
# branches — NULL input, missing praat_class attribute, the Matrix/Ltas
# class mapping, and the unknown-class warning.

test_that(".wrap_praat_object handles NULL and missing attributes", {
  expect_null(pladdrr:::.wrap_praat_object(NULL))
  ptr <- Matrix(numberOfRows = 2, numberOfColumns = 2)$.xptr
  expect_warning(
    out <- pladdrr:::.wrap_praat_object(ptr),
    "no praat_class attribute"
  )
  expect_identical(out, ptr)
})

test_that(".wrap_praat_object maps known classes", {
  m_ptr <- Matrix(numberOfRows = 2, numberOfColumns = 2)$.xptr
  attr(m_ptr, "praat_class") <- "Matrix"
  m <- pladdrr:::.wrap_praat_object(m_ptr)
  expect_s3_class(m, "Matrix")

  lt_ptr <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)$
    to_ltas()$.xptr
  attr(lt_ptr, "praat_class") <- "Ltas"
  lt <- pladdrr:::.wrap_praat_object(lt_ptr)
  expect_s3_class(lt, "Ltas")
})

test_that(".wrap_praat_object warns on unknown classes", {
  ptr <- Matrix(numberOfRows = 2, numberOfColumns = 2)$.xptr
  attr(ptr, "praat_class") <- "BogusClass"
  expect_warning(out <- pladdrr:::.wrap_praat_object(ptr), "Unknown Praat class")
  expect_identical(out, ptr)
})
