# test-multichannel-wav-write.R
#
# F-multichannel-wav claimed that Sound$save() writes corrupt multichannel WAV
# files: channel 1 silent and the remaining channels permuted above two channels,
# the 2-channel round trip only "surviving by accident", blamed on the vendored
# Praat writer. Checked against four decoders that are not pladdrr -- Praat
# 6.4.27 re-saving the same file byte for byte, libav via av::read_audio_bin(),
# a hand-written RIFF parser and a spec-derived byte reference -- the write path
# is correct from 1 to 8 channels: MelderFile_writeFloatToAudio()
# (src/praat.github.io/melder/melder_audiofiles.cpp:2256) emits sample-major
# frames from Sound's own z[channel][sample], and >2 channels just adds the
# WAVE_FORMAT_EXTENSIBLE header (same file:111-146). This file is therefore a
# PIN, not a red/green regression: it passes on the pre-fix build unchanged.
# What it guards is the exact mirror of the decode-side layout bug F-deps-01
# fixed -- interleaved frames versus channel-major blocks.
#
# The signal is permutation-sensitive: channel k is (k/10) * a ramp, so every
# channel has its own amplitude and its own first samples. A silent channel, a
# swap of any two channels or a channel-major file all fail here. Expected
# values come from the matrix that built the sound, never from the writer.

# channels x samples; channel k peaks at k/10 and starts at (k/10) * 0/(n-1),
# (k/10) * 1/(n-1), ... so no two channels share a level at any sample index.
.mc_signal <- function(channels, n = 199L) {
	# t(), never dim<-: vapply returns samples x channels, and re-dimensioning it
	# would reinterpret the samples instead of transposing them.
	t(vapply(seq_len(channels), function(k) (k / 10) * seq(0, 1, length.out = n), numeric(n)))
}

# 16-bit PCM quantisation, exactly as Praat clips and rounds it.
.mc_quantise <- function(values) round(pmin(32767, pmax(-32768, round(values * 32768))))

# Worst error between a written sound and the matrix behind it, counted in
# 16-bit samples: 1/32768 of full scale each. Rounding can never cost more than
# one unit, while a silent, swapped or block-laid-out channel costs thousands,
# so the comparison needs no fuzzing and cannot be talked into passing.
.mc_lsb_error <- function(actual, expected) {
	max(abs(.mc_quantise(actual) - .mc_quantise(expected)))
}

# Minimal RIFF reader: the raw bytes on disk, de-interleaved into channels x
# samples independently of pladdrr's own loader.
.mc_parse_wav <- function(path) {
	b <- readBin(path, "raw", file.size(path))
	u16 <- function(o) as.integer(b[o]) + as.integer(b[o + 1]) * 256L
	u32 <- function(o) as.integer(b[o]) + as.integer(b[o + 1]) * 256L +
		as.integer(b[o + 2]) * 65536L + as.integer(b[o + 3]) * 16777216L
	if (rawToChar(b[1:4]) != "RIFF" || rawToChar(b[9:12]) != "WAVE") {
		fail("written file is not a RIFF/WAVE container")
	}
	at <- 13L
	fmt <- NULL
	data_at <- NA_integer_
	data_size <- NA_integer_
	while (at + 7L <= length(b)) {
		id <- rawToChar(b[at:(at + 3)])
		size <- u32(at + 4L)
		if (id == "fmt ") {
			fmt <- list(format = u16(at + 8L), channels = u16(at + 10L),
				rate = u32(at + 12L), block_align = u16(at + 20L), bits = u16(at + 22L))
		} else if (id == "data") {
			data_at <- at + 8L
			data_size <- size
		}
		at <- at + 8L + size + (size %% 2L)
	}
	if (is.na(data_at) || is.null(fmt)) fail("written file has no fmt /data chunk")
	if (fmt$bits != 16L) fail("this test only covers 16-bit output, got ", fmt$bits)
	n_frame <- data_size %/% fmt$channels %/% 2L
	raw <- b[data_at:(data_at + n_frame * fmt$channels * 2L - 1L)]
	pcm <- readBin(raw, "integer", n_frame * fmt$channels, size = 2L)
	# WAV stores one frame per channel group: frame-major, i.e. interleaved.
	# (matrix(v, nrow = channels) is that same reading transposed, so the wrong
	# layout has to be spelled out as "channel k is one contiguous block".)
	list(fmt = fmt, n_frame = n_frame,
		values = matrix(pcm / 32768, nrow = n_frame, byrow = TRUE),
		channel_blocks = matrix(pcm / 32768, nrow = n_frame))
}

# The MS WAVE spec, written out by hand: PCM16 little-endian, format tag 1 up to
# two channels and WAVE_FORMAT_EXTENSIBLE above that, samples frame-major.
.mc_expected_wav <- function(values, sampling_rate) {
	channels <- nrow(values)
	pcm <- .mc_quantise(values)
	data <- as.vector(pcm)   # channels x samples, so this walk is frame-major
	extensible <- channels > 2L
	fmt_size <- if (extensible) 40L else 16L
	u16 <- function(v) writeBin(as.integer(v), raw(), 2L, endian = "little")
	u32 <- function(v) writeBin(as.integer(v), raw(), 4L, endian = "little")
	guid <- as.raw(c(1, 0, 0, 0, 0, 0, 16, 0, 128, 0, 0, 170, 0, 56, 155, 113))
	head <- c(charToRaw("RIFF"), u32(4L + (12L + fmt_size) + (4L + length(data) * 2L)),
		charToRaw("WAVE"), charToRaw("fmt "), u32(fmt_size),
		u16(if (extensible) 65534L else 1L), u16(channels), u32(sampling_rate),
		u32(sampling_rate * 2L * channels), u16(2L * channels), u16(16L))
	if (extensible) head <- c(head, u16(22L), u16(16L), u32(0L), guid)
	head <- c(head, charToRaw("data"), u32(length(data) * 2L))
	body <- writeBin(as.integer(data), raw(), 2L, endian = "little")
	# Praat pads the data chunk to an even byte count (the count in the header
	# does not include the pad).
	as.raw(c(head, body, if (length(body) %% 2L == 1L) as.raw(0) else raw()))
}

.mc_saved <- function(values, sampling_rate = 8000, format = "WAV") {
	path <- tempfile(fileext = paste0(".", tolower(format)))
	sound <- Sound$from_values(values, sampling_rate)
	# No skip(): a platform that cannot write the format must fail this file
	# loudly, because silent WAV output is the user-facing promise.
	expect_no_error(sound$save(path, format = format))
	expect_gt(file.info(path)$size, 44L)   # a header alone would be 44 bytes
	path
}

test_that("every channel keeps its own samples through save() -> Sound(path)", {
	for (channels in 1:8) {
		values <- .mc_signal(channels)
		back <- Sound(path = .mc_saved(values))$as_matrix()
		expect_identical(dim(back), c(as.integer(channels), 199L),
			info = paste0(channels, " channels"))
		expect_true(.mc_lsb_error(back, values) <= 1,
			info = paste0(channels, " channels"))
	}
})

test_that("the bytes on disk are interleaved frames, not channel-major blocks", {
	for (channels in 1:4) {
		values <- .mc_signal(channels)
		path <- .mc_saved(values)
		parsed <- .mc_parse_wav(path)
		expect_identical(parsed$fmt$channels, as.integer(channels))
		expect_identical(parsed$n_frame, 199L)
		expect_identical(parsed$fmt$block_align, as.integer(2 * channels))
		# The frame-major reading is the one that reproduces the input ...
		expect_true(.mc_lsb_error(t(parsed$values), values) <= 1,
			info = paste0(channels, " channels: interleaved reading"))
		# ... and the channel-major reading (one contiguous block per channel)
		# must NOT, which is what makes this test able to tell the two layouts
		# apart at all.
		if (channels > 1L) {
			expect_true(.mc_lsb_error(t(parsed$channel_blocks), values) > 100,
				info = paste0(channels, " channels"))
		}
		# Full byte-level contract, header included.
		expect_identical(
			as.integer(readBin(path, "raw", file.size(path))),
			as.integer(.mc_expected_wav(values, 8000)),
			info = paste0(channels, " channels: bytes differ from the WAVE spec")
		)
	}
})

test_that("channel 1 is not silent and no channel is a copy of its neighbour", {
	# The reported symptom, asserted away: a 3-channel write whose first file
	# channel was all zeroes and whose channels 2..3 were permuted.
	values <- .mc_signal(3L)
	parsed <- .mc_parse_wav(.mc_saved(values))
	for (k in 1:3) {
		channel <- parsed$values[, k]
		expect_true(max(abs(channel)) > max(abs(values[k, ])) / 2,
			info = paste0("file channel ", k, " is silent or lost"))
		expect_true(.mc_lsb_error(channel, values[k, ]) <= 1,
			info = paste0("file channel ", k, " holds another channel's samples"))
	}
})

test_that("what we write is what Praat 6.4.27 writes for the same signal", {
	# fixtures/multichannel-oracle-3ch.wav is the output of
	#   Read from file: <the file pladdrr wrote>
	#   Sound: Save as WAV file: ...
	# under `praat --run` (Praat 6.4.27, 2025-01-27), i.e. the oracle's own
	# bytes for the signal below; see audit/2026-11/fixes/F-multichannel-wav.md.
	fixture <- test_path("fixtures/multichannel-oracle-3ch.wav")
	if (!file.exists(fixture)) fail("oracle fixture missing")
	expect_identical(
		as.integer(readBin(fixture, "raw", file.size(fixture))),
		as.integer(readBin(.mc_saved(.mc_signal(3L)), "raw", 1e6)),
		info = "3-channel output drifted from the Praat oracle"
	)
})

test_that("the big-endian writer keeps the channels apart too", {
	values <- .mc_signal(3L)
	back <- Sound(path = .mc_saved(values, format = "AIFF"))$as_matrix()
	expect_true(.mc_lsb_error(back, values) <= 1)
})
