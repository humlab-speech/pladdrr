library(pladdrr)

cat("Testing Tier Resolution Hypothesis\n\n")

tg <- TextGrid$create(0, 5, "words phonemes")

cat("Methods WITHOUT tier parameter (no resolve_tier_number):\n")
cat("  get_total_duration: ")
tryCatch({
  tg$get_total_duration()
  cat("✅\n")
}, error = function(e) cat("❌", conditionMessage(e), "\n"))

cat("  get_number_of_tiers: ")
tryCatch({
  tg$get_number_of_tiers()
  cat("✅\n")
}, error = function(e) cat("❌", conditionMessage(e), "\n"))

cat("\nMethods WITH tier parameter (uses resolve_tier_number):\n")
cat("  insert_boundary(1, 2.5): ")
tryCatch({
  tg$insert_boundary(1, 2.5)
  cat("✅\n")
}, error = function(e) cat("❌", conditionMessage(e), "\n"))

cat("  get_number_of_intervals(1): ")
tryCatch({
  tg$get_number_of_intervals(1)
  cat("✅\n")
}, error = function(e) cat("❌", conditionMessage(e), "\n"))

cat("  set_interval_text(1, 1, 'hello'): ")
tryCatch({
  tg$set_interval_text(1, 1, "hello")
  cat("✅\n")
}, error = function(e) cat("❌", conditionMessage(e), "\n"))

cat("\nMethods with OTHER patterns:\n")
cat("  change_labels(1, 'a', 'b'): ")
tryCatch({
  tg$change_labels(1, "a", "b")
  cat("✅\n")
}, error = function(e) cat("❌", conditionMessage(e), "\n"))

cat("  to_table(): ")
tryCatch({
  tg$to_table()
  cat("✅\n")
}, error = function(e) cat("❌", conditionMessage(e), "\n"))
