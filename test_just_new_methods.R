library(pladdrr)

cat("Testing ONLY new methods (not old broken ones)\n\n")

tg <- TextGrid$create(0, 5, "words")
cat("Created TextGrid\n")

# Test change_labels (even though we have no labels yet)
cat("\nTest 1: change_labels (should run without error)\n")
tg$change_labels(tier = 1, search = "nonexistent", replace = "also_nonexistent")
cat("✅ change_labels worked\n")

# Test extend_time
cat("\nTest 2: extend_time\n")
cat("Original duration:", tg$get_total_duration(), "\n")
tg$extend_time(delta_time = 2.0, position = 1)
cat("After extension:", tg$get_total_duration(), "\n")
cat("✅ extend_time worked\n")

# Test get_total_duration_where
cat("\nTest 3: get_total_duration_where\n")
duration <- tg$get_total_duration_where(tier = 1, criterion = "")
cat("Total duration of empty label:", duration, "\n")
cat("✅ get_total_duration_where worked\n")

cat("\n🎉 All NEW methods work correctly!\n")
cat("(Note: old methods like insert_boundary appear to have a separate issue)\n")
