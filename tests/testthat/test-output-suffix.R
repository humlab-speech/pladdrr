# G4.0: writers append the format's conventional suffix when none is given.

tone <- function() generate_sine_wave(200, 0.3, sampling_rate = 16000, amplitude = 0.5)

test_that(".ensure_suffix appends only when the basename has no extension", {
  ens <- pladdrr:::.ensure_suffix
  expect_equal(ens("out", "Pitch"), "out.Pitch")
  expect_equal(ens("dir.v2/out", "Pitch"), "dir.v2/out.Pitch")
  expect_equal(ens("out.txt", "Pitch"), "out.txt")
  expect_equal(ens("~/out", "wav"), paste0(path.expand("~/out"), ".wav"))
  expect_error(ens(c("a", "b"), "wav"), "path must be a single non-empty string",
               class = "pladdrr_input_error")
  expect_error(ens("", "wav"), "path must be a single non-empty string")
  expect_error(ens(NA_character_, "wav"), "path must be a single non-empty string")
})

test_that("Sound$save appends a suffix matching the format", {
  d <- withr::local_tempdir()
  snd <- tone()
  snd$save(file.path(d, "a"))
  snd$save(file.path(d, "b"), format = "AIFF")
  snd$save(file.path(d, "c.dat"))
  expect_setequal(list.files(d), c("a.wav", "b.aiff", "c.dat"))
})

test_that("Praat-object writers append their class suffix", {
  d <- withr::local_tempdir()
  snd <- tone()
  snd$to_pitch_cc()$save(file.path(d, "p"))
  snd$to_formant_burg()$save(file.path(d, "f"))
  snd$to_pitch_cc()$save(file.path(d, "named.txt"))
  expect_setequal(list.files(d), c("p.Pitch", "f.Formant", "named.txt"))
})

test_that("every .cpp save call in R/ goes through .ensure_suffix", {
  root <- test_path("..", "..")
  skip_if(!dir.exists(file.path(root, "R")), "not a source checkout")
  src <- unlist(lapply(list.files(file.path(root, "R"), "\\.R$", full.names = TRUE),
                       readLines, warn = FALSE))
  calls <- grep("\\.cpp\\$save(_part|_channel)?\\(|\\.formant_save\\(", src, value = TRUE)
  calls <- calls[!grepl("^\\s*#", calls) & !grepl("<- function", calls)]
  # save_part/save_channel span lines; the suffix helper sits on a continuation
  single <- calls[!grepl("save_(part|channel)", calls)]
  expect_true(length(single) >= 20)
  expect_true(all(grepl("ensure_suffix", single)), info = paste(single[!grepl("ensure_suffix", single)], collapse = "\n"))
})
