# tests/testthat/test-vocaltract-wrapper-gaps.R
# Coverage gap-fill for R/vocaltract-wrapper.R (was ~62%): construction,
# geometry/area accessors, conversions, and the phone constructor.

test_that("empty VocalTract geometry getters", {
  vt <- VocalTract(nx = 17L, dx = 0.01)
  expect_s3_class(vt, "VocalTract")
  expect_true(vt$is_valid())
  expect_identical(vt$get_number_of_sections(), 17L)
  expect_gt(vt$get_length(), 0)
  expect_gt(vt$get_section_length(), 0)
  expect_identical(vt$get_xptr(), vt$get_ptr())
  expect_output(vt$print(), "VocalTract")
})

test_that("VocalTract area accessors", {
  vt <- VocalTract(nx = 17L, dx = 0.01)
  areas <- vt$get_areas()
  expect_type(areas, "double")
  expect_length(areas, 17L)
  vt$set_area(5, 0.5)
  expect_equal(vt$get_area(5), 0.5)
  new_areas <- rep(0.4, 17)
  vt$set_areas(new_areas)
  expect_equal(vt$get_areas(), new_areas, tolerance = sqrt(.Machine$double.eps))
})

test_that("VocalTract to_spectrum/to_matrix conversions", {
  vt <- VocalTract(nx = 17L, dx = 0.01)
  sp <- vt$to_spectrum()
  expect_s3_class(sp, "Spectrum")
  m <- vt$to_matrix()
  expect_s3_class(m, "Matrix")
})

test_that("vocaltract_create_from_phone", {
  vt <- VocalTract$create_from_phone("a")
  expect_s3_class(vt, "VocalTract")
  expect_gte(vt$get_number_of_sections(), 1L)
})
