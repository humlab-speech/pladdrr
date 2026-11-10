# G5.2a: every condition message literal in R/ is unique.
# G5.2b ratchet: the set of messages with no matching fragment in the tests may
# shrink but never grow. Regenerate dev/message-baseline.txt with
#   Rscript dev/message-coverage.R --write
# after adding tests. Source-tree only; skipped under R CMD check.

pkg_root <- function() {
  root <- test_path("..", "..")
  if (!file.exists(file.path(root, "dev", "audit-messages.R")) ||
      !dir.exists(file.path(root, "R"))) {
    skip("not a source checkout")
  }
  root
}

test_that("no two condition messages in R/ share the same literal text", {
  root <- pkg_root()
  old <- setwd(root); on.exit(setwd(old), add = TRUE)
  env <- new.env()
  sys.source("dev/audit-messages.R", envir = env)
  d <- env$duplicated_messages(env$audit_messages("R"))
  expect_equal(unique(d$text), character(0))
})

test_that("untested-message baseline does not grow", {
  root <- pkg_root()
  old <- setwd(root); on.exit(setwd(old), add = TRUE)
  skip_if(!file.exists("dev/message-baseline.txt"), "no baseline")
  env <- new.env()
  sys.source("dev/message-coverage.R", envir = env)
  now <- unique(env$untested_messages()$text)
  baseline <- readLines("dev/message-baseline.txt", warn = FALSE)
  expect_equal(setdiff(now, baseline), character(0))
})
