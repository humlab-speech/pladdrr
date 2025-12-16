#!/usr/bin/env Rscript
# Quick test - formant extraction

library(pladdrr)

cat("Loading test sound...\n")
sound <- Sound$new("inst/extdata/test.wav")
cat("Duration:", sound$get_duration(), "s\n")

cat("\nTesting formant extraction...\n")
formant <- sound$to_formant_burg()
cat("Formants extracted OK\n")
cat("Num frames:", formant$get_number_of_frames(), "\n")

cat("\nTesting Pitch->TextGrid VUV...\n")
pitch <- sound$to_pitch()
tg_vuv <- pitch$to_textgrid_vuv()
cat("VUV TextGrid tiers:", tg_vuv$get_number_of_tiers(), "\n")

cat("\nTesting Pitch->TextGrid silences...\n")
tg_sil <- pitch$to_textgrid_silences()
cat("Silence TextGrid tiers:", tg_sil$get_number_of_tiers(), "\n")

cat("\n✅ All tests passed!\n")
