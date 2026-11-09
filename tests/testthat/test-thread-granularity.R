# test-thread-granularity.R - minimum work per thread at the frame-parallel
# decision points of the cepstrogram and formant paths (audit F-power-02/03).
#
# Starting a worker costs 24-53 us of CPU plus the buffers that analysis
# allocates inside its thread block, while one power-cepstrogram frame costs
# ~16 us and one Burg formant frame ~40 us.  With the old thresholds (40 and 3
# frames per thread) a single 3 s clip woke 24 and 32 workers to hand each of
# them microseconds of work: 7.2x and 1.9x the CPU-seconds of the serial kernel,
# and for the cepstrogram slower in wall clock than a 4-8 thread cap.  These tests pin the decision
# itself (how many threads a work size may ask for), and the invariant that makes
# retuning it free: threads only partition frames, so results must be identical,
# not merely close.
#
# The floor values are the ones the analyses actually pass to
# MelderThread_PARALLELIZE; see src/pladdrr_thread_thresholds.h and the
# measurement in audit/2026-11/evidence/012/.

cepstrogram_frames_per_thread <- 250L   # LPC/Sound_to_PowerCepstrogram.cpp
formant_frames_per_thread <- 40L        # fon/Sound_to_Formant.cpp

# Number of threads a parallel-decision point asks for a given number of frames,
# at the currently configured thread cap. This is the seam: it calls the same
# MelderThread_computeNumberOfThreads() the analyses call, with the same
# threshold constant, so it cannot drift away from the call site.
grains <- function(site, work_size) {
  as.integer(pladdrr:::.pladdrr_thread_grains_cpp(work_size, site))
}

# Run `code` with the concurrent-thread cap set to n (0 = automatic), restore after.
with_thread_cap <- function(n, code) {
  old <- pladdrr_threads()
  automatic <- old$enabled && old$max_threads == old$processors
  on.exit(pladdrr_threads(if (automatic) 0L else if (old$enabled) old$max_threads else 1L))
  pladdrr_threads(n)
  force(code)
}

test_that("no cepstrogram or formant grain is smaller than the measured floor", {
  # Sizes: one grain, two grains, and the frame counts of real clips -
  # 0.25 s / 1 s / 3 s of formants at time_step 0.005, 1 s / 3 s / 30 s / 5 min
  # of cepstrogram at time_step 0.002.
  floors <- c(cepstrogram = cepstrogram_frames_per_thread,
              formant = formant_frames_per_thread)
  sizes <- list(cepstrogram = c(250, 500, 549, 1451, 14510, 145100),
                formant = c(40, 50, 80, 596, 5960, 59600))   # ascending: the monotonicity check below needs it
  for (site in names(floors)) {
    asked_before <- 0L
    for (n in sizes[[site]]) {
      asked <- with_thread_cap(32L, grains(site, n))
      expect_true(asked >= 1L)                      # never zero, never error
      expect_true(asked >= asked_before)            # more work never means fewer threads
      if (asked > 1L) {
        # The point of the finding: a thread is only woken for a full grain.
        expect_true(n / asked >= floors[[site]])
      }
      asked_before <- asked
    }
  }
})

test_that("work too small to fill a grain is not threaded at all", {
  floors <- c(cepstrogram = cepstrogram_frames_per_thread,
              formant = formant_frames_per_thread)
  # One grain for one thread is one thread. For comparison, the 3-frame formant
  # threshold asked for 9 workers for a 0.25 s clip (40 frames) and 32 for a 3 s
  # clip; the 40-frame cepstrogram threshold asked for 24 for a 3 s clip.
  for (site in c("cepstrogram", "formant")) {
    floor_ <- floors[[site]]   # just below the point where a second thread is legal anywhere
    expect_equal(with_thread_cap(32L, grains(site, 1L)), 1L)
    expect_equal(with_thread_cap(32L, grains(site, 10L)), 1L)
    expect_equal(with_thread_cap(32L, grains(site, floor_)), 1L)          # one grain
    expect_equal(with_thread_cap(32L, grains(site, 2L * floor_ - 1L)), 1L) # one frame short of two
  }
  # Real-clip sizes: Linux rounds n / (1.5 * floor) to nearest, so these stay on one
  # thread there; macOS rounds n / floor down (see MelderThread_computeNumberOfThreads),
  # where 501 and 83 frames already hold two grains.
  if (Sys.info()[["sysname"]] == "Linux") {
    expect_equal(with_thread_cap(32L, grains("cepstrogram", 501L)), 1L)   # 1.2 s clip
    expect_equal(with_thread_cap(32L, grains("formant", 83L)), 1L)        # 0.46 s clip
  }

  # Four grains is the smallest size at which every platform's formula in
  # MelderThread_computeNumberOfThreads() agrees that a second thread pays.
  for (site in c("cepstrogram", "formant")) {
    expect_gte(with_thread_cap(32L, grains(site, 4L * floors[[site]])), 2L)
  }
})

test_that("work that pays for threads still gets them, up to the cap", {
  # Raising a threshold may only remove threads whose grain was too small; it
  # must not starve work that is big enough. 4000 frames is >= 8 grains at both
  # thresholds on every platform.
  for (site in c("cepstrogram", "formant")) {
    expect_equal(with_thread_cap(8L, grains(site, 4000L)), 8L, info = site)
    expect_equal(with_thread_cap(4L, grains(site, 4000L)), 4L, info = site)
    expect_equal(with_thread_cap(2L, grains(site, 4000L)), 2L, info = site)
    # Long recordings still ask for the whole machine (200000 frames = 1000 s of
    # formants / 400 s of cepstrogram, i.e. more grains than any machine has
    # threads; the 400-thread ceiling is Praat's NUMrandom limit).
    expect_equal(with_thread_cap(0L, grains(site, 200000L)),
      min(pladdrr_threads()$max_threads, 400L), info = site)
  }
  # pladdrr_threads(1) must still mean one thread.
  expect_equal(with_thread_cap(1L, grains("cepstrogram", 200000L)), 1L)
  expect_equal(with_thread_cap(1L, grains("formant", 200000L)), 1L)
})

# Seven shapes: short/long, one/two channels, and clip lengths whose frame
# counts sit just below and just above both decision points - 0.46 s is 83
# formant frames (1 thread) and 0.5 s is 90 (2 threads); 1.2 s is 501
# cepstrogram frames (1 thread) and 1.25 s is 576 (2 threads).
make_sound <- function(dur, channels) {
  sr <- 16000
  t <- seq(0, dur - 1 / sr, by = 1 / sr)
  voiced <- function(phase) {
    v <- drop(rowSums(vapply(1:12, function(k)
      sin(2 * pi * 120 * k * t + phase * k) / k, numeric(length(t)))))
    v * (0.6 + 0.4 * sin(2 * pi * 2.5 * t + phase))
  }
  m <- t(vapply(seq_len(channels), function(i) voiced((i - 1) * 0.7), numeric(length(t))))
  if (channels == 1L) m <- as.numeric(m)
  sound_from_values(m / max(abs(m)) * 0.8, sr)
}

analyse_all <- function(sound) {
  list(
    cepstrogram = sound$to_powercepstrogram(60, 0.002, 5000, 50)$as_matrix(),
    cpps = calculate_cpps_fast(sound),
    formant = sound$to_formant_burg(time_step = 0.005)$as_data_frame(),
    pitch = sound$to_pitch(time_step = 0.005, pitch_floor = 60,
      pitch_ceiling = 500)$as_data_frame()
  )
}

test_that("cepstrogram, CPPS, formant and pitch are bit-identical at any thread count", {
  shapes <- list(c(0.25, 1), c(0.46, 1), c(0.5, 1), c(1.2, 1), c(1.25, 1),
    c(3, 1), c(3, 2))
  for (shape in shapes) {
    sound <- make_sound(shape[1], as.integer(shape[2]))
    serial <- with_thread_cap(1L, analyse_all(sound))
    for (n in list(4L, 0L)) {
      other <- with_thread_cap(n, analyse_all(sound))
      for (key in names(serial)) {
        # tolerance = 0: identical bits, not "close enough". Windows (MinGW)
        # formant bandwidths differ at ~3e-8 between thread counts.
        expect_equal(other[[key]], serial[[key]],
          tolerance = if (.Platform$OS.type == "windows") 1e-6 else 0,
          info = paste(shape[1], "s", shape[2], "ch", key,
            if (n == 0L) "threads=auto" else "threads=4"))
      }
    }
  }
})
