library(pladdrr)

tg <- TextGrid$create(0, 5, "words")
cat("TextGrid created\n")

cat("Calling insert_boundary...\n")
result <- tg$insert_boundary(1, 1.0)  # Use tier number
cat("Success!\n")

cat("Calling change_labels...\n")
tg$change_labels(1, "test", "new")
cat("Success!\n")

cat("\n✅ All tests passed!\n")
