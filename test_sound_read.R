.libPaths(c("~/R_libs", .libPaths()))
library(speaker)
cat("Testing Sound file reading...\n")
sound_path <- system.file("extdata", "test.wav", package = "speaker")
cat("Path:", sound_path, "\n")
if (file.exists(sound_path)) {
  sound <- Sound$new(sound_path)
  cat("✓ Sound reading works\n")
  print(sound)
}
