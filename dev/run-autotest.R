# Run autotest (test = TRUE: the real mutation tests, not the default dry run)
# over the exported functions in isolated batches (a C++ abort in
# one batch must not lose the others). Usage, from the package root:
#   Rscript dev/run-autotest.R [batch_size=20] [timeout_s=900]
# Results: dev/autotest/batch-NN.rds (tibble from autotest_package) and
# dev/autotest/summary.csv. Needs the package installed from this tree.
args <- commandArgs(TRUE)
size <- if (length(args) >= 1L) as.integer(args[1L]) else 20L
tmo  <- if (length(args) >= 2L) as.integer(args[2L]) else 900L

ns <- readLines("NAMESPACE")
fns <- sub("^export\\((.*)\\)$", "\\1", grep("^export\\(", ns, value = TRUE))
fns <- gsub("\"", "", fns)
installed <- asNamespace("pladdrr")
fns <- fns[vapply(fns, function(f) exists(f, installed, inherits = FALSE) &&
                    is.function(get(f, installed)), NA)]
# autotest only accepts functions it can see in the package namespace listing;
# ask it (a bogus name makes it print the accepted set) and intersect.
probe <- tryCatch(autotest::autotest_package("pladdrr", functions = "..none..",
                                             progress = "none"),
                  error = function(e) conditionMessage(e))
accepted <- regmatches(probe, gregexpr("'[A-Za-z0-9_.]+'", probe))[[1L]]
accepted <- gsub("'", "", accepted)
fns <- intersect(fns, accepted)
batches <- split(fns, ceiling(seq_along(fns) / size))
dir.create("dev/autotest", showWarnings = FALSE)

run_batch <- function(tag, fs) {
  out <- sprintf("dev/autotest/%s.rds", tag)
  code <- sprintf(
    'suppressMessages(x <- autotest::autotest_package("pladdrr", functions = %s, progress = "none", test = TRUE)); saveRDS(x, "%s")',
    paste(deparse(fs), collapse = ""), out)
  t0 <- Sys.time()
  status <- system2("timeout", c(tmo, "Rscript", "-e", shQuote(code)),
                    stdout = FALSE, stderr = sprintf("dev/autotest/%s.log", tag))
  data.frame(tag = tag, fns = paste(fs, collapse = " "), status = status,
             secs = round(as.numeric(difftime(Sys.time(), t0, units = "secs"))),
             produced = file.exists(out))
}
# A failed batch (autotest error, or an abort that kills the R process) is
# re-run one function at a time so the culprit is named instead of lost.
one <- function(i, fs) {
  r <- run_batch(sprintf("batch-%02d", i), fs)
  if (r$status != 0L && length(fs) > 1L)
    r <- rbind(r, do.call(rbind, lapply(fs, function(f) run_batch(sprintf("fn-%s", f), f))))
  r
}
res <- do.call(rbind, Map(one, seq_along(batches), batches))
res$fns <- substr(res$fns, 1, 60)
write.csv(res, "dev/autotest/summary.csv", row.names = FALSE)
print(res)
