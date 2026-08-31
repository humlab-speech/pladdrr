# test-vocaltract-r6.R
# Coverage gap-fill for src/modules/vocaltract_module.cpp (Task 30)
#
# VocalTract is an R6-style S3 class wrapping the vocaltract_module Rcpp
# module. It previously had no dedicated test file.

test_that("VocalTract constructs with defaults and reports basics", {
  vt <- VocalTract()

  expect_s3_class(vt, "VocalTract")
  expect_true(vt$is_valid())
  expect_identical(vt$get_number_of_sections(), 17L)
  expect_type(vt$get_length(), "double")
  expect_type(vt$get_section_length(), "double")
  expect_type(vt$get_areas(), "double")
  expect_length(vt$get_areas(), 17)
})

test_that("VocalTract area getters and setters work", {
  vt <- VocalTract()

  expect_type(vt$get_area(1), "double")

  expect_invisible(vt$set_area(1, 5e-4))
  expect_equal(vt$get_area(1), 5e-4, tolerance = 1e-9)

  new_areas <- rep(3e-4, 17)
  expect_invisible(vt$set_areas(new_areas))
  expect_equal(vt$get_areas(), new_areas, tolerance = 1e-9)
})

test_that("VocalTract to_spectrum and to_matrix produce objects", {
  vt <- VocalTract()

  spec <- vt$to_spectrum(number_of_frequencies = 512)
  expect_s3_class(spec, "Spectrum")

  mat <- vt$to_matrix()
  expect_true(is.matrix(mat) || is(mat, "Matrix"))
})

test_that("VocalTract print works", {
  vt <- VocalTract()
  expect_output(print(vt), "VocalTract")
})
