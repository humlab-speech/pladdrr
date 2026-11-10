# Combine dev/autotest/batch-*.rds and summarise by finding type / test name.
files <- setdiff(list.files("dev/autotest", pattern = "^(batch|fn)-.*[.]rds$", full.names = TRUE), "dev/autotest/all.rds")
x <- do.call(rbind, lapply(files, function(f) { r <- readRDS(f); if (is.null(r)) NULL else as.data.frame(r) }))
cat(nrow(x), "rows from", length(files), "batches\n")
print(table(x$type))
real <- x[x$type != "dummy", ]
cat("\nNon-dummy findings by test:\n"); print(sort(table(real$test_name), decreasing = TRUE))
saveRDS(x, "dev/autotest/all.rds")
write.csv(real[, c("type", "test_name", "fn_name", "parameter", "operation", "content")],
          "dev/autotest/findings.csv", row.names = FALSE)
