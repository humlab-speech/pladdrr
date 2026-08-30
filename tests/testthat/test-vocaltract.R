
test_that("vocaltract_create_from_phone validates and builds", {
  vt <- vocaltract_create_from_phone("a")
  expect_s3_class(vt, "VocalTract")
  expect_error(vocaltract_create_from_phone("zz"), "Invalid phone")
})
