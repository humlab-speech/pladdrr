# Regression tests for F-security-02 (+ its reporting half, F-security-05b /
# F-errrep-01): a WAV whose `data` chunk declares more bytes than the file holds
# must be read as the samples that physically exist — never as a
# header-sized wall of fabricated zeros, and never without a catchable signal.

# Little-endian header helpers.
.i32 <- function(v) writeBin(as.integer(v), raw(), size = 4, endian = "little")
.i16 <- function(v) writeBin(as.integer(v), raw(), size = 2, endian = "little")
.le32 <- function(raw) as.integer(readBin(raw, "integer", 1L, endian = "little"))

# A canonical 44-byte-header WAV (the layout Praat itself writes), with the
# `data` chunk length set to `data_size` — which may lie.
.wav_bytes <- function(payload, data_size = length(payload), channels = 1L,
                       bits = 16L, rate = 22050L) {
  bytes_per_sample <- bits %/% 8L
  c(
    charToRaw("RIFF"), .i32(36L + data_size), charToRaw("WAVE"),
    charToRaw("fmt "), .i32(16L), .i16(1L), .i16(channels), .i32(rate),
    .i32(rate * channels * bytes_per_sample), .i16(channels * bytes_per_sample),
    .i16(bits), charToRaw("data"), .i32(data_size), payload
  )
}

.wav_write <- function(path, payload, ...) {
  writeBin(.wav_bytes(payload, ...), path)
  path
}

# Keep the first `keep_bytes` of a WAV Praat wrote, but leave the `data` chunk
# length claiming the full original size — i.e. a truncated file.
.wav_truncate <- function(path, keep_bytes) {
  bytes <- readBin(path, "raw", file.size(path))
  declared <- .le32(bytes[41:44])
  bytes <- bytes[seq_len(keep_bytes)]
  bytes[41:44] <- .i32(declared)
  writeBin(bytes, path)
  path
}

test_that("a pristine WAV reads silently with every sample", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.2,
    sampling_rate = 22050)
  path <- file.path(tempdir(), "pristine.wav")
  sound$save(path)
  bytes <- readBin(path, "raw", file.size(path))
  expect_identical(rawToChar(bytes[1:4]), "RIFF")
  expect_identical(rawToChar(bytes[37:40]), "data")
  expect_identical(.le32(bytes[41:44]),
    as.integer(sound$get_number_of_samples() * 2L))
  expect_silent(read <- Sound(path = path))
  expect_identical(as.integer(read$get_number_of_samples()),
    as.integer(sound$get_number_of_samples()))
})

test_that("cutting the file in half returns the samples that exist, with a warning", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.2,
    sampling_rate = 22050)
  path <- file.path(tempdir(), "trunc_half.wav")
  sound$save(path)
  keep <- as.integer(floor(file.size(path) / 2))
  .wav_truncate(path, keep)
  present <- (keep - 44L) %/% 2L
  expect_gt(present, 0L)

  w <- expect_warning(read <- Sound(path = path), class = "pladdrr_data_loss")
  expect_match(conditionMessage(w), basename(path), fixed = TRUE)
  expect_match(conditionMessage(w), as.character(present), fixed = TRUE)
  expect_identical(as.integer(read$get_number_of_samples()), present)
})

test_that("data truncated after a few samples returns exactly those samples", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.2,
    sampling_rate = 22050)
  path <- file.path(tempdir(), "trunc_short.wav")
  sound$save(path)
  kept <- 100L   # samples that physically survive
  .wav_truncate(path, 44L + kept * 2L)

  expect_warning(read <- Sound(path = path), class = "pladdrr_data_loss")
  expect_identical(as.integer(read$get_number_of_samples()), kept)
  # What survived is the real signal, not fabricated silence.
  expect_gt(sum(read$get_values() != 0), 0)
})

test_that("a lying data chunk does not allocate from the claim (subprocess)", {
  # 45 bytes on disk; the header claims 1e9 samples = 8 GB of doubles. Read out
  # of process so a pre-fix allocation blows this test up instead of the suite.
  path <- file.path(tempdir(), "lying_header.wav")
  .wav_write(path, as.raw(1L), data_size = 1000000000L, bits = 8L)
  script <- file.path(tempdir(), "trunc_wav_peak.R")
  writeLines(c(
    "library(pladdrr)",
    "seen <- 0L",
    "s <- withCallingHandlers(",
    sprintf('  pladdrr::Sound(path = "%s"),', path),
    '  pladdrr_data_loss = function(w) { seen <<- 1L; invokeRestart("muffleWarning") })',
    'st <- readLines("/proc/self/status")',
    'mb <- function(k) as.numeric(gsub("[^0-9]", "", grep(k, st, value = TRUE))) / 1024',
    'cat(sprintf("NX=%s PEAK=%.0f HWM=%.0f CONDITIONS=%s\\n",',
    '  format(s$get_number_of_samples()), mb("^VmPeak"), mb("^VmHWM"), seen))'
  ), script)
  out <- system2(file.path(R.home("bin"), "Rscript"), shQuote(script),
    stdout = TRUE, stderr = TRUE)
  hit <- grep("NX=", out, value = TRUE)
  expect_length(hit, 1L)   # child must report, not die
  kv <- regmatches(hit[1], regexec(
    "NX=([0-9]+) PEAK=([0-9]+) HWM=([0-9]+) CONDITIONS=([0-9]+)",
    hit[1]))[[1]]
  expect_identical(kv[2], "1")        # one sample present: 45 bytes - 44 header
  # VmPeak, not VmHWM, is what the header claim buys: Praat calloc's the buffer,
  # so the 8 GB of address space stay untouched (resident 124 MB on both builds)
  # until something reads the samples. Measured on /root/rlib-base: 7877 MB; on
  # the fixed build 312 MB, which is R + pladdrr and nothing else.
  expect_lt(as.numeric(kv[3]), 1500)  # MB of address space
  expect_lt(as.numeric(kv[4]), 200)   # MB resident
  expect_identical(kv[5], "1")        # ... and the loss was catchable in R
})

# Review round (sufficiency reviewer): the clamp must stop at the end of the
# `data` chunk, not at the end of the file. A real chunk after the samples
# (LIST/INFO metadata, common in recorded files) is not audio; counting to EOF
# read its 104 header bytes back as 52 extra samples.
test_that("a lying data chunk stops at the samples; a chunk after them is not audio", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.2,
    sampling_rate = 22050)
  path <- file.path(tempdir(), "trailer_after_lie.wav")
  sound$save(path)
  pristine <- as.numeric(Sound(path = path)$get_values())
  bytes <- readBin(path, "raw", file.size(path))
  present <- (length(bytes) - 44L) %/% 2L
  trailer <- c(charToRaw("LIST"), .i32(96L), charToRaw("INFO"), raw(92L))
  bytes[41:44] <- .i32(4L * present)   # lie: four times the samples that exist
  bytes[5:8] <- .i32(length(bytes) + length(trailer) - 8L)   # RIFF keeps the truth
  writeBin(c(bytes, trailer), path)

  expect_warning(read <- Sound(path = path), class = "pladdrr_data_loss")
  expect_identical(as.integer(read$get_number_of_samples()), present)
  # All of it is the signal that was written, including the last sample; none of
  # it came from the metadata chunk.
  expect_identical(as.numeric(read$get_values()), pristine)
})

test_that("several chunks after a lying data chunk are all skipped", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.2,
    sampling_rate = 22050)
  path <- file.path(tempdir(), "two_trailers_after_lie.wav")
  sound$save(path)
  pristine <- as.numeric(Sound(path = path)$get_values())
  bytes <- readBin(path, "raw", file.size(path))
  present <- (length(bytes) - 44L) %/% 2L
  trailer <- c(
    charToRaw("LIST"), .i32(8L), charToRaw("INFOartx"),
    charToRaw("INFO"), .i32(12L), charToRaw("pladdrraudit")
  )
  bytes[41:44] <- .i32(4L * present)
  bytes[5:8] <- .i32(length(bytes) + length(trailer) - 8L)
  writeBin(c(bytes, trailer), path)

  expect_warning(read <- Sound(path = path), class = "pladdrr_data_loss")
  expect_identical(as.integer(read$get_number_of_samples()), present)
  expect_identical(as.numeric(read$get_values()), pristine)
})

test_that("an honest data chunk followed by metadata reads in full and silently", {
  # The other side of the same walk: metadata after the samples must neither be
  # read as audio nor make an intact file warn.
  sound <- Sound$create_tone(frequency = 440, duration = 0.2,
    sampling_rate = 22050)
  path <- file.path(tempdir(), "honest_with_trailer.wav")
  sound$save(path)
  pristine <- as.numeric(Sound(path = path)$get_values())
  bytes <- readBin(path, "raw", file.size(path))
  trailer <- c(charToRaw("LIST"), .i32(96L), charToRaw("INFO"), raw(92L))
  bytes[5:8] <- .i32(length(bytes) + length(trailer) - 8L)
  writeBin(c(bytes, trailer), path)

  expect_silent(read <- Sound(path = path))
  expect_identical(as.numeric(read$get_values()), pristine)
})

# The mirror image of a truncated file: a `data` chunk that declares FEWER
# samples than the file holds. Praat reads the declared count and announces the
# rest in console text only (6.4.27 returns nx=4410 for a file holding 1750
# samples), so design goal 1 (fidelity) keeps that count; design principle 6
# (report loss of data) requires the condition, which Praat has no channel for.
test_that("an understated data chunk keeps Praat's count but reports the audio it drops", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.2,
    sampling_rate = 22050)
  path <- file.path(tempdir(), "understated.wav")
  sound$save(path)
  bytes <- readBin(path, "raw", file.size(path))
  declared <- 100L   # bytes: 50 samples, while the file holds 4410
  following <- (length(bytes) - 44L) %/% 2L
  bytes[41:44] <- .i32(declared)
  writeBin(bytes, path)

  w <- expect_warning(read <- Sound(path = path), class = "pladdrr_data_loss")
  # Praat's answer, pinned: the declared samples only, no more than today.
  expect_identical(as.integer(read$get_number_of_samples()), declared %/% 2L)
  expect_match(conditionMessage(w), basename(path), fixed = TRUE)
  expect_match(conditionMessage(w), as.character(declared %/% 2L), fixed = TRUE)
  expect_match(conditionMessage(w), as.character(following), fixed = TRUE)
  expect_identical(w$routine, "sound_read_from_file")

  old <- options(pladdrr.data_loss = "silent")
  on.exit(options(old), add = TRUE)
  expect_silent(quiet <- Sound(path = path))
  expect_identical(as.integer(quiet$get_number_of_samples()), declared %/% 2L)
})

test_that("options(pladdrr.data_loss=) controls the reaction to truncation", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.2,
    sampling_rate = 22050)
  path <- file.path(tempdir(), "trunc_modes.wav")
  sound$save(path)
  .wav_truncate(path, 44L + 20L)   # 10 samples present

  old <- options(pladdrr.data_loss = "error")
  on.exit(options(old), add = TRUE)
  expect_error(Sound(path = path), class = "pladdrr_data_loss")

  options(pladdrr.data_loss = "silent")
  expect_silent(read <- Sound(path = path))
  expect_identical(as.integer(read$get_number_of_samples()), 10L)

  options(pladdrr.data_loss = "warn")
  expect_warning(Sound(path = path), class = "pladdrr_data_loss")
})
