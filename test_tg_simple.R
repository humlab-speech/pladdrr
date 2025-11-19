library(speaker)
cat("Testing TextGrid creation (not reading)...\n")
tg <- TextGrid$create(0, 5, "test")
print(tg)
cat("✓ TextGrid creation works\n\n")

cat("Testing TextGrid file reading...\n")
tg_path <- system.file("extdata", "test.TextGrid", package = "speaker")
cat("Path:", tg_path, "\n")
cat("File exists:", file.exists(tg_path), "\n")

if (file.exists(tg_path)) {
  cat("Attempting to read...\n")
  tg2 <- TextGrid$new(tg_path)
  cat("✓ TextGrid reading works\n")
  print(tg2)
}
