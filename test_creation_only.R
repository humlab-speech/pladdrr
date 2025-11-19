.libPaths(c("~/R_libs", .libPaths()))
library(speaker)

# Test creating objects (not reading files)
cat("Testing object creation...\n\n")

cat("1. Creating Sound from tone...\n")
sound <- Sound$create_tone(duration = 1.0, frequency = 440, sampling_rate = 44100, amplitude = 0.5)
print(sound)
cat("✓ Sound creation works\n\n")

cat("2. Creating Pitch from Sound...\n")
pitch <- sound$to_pitch()
print(pitch)
cat("✓ Pitch extraction works\n\n")

cat("3. Creating TextGrid...\n")
tg <- TextGrid$create(0, 5, "test")
print(tg)
cat("✓ TextGrid creation works\n\n")

cat("All creation tests passed!\n")
