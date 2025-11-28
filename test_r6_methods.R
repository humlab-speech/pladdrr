library(pladdrr)

cat("Testing R6 Method Access\n\n")

# Create TextGrid
cat("Creating TextGrid...\n")
tg <- TextGrid$create(0, 5, "words")
cat("TextGrid created. Class:", paste(class(tg), collapse=", "), "\n\n")

# Test 1: Check method exists
cat("=== Test 1: Method exists ===\n")
cat("Has change_labels:", "change_labels" %in% names(tg), "\n")
cat("Is function:", is.function(tg$change_labels), "\n\n")

# Test 2: Try calling method
cat("=== Test 2: Calling change_labels ===\n")
tryCatch({
  result <- tg$change_labels(1, "test", "new")
  cat("✅ SUCCESS! Method called without error\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\n=== Test 3: Try a known working method ===\n")
tryCatch({
  duration <- tg$get_total_duration()
  cat("✅ get_total_duration() works! Duration:", duration, "\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\n=== Test 4: Try extend_time ===\n")
tryCatch({
  tg$extend_time(1.0, 1)
  cat("✅ extend_time() works!\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\n=== Test 5: Try to_table ===\n")
tryCatch({
  table <- tg$to_table()
  cat("✅ to_table() works! Table class:", paste(class(table), collapse=", "), "\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})
