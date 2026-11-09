# Release metadata must agree with DESCRIPTION. Each of these drifted at least
# once (inst/CITATION kept 5.0.5 through the 5.1.0 release).

test_that("inst/CITATION names the installed package version", {
  cit <- system.file("CITATION", package = "pladdrr")
  skip_if(!nzchar(cit), "no CITATION file")
  ver <- as.character(utils::packageVersion("pladdrr"))
  expect_true(any(grepl(paste0("R package version ", ver),
                        readLines(cit, warn = FALSE), fixed = TRUE)))
})

test_that("CITATION.cff and codemeta.json match the package version", {
  # Source-tree files: absent from the built package, so skip under R CMD check.
  cff <- test_path("..", "..", "CITATION.cff")
  codemeta <- test_path("..", "..", "codemeta.json")
  skip_if(!file.exists(cff) || !file.exists(codemeta), "not a source checkout")
  ver <- as.character(utils::packageVersion("pladdrr"))
  expect_true(any(grepl(paste0("^version: ", ver, "$"),
                        readLines(cff, warn = FALSE))))
  expect_true(any(grepl(paste0("\"version\": \"", ver, "\""),
                        readLines(codemeta, warn = FALSE), fixed = TRUE)))
})
