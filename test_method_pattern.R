library(pladdrr)

cat("Testing Method Pattern\n\n")

# Create objects
tg <- TextGrid$create(0, 5, "words")
sound <- Sound$from_values(sin(seq(0, 1, length.out=1000)), 1000)

cat("TextGrid Methods:\n")
methods <- c("insert_boundary", "set_interval_text", "get_total_duration", 
             "change_labels", "to_table", "extend_time")
for (m in methods) {
  result <- tryCatch({
    f <- tg[[m]]
    if (is.function(f)) "✅ Works" else "❌ Not function"
  }, error = function(e) paste("❌", conditionMessage(e)))
  cat(sprintf("  %-25s %s\n", m, result))
}

cat("\nSound Methods:\n")
methods <- c("get_total_duration", "to_pitch", "to_formant_burg", 
             "to_pointprocess_periodic_cc")
for (m in methods) {
  result <- tryCatch({
    f <- sound[[m]]
    if (is.function(f)) "✅ Works" else "❌ Not function"
  }, error = function(e) paste("❌", conditionMessage(e)))
  cat(sprintf("  %-30s %s\n", m, result))
}

cat("\nCalling TextGrid methods:\n")
for (m in c("get_total_duration", "change_labels", "insert_boundary")) {
  result <- tryCatch({
    if (m == "change_labels") {
      tg[[m]](1, "a", "b")
      "✅ Called successfully"
    } else if (m == "insert_boundary") {
      tg[[m]](1, 2.5)
      "✅ Called successfully"
    } else {
      val <- tg[[m]]()
      paste("✅ Returned:", val)
    }
  }, error = function(e) paste("❌", conditionMessage(e)))
  cat(sprintf("  %-25s %s\n", m, result))
}
