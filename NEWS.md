# pladdrr 5.0.6

## Bug fixes

* `batch_process()` rows for files that failed now carry `error_class` next to
  `error` (the first class of the condition, e.g. `pladdrr_input_error`). A worker
  turns a condition into a row so one bad file cannot lose the run, which means a
  `tryCatch(pladdrr_data_loss = )` around the call can never see it; filter on
  `error_class` instead. The documentation says so.
* The default worker count is the usable CPUs minus one only when there are more
  than two. With a 2-CPU allowance it was one worker, so
  `batch_process(parallel = TRUE)` silently ran serially.
* An `av`-decoded file whose container reports no channel count (`NA`) is read as
  mono instead of failing with "invalid 'dim'".

* Sizes that become allocations are validated up front. `sound_create_tone()`,
  `sound_create_pure_tone()` and `sound_create_tone_complex()` refuse a
  non-positive, non-finite or absurd `duration` / `sampling_rate` (a negative
  duration used to return a Sound with `nx = -16000`; 1e9 s asked for 4.4e13
  samples), `Matrix()` / `matrix_create_simple()` refuse non-positive or
  oversized dimensions (a negative count built a corrupt object), and
  `Excitation$to_formant()` needs `max_formants >= 1`. All raise a classed
  `pladdrr_input_error` naming the argument. The limit is 2^29 cells (4 GiB of
  doubles), the same as the cochleagram bound.

* The automatic thread count is capped at two when `_R_CHECK_LIMIT_CORES_` is set
  to anything but `false`, the way `R CMD check --as-cran` sets it and the way
  `parallel` already honours it. Before, only the R-level worker default
  followed it, so the C++ pool still used every core and CRAN's timing check
  (CPU time over 2.5x elapsed) flagged the CPPS examples: a 3 s
  `to_powercepstrogram_fast()` + `get_cpps_fast()` ran at a CPU/elapsed ratio of
  7.7 and now 2.0 under the variable. Outside `R CMD check` nothing changes, and
  an explicit `pladdrr_threads(n)` still wins.

* Every class constructor that takes `.xptr` now refuses a pointer to a Praat
  object of another class with a `pladdrr_input_error` ("Not a Sound (found
  TextGrid)"), the check `Matrix` and `PitchTier` already had. Before, 10
  constructors (`Sound`, `Pitch`, `Formant`, `FormantTier`, `Intensity`,
  `IntensityTier`, `Excitation`, `MFCC`, `LFCC`, `TextGrid`) re-interpreted the
  foreign object and the first query killed the R session (SIGSEGV, exit 139),
  and 21 more answered with another class's numbers. Subclasses still pass (a
  `Sound` is a valid `Matrix`). Not covered yet: `PowerCepstrogram`, which has no
  module constructor.

* `Sound$to_cochleagram()`, `$to_cochleagram_edb()` and `Spectrum$to_excitation()`
  refuse a step size that cannot describe the result instead of asking Praat for
  it. `df = 1e-9` is a 2.5 TB request: Linux answered with an allocation error,
  but macOS committed the pages and the kernel killed the whole R session
  (exit 137, invisible to `tryCatch()`). The size is now bounded in C++ (2^29
  cochleagram cells, i.e. about 5.8 h of audio at the default steps; 10 000
  excitation bands), so every door (R6, module, script) raises "... is not
  allowed". `dt`, `df`, `window_length`, `dtime` and `dfreq` also raise a classed
  `pladdrr_input_error` naming the argument, and `to_cochleagram_edb(dfreq = -1)`
  no longer returns a Cochleagram with a negative band count.
  **Behaviour change to expect:** requests above those bounds used to run on
  Linux machines with enough memory and now raise.

* `Sound$to_cochleagram()` on a very low-rate Sound no longer kills the R
  process. A sampling rate below ~67 Hz (with the default 0.03 s window) made the
  internal analysis window negative, and the FFT zero-padding step three
  functions away wrote outside a one-cell allocation: `free(): invalid pointer`,
  exit code 134, invisible to `tryCatch()` — the whole session died, along with
  anything an agent had in flight. It now raises, in every door
  (`Sound$to_cochleagram()`, the `cochleagram_module` door, and a script
  `To Cochleagram:`), with Praat's own message for the case,
  "Analysis window too short." — the guard `Sound_to_Pitch` has always had.
  **Behaviour change to expect:** at the default 0.03 s window the guard refuses
  any sampling rate below 200 Hz (the window needs 6 samples). Measured on the
  previous build those rates had no usable output — 67-133 Hz returned an
  all-NaN cochleagram (0 of 4352 cells finite), 150-199 Hz about 55% finite, the
  same degenerate shape as the still-accepted 200-500 Hz — but a script calling
  one of them now gets an error where it got a matrix of gaps.

* A failed cochleagram or excitation conversion no longer contaminates every
  later Praat error in the session. Six catch blocks — five in
  `src/cochleagram_wrappers.cpp` and `src/excitation_wrappers.cpp`, plus the
  exported `sound_extract_parts_pooled()` — were the only ones that let a Praat
  error cross back into R without calling `Melder_clearError()`. Praat's global
  error buffer only accumulates, and that call alone empties it, so after one bad
  conversion (`Sound$to_cochleagram(df = 1e-9)`,
  `Spectrum$to_excitation(erb_density = 1e-9)`) every later error in the same R
  session was prefixed with the stale "not enough room for ... elements" /
  "not converted to Cochleagram" text: an agent parsing an error got a message
  mixing two unrelated calls, and since Praat drops text that would overflow its
  2000-character buffer, a saturated buffer loses later error text outright.
  (Eight further blocks do not clear either; they re-throw into an outer
  clearing catch instead of reaching R, so they are left alone.) The reason
  Praat actually gave now travels in the error it belongs to: those errors end
  with Praat's own text (`Praat error in Spectrum_to_Excitation: Out of memory:
  ...`) via the package's `get_melder_error()` helper, which previously had no
  callers at all. Matching the existing prefix keeps working; anything anchored
  to the end of the message must be updated.

* `as.matrix()` no longer returns junk for the 39 of 41 object classes that had
  no method of their own. Only `Matrix` and `Polygon` registered one, so R's
  default fired for the rest: it put a `dim` on the 2-element wrapper list
  (`.xptr`, `.cpp`) and *kept the S3 class*, so `is.matrix(as.matrix(pitch))`
  was TRUE, no error was raised, the "matrix" held an external pointer instead
  of numbers, and printing it died inside the class's own `print()`. One
  fallback method on the shared `PraatObject` class now returns the object's own
  `$as_matrix()` where it has one (Sound, Pitch, Intensity, Spectrogram, Ltas,
  the tiers, the band-filtered spectrograms, ... — bit-for-bit the numbers that
  accessor gives), and raises the package's typed `pladdrr_input_error` naming
  the class and the accessor to use where it does not (`Formant`, PointProcess,
  TextGrid, Table, ... have no matrix to give). `as.matrix(Matrix)` and
  `as.matrix(Polygon)` behave exactly as before.

* Options passed to Praat script commands now select the option Praat would
  select. pladdrr's library-mode form layer (`src/uiform_libmode.cpp`, the
  script-only stand-in for Praat's `Ui.cpp`) stored Praat's `base` argument — the
  number an option list starts at — in the field's `subtract` slot instead of
  converting it (`Ui.cpp:1201 thy subtract = ( base == 1 ? 0 : 1 );`), so every
  CHOICE/OPTIONMENU argument reached the command one option too low
  (`Ltas: Get mean: 0, 0, "energy"` returned the dB mean and `"dB"` the sones
  mean; `Pitch: Get standard deviation: 0, 0, "hertz"` the ERB figure), every
  0-based `CHOICEx` list one option too high (`Pitch: Get value at time: …,
  "nearest"` interpolated like `"linear"`), and the *first* option of a
  `CHOICE_ENUM` — Pitch's own default unit `"hertz"`, `"none"`, `"nearest"` —
  raised `Field 'Unit' must not have the value 'hertz'.` where Praat answers a
  number. This is the script layer only: it applies to `PraatInterpreter$run()`
  and `praat_run_script()` alike, not to the R6 or direct wrappers, which pass
  their own integers and were already checked against Praat. It is not only a
  string-layer bug: a **numeric** third argument changed meaning, so
  `Get mean: 0, 0, 1` (energy in Praat's own enum) returned -8.19 dB before and
  42.85 dB now, and a script that compensated by shifting its own option
  strings, or by adding one to a number, must undo that. Among the families now
  answered instead of refused: the twelve `Formant: Get ...` commands whose
  `Unit` argument is Praat's `kFormant_unit` choice (all twelve used to error on
  their default; the enum offers `"hertz"` and `"bark"`, and `"erb"` is refused
  by Praat 6.4.27 too), and `Intensity: Get mean`, whose default `"energy"`
  came out 4.06 dB low (84.0703382556 where Praat prints 88.1298604765).

* `matrix_read()` and `PitchTier$from_file()` reject a file whose
  `Object class = ...` line names another class. A Praat text file names the
  C++ class to instantiate, and both readers cast the result to their own type
  without checking: loading a PitchTier as a Matrix reported garbage
  dimensions and then killed the R session uncatchably (SIGSEGV, exit 139) on
  the first value query, while a TextGrid cast to Matrix returned arbitrary
  heap values as numbers. They now raise the package's tagged input error
  (`[pladdrr_input_error:...]`, so `with_pladdrr_errors()` turns it into a
  catchable `pladdrr_input_error`) naming the file and the class found. Objects
  of a *derived* class still load (`Sound` or `Ltas` read as a `Matrix`),
  because the test is Praat's own subclass rule (`Thing_isa`) and not a name
  match.
* The same class check now guards the other door into a `Matrix` or `PitchTier`:
  the `.xptr` constructor argument. `Matrix(.xptr = <a TextGrid pointer>)` and
  `PitchTier(.xptr = <a Matrix pointer>)` used to build an object happily and
  die in the R process (SIGSEGV, exit 139, no `tryCatch` possible) on the first
  query, because the pointer was reinterpreted as the wrapper's own C++ type
  before anything looked at it. Both now refuse a foreign object with the
  package's typed `pladdrr_input_error` naming the class found, and because the
  check is Praat's subclass test (`Thing_isa`), legitimate transfers — a `Pitch`
  converted to a `PitchTier`, an `Ltas` or `Sound` pointer taken as a `Matrix` —
  keep working. The other 37 `.xptr`-accepting constructors are still open
  (`Sound`, `Pitch`, `Formant`, `Intensity`, `TextGrid`, ... segfault the same
  way); each needs its own one-line wiring, listed in
  `audit/2026-11/fixes/F-xptr-door.md`.
* A WAV whose `data` chunk declares more bytes than the file holds (truncated
  download, malformed header) no longer allocates from that claim and pads the
  rest with zeros. `Sound(path = )` now returns exactly the samples that are in
  the file, up to the end of the `data` chunk: a metadata chunk that follows the
  samples is no longer read back as audio either. It raises a
  `pladdrr_data_loss` condition naming the file and the real count, so
  `options(pladdrr.data_loss = "error")` turns a truncated file into an error
  and `"silent"` silences it. A 46-byte file whose header claimed 536 870 912
  samples used to arrive as a 4.3 GB object; it now yields the one
  sample that is physically in it. The mirror case, a `data` chunk that
  understates the audio that follows it, still returns the shorter count Praat
  returns (design goal 1), but now reports the discarded samples through the
  same condition instead of only in Praat's console text.
* `batch_process()` no longer loses the whole run to one bad file. A file that
  cannot be read (a 0-byte `.wav` from an aborted download) or on which `func`
  fails produced a row with different columns from the measured rows, and the
  final `rbind()` then died with "names do not match previous names": no results
  at all, and a message naming neither file nor cause. Every input file now
  yields exactly one row, in file order, a failure carrying its message in an
  `error` column and `NA` where the other rows have a measurement. That includes
  the `pladdrr_data_loss` error of a truncated WAV under
  `options(pladdrr.data_loss = "error")`, which used to abort the batch too.
* Reading FLAC, MP3, OGG and other `av`-decoded files no longer changes the
  level or folds the channels. The fallback reader divided the decoded samples
  by their own peak instead of the format's full scale, so the same tone came
  back 6.02 dB hotter from a lossless FLAC than from the WAV it was converted
  from, and it ignored the channel count, so a 2 x N stereo file arrived as a
  1 x 2N mono Sound of twice the length. It now scales by full scale (2^31, the
  S32LE that `av::read_audio_bin()` hands back) and de-interleaves into one row
  per channel. The substitution itself is announced with a catchable
  `pladdrr_decoder_fallback` warning instead of a console message, so a script
  that insists on the native reader can turn it into an error. Known limit,
  documented in `?Sound`: AAC/MP4 encoder delay is not trimmed (Praat has no
  reader for those containers, so there is no oracle behaviour to reproduce).

* `FormantPath$path_finder()` now matches Praat. A SIMD branch clamped the
  frequency-change cost twice (capped at 0.01 instead of 1), so the Viterbi
  path, and the formants of `extract_formant()` after it, could differ from
  Praat by more than 1 kHz.
* `sound_extract_parts_pooled()` no longer leaks segments: they are now
  ordinary R-owned Sounds (`use_pool` is accepted but ignored). A Sound from
  `sound_pool_acquire()` while the pool is full is now freed by R.
* An out-of-range `channel` is now an error instead of a wrong number. On a
  mono sound, `Sound$get_mean(from, to, channel = 2)` returned arbitrary heap
  contents (observed -6.8e+302) and larger indices could kill the R process;
  the same missing check in `PointProcess$get_values_from_sound()`, the LPC
  `filter_inverse_at_time()` entry points, `LongSound$get_window_extrema()` and
  `LongSound$save_channel()` silently produced another channel's numbers, and
  `Sound$to_point_process_extrema()` / `$to_point_process_zeros()` counted
  extrema and zero crossings in whatever memory lay beyond the channel array
  (`channel = 1000` killed the R session). An `NA` channel is named as such
  where the check happens in R (`Sound$to_point_process_zeros(channel = NA)` ->
  "`channel` must be a single integer, not NA"); where it happens in C++ the
  `NA` still arrives as its integer cast (`Sound$get_mean(0, 1, NA)` ->
  "Channel out of range [0, 3]: -2147483648"). None of these channel errors is
  classed: the R ones are plain `simpleError`s and the C++ ones
  `Rcpp::exception`, so catch `error`, not `pladdrr_input_error`.
  `channel = 0` keeps meaning "all channels" (Praat's `Vector_CHANNEL_AVERAGE`)
  where Praat allows it; `LongSound$get_window_extrema()` is 1-based and
  `LongSound$save_channel()` keeps Praat's 0 = left / 1 = right. Deviation from
  the application: Praat *clamps* an out-of-range channel to channel 1, pladdrr
  errors, because an error beats silent garbage.
* `Sound$get_maximum(from, to, channel)` and `Sound$get_minimum()` now honour
  that documented `channel` argument; on a multichannel sound both used to
  return the extremum over all channels whatever channel was asked for. On a
  3-channel file with per-channel peaks of 0.1 / 0.5 / 0.9, all three of
  `get_maximum(0, 0, 1:3)` returned `0.8999634` before and `0.09997559`,
  `0.4999695`, `0.8999634` now. The default became `channel = 0` (all channels),
  so existing calls without a channel, and all single-channel results, are
  bit-identical. The `channel` argument is checked by the guards described in
  the previous bullet (an untagged error, not a `pladdrr_input_error`).
* `Intensity$get_mean()`'s `averaging_method` sent Praat's averaging codes one
  too low, so the documented default `"energy"` returned the **median**,
  `"sones"` returned the energy average and `"db"` the sones average. The table
  now matches Praat's `Intensity_averaging` enum (`"median"` 0, `"energy"` 1,
  `"sones"` 2, `"db"` 3) and an unknown string errors instead of quietly
  averaging in medians. How far a number moves is the gap between the median and
  the energy mean of the contour, so it depends on the material and is not
  bounded: on the level-stepped signal the tests use it is 0.39 dB (87.74 ->
  88.13 dB), on a stationary file it is 8e-06 dB, and on a file that is mostly
  below its own analysis threshold the old median sat on the floor and the
  answer was the `-300` dB floor value where the energy average is 54.93 dB.
  `check_audio_quality()`'s `mean_intensity_db` is that same call and moves with
  it. `Intensity$get_statistics()`'s `"mean"` metric and `print()`'s "Mean
  intensity" line now use the same energy average, so all three agree. The
  integer APIs keep their numbers (`intensity_get_mean_direct(x, 0, 0, 0L)` is
  the median before and after — it used to add one, which is why the *string*
  layer was off by one, not the integer layer); their documentation is what was
  corrected, and it now names `0` median, `1` energy, `2` sones, `3` dB, which
  is also Praat's `Intensity_averaging` order. Passing a raw integer to
  `Intensity$get_mean()` (e.g. `averaging_method = 0L`, which silently meant
  "median") is no longer accepted; it errors and names the four strings. `"db"`
  is Praat's legacy two-argument `Intensity: Get mean`.
* **BREAKING CHANGE (numbers move).** `Ltas$get_mean()`, `$get_means_batch()` and
  `$get_standard_deviation()` with `unit = "energy"` or `unit = "sones"` returned
  the *linear* average — the mean of `10^(dB/10)` or of `2^(dB/10)` — where
  Praat's `Ltas: Get mean` averages in that domain and then converts the result
  back, so they now report the dB number Praat prints. Before: on a one-second
  speech LTAS `ltas$get_mean(0, 0, unit = "energy")` returned `14170.064098`
  (`unit = "sones"` returned the deceptively dB-shaped `0.900002`); after, the
  same call returns `41.513718` dB, which is what Praat prints and what
  `10*log10()` of the old answer already gave. Nothing marks the change at
  runtime: a column stored by 5.0.5 under `unit = "energy"` was simply wrong by
  three decades, and re-running the old script now silently gives different
  numbers, so recompute anything you saved.
  `ltas$get_standard_deviation(0, 0, unit = "energy")` moved the same way
  (`209963.529484` → `53.221439` dB).
* `Ltas$get_slope()` and `$get_local_peak_height()` mapped `unit = "dB"` — their
  **default** — to Praat's code 0, while `Ltas_getSlope` and
  `Ltas_getLocalPeakHeight` test for 3 (`fon/Ltas.cpp:87`, `:95`), so they
  returned a dimensionless ratio instead of a dB difference and could flip sign:
  `get_slope(0, 1000, 1000, 4000)` gave `-0.115522`, it now gives `-31.906946`
  dB (Praat's answer); `get_slope(1000, 4000, 4000, 8000)` changes sign, from
  `+5.840895` to `-15.995483`. `"energy"` and `"sones"` results are unchanged, which is
  why v4.0.4's table called them the working spellings — they were right by
  accident, because only the dB branch was broken.
* `Ltas` band averages no longer interpolate between bins, matching Praat's Ltas
  queries, which pass `interpolate = false`. **The default `unit = "dB"`
  results move too**, so "dB is unchanged" above would have been wrong: any
  band whose edges do not fall on bin edges changes, and how far depends on how
  far off they are. On `inst/extdata/test.wav`, `get_mean(500, 2000)` went from
  `10.717937` to `10.444981` dB; scanning 50 Hz-wide bands over 0-5500 Hz on an
  Ltas with a 100 Hz analysis bandwidth the movement reaches **8.41 dB**, so a
  low band inside a single bin is the worst case, not an exception. Full-band
  means (`fmin = fmax = 0`, the usual call) are bit-identical to before, and
  every averaging method, unit string and band
  are bit-identical to before, and every averaging method, unit string and band
  tested is now bit-identical to Praat 6.4.27
  (`tests/testthat/test-ltas-averaging-unit.R`). An unknown `unit` string in an
  averaging query is now a `pladdrr_input_error` instead of a silent
  `"energy"`, so **this also BREAKS** a script that had been passing a typo.

## Performance and memory

* The automatic thread count, and the default worker count of
  `analyze_files_parallel()` / `process_sounds_parallel()` / `batch_process()`,
  now follow the CPUs the *process* may use — the CPU affinity mask
  (`taskset`, container cpusets, SLURM) intersected with the cgroup CPU quota
  visible to the process — instead of the machine's core count. The old default
  asked for the machine's 32 threads no matter how few CPUs the process was
  given. Measured on a 32-core box (shared; medians of 3-5 runs over a 100-file
  pitch+formant corpus): in a 4-CPU cpuset `analyze_files_parallel()` with the
  default core count went from 4.57 s wall / 15.5 CPU-seconds to 1.81 s / 4.25
  (-60 % wall, -73 % CPU-seconds — it was starting 31 CPU-bound workers on 4
  CPUs), and a plain sequential loop from 2.08 s to 1.78 s with CPU-seconds
  unchanged. In a 16-CPU cpuset the saving is mostly latency, not CPU-seconds
  (loop 1.72 s -> 1.54 s, 4.39 -> 4.19 CPU-seconds; the batch helpers
  1.72 s / 17.7 -> 1.18 s / 10.0), because with 16 usable CPUs the 32-thread
  default was mostly waiting rather than spinning.
  `pladdrr_threads()$processors` reports the same number, and explicit
  `pladdrr_threads(n)` / `n_cores` still win.
  Where the platform exposes no affinity or quota API (Windows, macOS) the
  count is unchanged; output is bit-identical either way.
* The power-cepstrogram (CPPS) and Burg formant analyses no longer start a
  worker thread for a handful of frames. `Sound$to_powercepstrogram()` split a
  3 s clip into 60-frame grains - 24 threads, 6x the CPU-seconds of the serial
  kernel and slower in wall clock than an 8-thread run; `to_formant_burg()`
  split it every 3 frames, so even a 0.25 s clip (40 frames) asked for 9 workers.
  The minimum work per thread is now 250 and 40 frames respectively (measured
  break-even times three and five; 10 of the 11 other LPC/formant sites already
  use 40, the eleventh uses 80), so short clips stay on one thread while long
  recordings still fill the machine. On 32 cores, one 3 s clip: 166 -> 27 CPU-ms
  (-83%) at 0.74x the wall time for the cepstrogram, 44 -> 30 CPU-ms (-32%) at
  1.03x the wall time for formants; a 30 s recording is unchanged.
  **Short clips pay for it in latency**, which is the trade: over 600 clips at
  default settings, wall time per call went 1.26 -> 1.66 ms (+32%) for a 0.2 s
  formant analysis, 2.11 -> 3.22 ms (+53%) for a 0.4 s one and 1.85 -> 2.49 ms
  (+35%) for a 0.4 s cepstrogram, against CPU-seconds down 21-36% on the same
  calls; a 0.2 s cepstrogram and all pitch analysis are unaffected. If you
  analyse hundreds of sub-second clips and wall clock matters more than load,
  this change moves the wrong way for you. Output is bit-identical at every
  size, threads only partition frames.
* Loading the package uses ~40 MB less resident memory per R process
  (including every parallel worker): Praat's 42 MB object list is now
  constant-initialised instead of being written at load time.
* `Sound$resample()` (and therefore every Burg formant analysis) runs its
  sinc interpolation on multiple threads; output is bit-identical.
* `process_sounds_parallel()` on PSOCK clusters (Windows) no longer ships
  every Sound's samples to every worker with each task.
* `as_data_frame()` for Spectrogram, ComplexSpectrogram and Matrix fills
  preallocated vectors (peak memory roughly halved for long sounds).
* `sound_mean()`, `sound_min()`, `sound_max()`, `sound_rms()` and
  `sound_statistics()` read channel 1 directly instead of exporting all
  channels.
* Voice activity ZCR framing is O(frames + crossings) instead of
  O(frames x crossings).
* AVQI frees the per-interval Sounds once they are concatenated.

## Internal

* Removed unused or unreachable SIMD code (pitch bridge, pitch filter,
  autocorrelation, window functions, SlopeSelector, cochleagram, excitation,
  FormantPath) and their internal test-only bindings.
* Faithfulness registry: the `Pitch (cc)` and `Pitch (AC)` rows had been
  failing silently in the Praat oracle (a line wrap split the Praat command);
  fixed, and a FormantPath path-finder row was added.

# pladdrr 5.0.5

## Code quality

* `goodpractice` style pass:
  * Wrapped all >80-character code lines in hand-written `R/` files
    (auto-generated `RcppExports.R` unchanged); long string literals
    split into concatenated fragments with identical values.
  * Split five over-long functions into helpers (`autolayer.TextGrid`,
    `analyze_files_parallel`, `plot.Matrix`, `plot.PowerCepstrum`,
    `two_pass_adaptive_pitch`); the `goodpractice` function-length
    check now passes.
  * Consolidated cross-file `@param` blocks: dots docs kept in a single
    canonical file, constructor `name` docs inherited from a new
    `pladdrr_shared_method_name` anchor.
  * Removed the unused `._bust_cache` PointProcess method; the 113
    remaining `complexity_unused_internal` findings are documented
    false positives (S3 `$` dispatch, S3 generics, roxygen anchors,
    Rcpp export surface) - see `dev/goodpractice-dead-code-triage.md`.
  * Test coverage raised 89.3% to 91.8%: added coverage-gap tests for
    input validation, empty-data warnings, dispatch fallback paths, and
    `pladdrr.data_loss` modes; not-testable guards (missing-ggplot2
    stops, doc anchors, load-time branches) marked `# nocov`.
  * NEWS spelling fixes and `inst/WORDLIST` additions (`dev`,
    `uncommented`).

## CRAN compliance

* Removed the last two `R CMD check` warnings:
  * The compiled-code warning (`stderr`/`stdout`/`_exit` symbols in the
    vendored Praat objects): `melder_console.cpp` now routes console
    output through the R API (`Rprintf`/`REprintf`), gated to the main
    thread (R's console API is unsafe off-main-thread, and `Melder_casual`
    can fire inside threaded DSP frame loops; worker-thread messages are
    dropped). All `exit()` call sites in Praat's CLI paths throw a
    `MelderError` under `PRAAT_LIB` instead of terminating the process.
  * The non-portable `PKG_CXXFLAGS` flag `-ffp-contract=off` was replaced
    by a source-level `#pragma STDC FP_CONTRACT OFF` in the vendored
    `melder.h` (included by every DSP translation unit) — the same
    bit-exactness guarantee with no compiler flags.
* Removed the R-devel "package has both `src/Makevars.in` and
  `src/Makevars`" NOTE: the `cleanup` script now deletes the
  configure-generated `src/Makevars` from the build copy.
* Expanded `inst/WORDLIST` and fixed a typo; the documentation now passes
  `spelling::spell_check_package()`.
* Modernized the test suite (~440 assertion conversions: `expect_gt/gte/
  lt/lte`, `expect_length`, `expect_named`, `expect_type`,
  `expect_s3_class`, `expect_identical` for exact integer comparisons,
  `expect_false`, `fixed = TRUE` on literal patterns, `anyNA`).
* Parallel batch functions (`analyze_files_parallel()`,
  `process_sounds_parallel()`) now cap their automatic core count at 2 under
  `R CMD check` (honoring `_R_CHECK_LIMIT_CORES_`), so the default-`n_cores`
  tests pass CRAN's process-spawn limit while dev/CI still uses all cores.
* Fixed a broken example in the `textgrid_create()` docs (an uncommented
  continuation line) that made `R CMD check` fail to run any examples.
* Documented the `...` argument on `plot.*`, `as.data.frame.*`, `print.*`,
  and `summary.*` methods, and synced the shared `pladdrr_shared_*` parameter
  docs with their usage — clears the "Rd \usage sections" warning.

# pladdrr 5.0.4

## Bug fixes

* The Praat interpreter entry points (`praat_run_script()`,

* The Praat interpreter entry points (`praat_run_script()`,
  `praat_eval_numeric()`, `praat_eval_string()`, `praat_eval_vector()`,
  `praat_eval_matrix()`, `praat_eval_string_array()`, and
  `PraatInterpreter$run()`/`$eval()`/`$set_variable()`) now reject `NULL`,
  empty, non-scalar, or non-character inputs with a clear R error instead of
  an opaque C++ failure.
* `Sound$to_textgrid_silences()` accepted `min_silent_duration` /
  `min_sounding_duration` but silently ignored them (a `TODO`). It now
  merges short silent and sounding intervals via the same
  `IntervalTier_cutIntervals_minimumDuration` +
  `IntervalTier_combineIntervalsOnLabelMatch` passes the intensity-based
  path already used.
* `PointProcess(tmin, tmax)` now creates an empty PointProcess (previously
  it only accepted an internal pointer and stopped otherwise). Backed by a new
  `pointprocess_module$create_empty()` C++ factory wrapping Praat's
  `PointProcess_create()`. Enables empty-object batch operations.
* `praat_eval_string_array("empty$# (n)")` segfaulted the R session. The
  vendored Praat `do_empty_STRVEC` built its result with
  `autoSTRVEC result { n }`, which zero-initialises the vector and so leaves
  every element a null pointer instead of a valid empty C string; the R
  wrapper's `Melder_peek32to8()` then dereferenced null. It now returns `n`
  empty strings. Also un-skipped `formant$save()` (its earlier segfault was a
  symptom of the fixed `to_formant_burg()` crash).
* `Sound$get_optimal_formant_ceiling()` and `Sound$to_formant_optimal()`
  crashed the R session (SIGTRAP / "irrecoverable exception") for every
  input. Two stacked causes were fixed. (1) The vendored Praat
  `Sound_to_Formant_common` read the null output `sound` instead of the local
  `resampled` when setting up the short-term analysis and Formant/LPC
  objects, crashing every Burg/robust formant-analysis entry point
  (`to_formant_burg()` was also broken). (2) The pladdrr `Formant_extractPart`
  stub wrote `newFrame->formant[]` without allocating it — `Formant_create`
  zeroes frames so the array is null — so the interval path aborted on the
  first dereference. `to_formant_burg()`, `to_formant_optimal()`, and
  `get_optimal_formant_ceiling()` now all work.
* `autoplot.Spectrogram()`, `autolayer.Spectrogram()`, and `plot.Spectrogram()`
  scrambled the frequency axis for any non-square spectrogram matrix (a
  `expand.grid()`/`as.vector()` row/column-major mismatch — a 220 Hz tone
  rendered with its peak at 2201 Hz), and plotted raw linear power directly
  as if already in dB, making the `dynamic_range` clipping parameter a
  silent no-op.
* `plot_powercepstrogram()` had the same two defects (time/quefrency-axis
  transposition and missing power-to-dB conversion), plus a hardcoded
  `max_time <- 5.0` placeholder in place of the cepstrogram's real duration.
* `plot_cpp_timeseries()` used the same hardcoded-duration placeholder, and
  a `tryCatch()` scoping bug (`cpp_values[i] <- NA` instead of `<<-` inside
  the error handler) meant a failed per-time-point CPP query silently
  became `0` instead of being dropped as `NA`.
* `plot_powercepstrum()` used a hardcoded `max_quefrency <- 0.05` placeholder
  instead of the cepstrum's real quefrency range, and plotted its
  `power_dB` column (misleadingly named — the values are raw linear power,
  not dB) without converting, putting the line trace and its own
  peak-prominence marker on incompatible scales.

  None of these 5 functions had any test coverage before this release; 12
  new regression tests were added (`test-spectrogram-plot-regression.R`,
  `test-cepstrum-plots-regression.R`).
* Follow-up fixes closing the remaining `power_dB`-mislabel call sites:
  `autoplot.PowerCepstrum()`/`autolayer.PowerCepstrum()` and
  `plot.PowerCepstrum()` still plotted the C++ `as_data_frame()`'s
  misleadingly-named `power_dB` column (raw linear power) directly under a
  "Power (dB)" axis, and selected their cepstral-peak marker with
  `which.max()` on linear power. Both now convert to a real dB `power_db`
  column before plotting (5 new tests in
  `test-powercepstrum-db-regression.R`).
* `plot_powercepstrogram(show_cpp_contour = TRUE)` drew its CPP-contour
  overlay as a flat line at a hardcoded `quefrency = 0.01` placeholder; it
  now overlays the real per-time-frame cepstral-peak quefrency, computed as
  the argmax of each frame's own raster row.
* `plot.Spectrogram()`'s `preemphasis` argument (default 50) was accepted
  but never referenced; removed as dead — pre-emphasis belongs in the DSP
  layer, not a plot method.
* `plot_cpp_timeseries()` no longer emits a cosmetic
  "Mean CPP: NaN dB (SD: NA)" subtitle when every sample fails; it now
  shows "No samples".
* `PowerCepstrum$as_data_frame()` (the C++ `RPowerCepstrum` module) returned
  a column misleadingly named `power_dB` that actually held raw linear power;
  renamed to the honest `power`. This is a breaking change for any caller
  that read `$as_data_frame()$power_dB` directly; the affected plotting
  functions now read `power` and convert to `power_db`.
* `as.data.frame.LPC()` indexed the coefficient *matrix* as if it were a flat
  list (`coeffs[[i]]`), so it emitted one row per frame with a single
  mislabeled coefficient and silently dropped the other
  `maxnCoefficients - 1` coefficients of every frame. It now reads each
  frame's coefficient column (`coeffs[, i]`), yielding one row per
  (frame, coefficient) as documented.
* `AmplitudeTier$to_intensity_tier()` and `AmplitudeTier$save()` called
  non-existent internal wrappers (`.amplitudetier_to_intensitytier()` /
  `.amplitudetier_save()`), so both errored with "could not find function".
  They now dispatch through the Rcpp module (`to_intensity_tier_ptr()` /
  `save()`). Six `get_shimmer_*()` AmplitudeTier methods were also removed:
  shimmer is a PointProcess metric (already present there), and these
  AmplitudeTier copies had no C++ implementation.
* `plot_spectrogram_pitch()`'s `freq_max` argument (documented "Maximum
  frequency to display") was silently ignored — it was passed to
  `plot.Spectrogram()`, which has no such parameter. It now maps to
  `plot.Spectrogram()`'s `to_freq`, so the frequency cap is honored.
* `plot_sound_pitch()`'s `pitch_floor`/`pitch_ceiling` arguments were dead —
  passed to `plot.Pitch()`, which ignores them. Removed.
* Deprecated `get_intensity_at_time()`'s `interpolate` argument and
  `create_sound()`'s `start_time` argument were silently ignored; both now
  forward to the underlying R6 methods.
* `plot.Pitch()`/`autoplot.Pitch()`'s `show_voicing` argument never colored
  by voicing strength: it looked for a `voicing_strength` column, but
  `Pitch$as_data_frame()` names it `strength` (and only includes it with
  `include_strength = TRUE`). Both now pull the strength column and color by it.
* `autolayer.PointProcess()`'s `ymin`/`ymax` arguments were ignored (it used
  `geom_vline`), `autoplot.PCA()`/`autoplot.Discriminant()`'s `garnish`
  argument was dead, and `.formant_colors()`'s `max_formant` was redundant.
  All now honor their documented behavior.

# pladdrr 5.0.1

## New features

* Added `autoplot()` and `autolayer()` S3 methods for 27 previously unsupported Praat object classes: AmplitudeTier, DurationTier, IntensityTier, PitchTier, FormantTier, FormantGrid, FormantPath, Excitation, ComplexSpectrogram, Cepstrum, Cochleagram, PowerCepstrogram, MFCC, LFCC, BarkSpectrogram, MelSpectrogram, Matrix, PCA, Discriminant, FormantModeler, Electroglottogram, LongSound, DTW, Polygon, VocalTract, LPC, KlattGrid.
* Added `as.data.frame()` S3 methods for 15 classes that lacked them.

## Bug fixes

* `process_sounds_parallel()` shipped already-loaded `Sound` objects directly
  to Windows PSOCK workers; their external pointer to the underlying C++
  object cannot survive that process boundary, causing spurious errors on
  Windows with `n_cores > 1`. Sounds are now serialized to raw sample data
  and reconstructed inside each worker.
* Fixed `FormantGrid$as_data_frame()` missing required `time_step` argument.
* `autoplot.KlattGrid()`/`as.data.frame.KlattGrid()` passed a formant-type
  name as a string where the underlying accessor required an integer code,
  producing empty plots or silently wrong data for every formant type.
  Fixed to map the name to its integer code before dispatch; also corrected
  the shared `formant_type` documentation, which claimed `"all"` was an
  accepted value for `autolayer.KlattGrid()` when only `autoplot.KlattGrid()`
  actually supports it.
* `as.data.frame.Cochleagram()` always errored.
* `as.data.frame.LPC()` always errored, due to a typo'd `power_dB` column
  name that did not exist on the object.
* `autolayer.DTW()` plotted the wrong columns and crashed on some
  `NULL`-valued paths.
* `autoplot`/`autolayer`/`as.data.frame` for `Matrix`, `BarkSpectrogram`, and
  `MelSpectrogram` plotted raw row/column bin indices instead of the real
  time/frequency axis values.
* `autoplot.Cepstrum()` defaulted to a power-cepstrum dB view; Praat's actual
  default is a raw signed quefrency-domain view. Fixed the default and added
  a `power` parameter to select the dB view explicitly.
* `autoplot.ComplexSpectrogram()` and `autolayer.ComplexSpectrogram()` both
  mislabeled linear amplitude values as dB and ignored `dynamic_range`.
* `as.data.frame.VocalTract()`, `autoplot.VocalTract()`, and
  `autolayer.VocalTract()` all hardcoded section spacing (`dx`) instead of
  reading it from the object, giving wrong x-axis values whenever spacing
  was non-default.
* `autoplot.FormantTier()`/`autolayer.FormantTier()` defaulted to an
  interpolated line view; Praat's actual default view is speckle (points).
* `autoplot.FormantPath()` and `autoplot.FormantModeler()` always produced
  empty plots — the former from a column-name mismatch, the latter from a
  wide/long data-frame format mismatch.
* `as.data.frame.PowerCepstrogram()` called a nonexistent `$as_data_frame()`
  method and always crashed; fixed to route through `$to_matrix()`.
* `Sound$extract_electroglottogram()` was never registered in the R6 method
  table, despite its underlying C++ export existing and being registered;
  every call crashed with "attempt to apply non-function".

# pladdrr 5.0.0

## Bug fixes

* `intensity_tier_to_amplitude_tier()` and `amplitude_tier_from_point_process()`
  read `$.pointer` off `IntensityTier`/`PointProcess`/`Sound` objects, but
  those classes store their external pointer under `$.xptr` (`$.pointer` is
  only an alias on `AmplitudeTier`). The mismatch resolved to `NULL` and
  failed deep in the C++ layer with `R_ExternalPtrAddr: argument of type
  NILSXP is not an external pointer`. Fixed both call sites to use `$.xptr`.
* `matrix_read()` called an internal `.matrix_read()` binding that did not
  exist, so every call failed with `could not find function ".matrix_read"`
  (silently masked by an `R CMD check` NOTE-suppression entry in
  `utils::globalVariables()`, not by a real implementation). Added the
  missing C++ binding (mirroring the existing `PitchTier`/`IntensityTier`/
  `TextGrid` read pattern) and wired up `Matrix$save()` to the C++ save
  method that already existed but was never exposed to R.
* `get_max_pitch()`/`get_min_pitch()` (deprecated legacy wrappers) called
  `Pitch$get_maximum()`/`get_minimum()` with a stale `interpolation =`
  argument; the current method signature takes `interpolate =` (logical).
  Every call failed with `unused argument (interpolation = "none")`. Fixed
  to pass `interpolate = FALSE`.
* `get_formant_at_time()`/`get_mean_formant()`'s documentation pointed
  users to `extract_formants()` as the source of a compatible object, but
  `extract_formants()` no longer produces one when given an R6 `Sound`
  object (it delegates to `sound$to_formant_burg()`, returning an R6
  `Formant` object instead) — a stale cross-reference left over from the
  package's S3-to-R6 migration. No behavior changed; documentation now
  describes the actual expected input and `extract_formants()`'s actual
  return value on both its code paths.

## Documentation

* Removed performance claims (absolute and relative) from `DESCRIPTION` and
  `README.md` per CRAN submission review, including comparisons to other
  tools such as Parselmouth. Historical changelog entries with benchmark
  data have been moved to `NEWS-archive.md`, which is not shipped in the
  package tarball.
* Reconciled the Praat module count reported in `DESCRIPTION` (37 to 38) to
  match the actual number of exposed Rcpp modules.

## Memory

* Reworked spectral moments batch calculations to compute centre of
  gravity, standard deviation, skewness, and kurtosis directly from the
  spectrogram data, removing intermediate per-frame allocations. Results
  are numerically identical to previous versions.
* Pre-allocated the output vectors used to build formant and pitch data
  frames, and made pitch data frame construction skip allocating the
  strength/intensity columns when they are not requested.
