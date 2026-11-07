# test-praat-interpreter-choice-args.R
#
# F-FAITH-13b: pladdrr's library-mode UiForm (src/uiform_libmode.cpp) used to
# store Praat's `base` argument in the field's `subtract` slot, so every CHOICE /
# CHOICE_ENUM / OPTIONMENU argument that reaches the embedded Praat script
# interpreter was off by one option, and the first option of every CHOICE_ENUM
# (enum value 0) threw "Field 'X' must not have the value 'Y'".
#
# The expected values below are FROZEN from the oracle
#   /usr/bin/praat = Praat 6.4.27 (January 27 2025)
# by
#   /usr/bin/praat --run audit/2026-11/evidence/uiform/oracle.praat
#   /usr/bin/praat --run audit/2026-11/evidence/uiform/oracle2_glide.praat
# (transcripts: audit/2026-11/evidence/uiform/oracle_probe_raw.txt and
# oracle2_glide_raw.txt). The "before" behaviour of pladdrr is in
# audit/2026-11/evidence/uiform/pladdrr_base_probe.txt.
#
# Both systems read the SAME bytes: the fixtures are written here with pladdrr
# and read back from disk, exactly as the oracle scripts read them, so only the
# argument mapping may differ.

# ---- fixtures ------------------------------------------------------------

.uiform_fixture_files <- function() {
  dir <- tempfile ("pladdrr-uiform-")
  dir.create (dir)
  sr <- 44100L
  t <- seq (0, by = 1 / sr, length.out = 44100)   # exactly 1.000 s
  harm <- double (length (t))                     # 220 Hz harmonic stack
  for (k in 1:10) harm <- harm + sin (2 * pi * 220 * k * t) / k
  harm <- harm / max (abs (harm)) * 0.8
  glide <- sin (2 * pi * (100 * t + 100 * t * t)) * 0.8   # 200 -> 400 Hz chirp
  Sound$from_values (harm, sr)$save (file.path (dir, "harm220.wav"))
  Sound$from_values (glide, sr)$save (file.path (dir, "glide.wav"))
  lines <- c (
    'File type = "ooTextFile"', 'Object class = "TextGrid"', "", "0", "1", "<exists>", "1",
    '"IntervalTier"', '"a"', "0", "1", "3",
    "0", "0.3", '"hi"', "0.3", "0.6", '"there"', "0.6", "1", '"hi there"')
  writeLines (lines, file.path (dir, "tg.TextGrid"))
  c (harm220 = file.path (dir, "harm220.wav"), glide = file.path (dir, "glide.wav"),
    tg = file.path (dir, "tg.TextGrid"))
}

# Run one query in an ISOLATED interpreter. Praat's object list is one global
# data structure, so each helper clears it first: a query that throws must not
# leave a stale object (or a stale FORM field value) behind for the next one.
.uiform_interp <- function (files, which) {
  interp <- PraatInterpreter$new ()
  interp$clear_objects ()
  interp$set_object (which, if (which == "tg") TextGrid$new (files [[which]])
    else Sound$new (files [[which]]))
  interp$select_object (which)
  if (which != "tg") interp$run ("To Pitch: 0.01, 75, 600")
  if (which == "harm220") {   # the Ltas fixture is only needed for the harm220 rows
    interp$select_object (which)
    interp$run ("To Ltas: 100")
  }
  interp
}

.uiform_query <- function (files, object, command) {
  interp <- .uiform_interp (files, if (grepl ("glide", object)) "glide" else "harm220")
  interp$select_object (object)
  interp$run (paste0 ("x = ", command))
  interp$get_variable ("x")
}

# ---- CHOICE_ENUM / OPTIONMENU_ENUM with enum MIN = 0 ---------------------
# Macro: OPTIONMENU_ENUM (kPitch_unit, ...) / CHOICE_ENUM (kVector_..., ...)
# pass base = (int) EnumeratedType::MIN = 0, so subtract must be 1 and the
# FIRST option (enum value 0) must be reachable.

test_that ("the first option of a CHOICE_ENUM field works (kPitch_unit = Hertz)", {
  files <- .uiform_fixture_files ()
  # oracle: Pitch Get mean hertz => 220.0000166207104   (oracle_probe_raw.txt)
  expect_equal (.uiform_query (files, "Pitch harm220", 'Get mean: 0, 0, "hertz"'),
    220.0000166207104, tolerance = 1e-7)
  # oracle: Pitch Get quantile hertz => 220.00007009990867
  expect_equal (.uiform_query (files, "Pitch harm220", 'Get quantile: 0, 0, 0.5, "hertz"'),
    220.00007009990867, tolerance = 1e-7)
  # oracle: Pitch Get value in frame 50 hertz => 220.0000755103521
  expect_equal (.uiform_query (files, "Pitch harm220", 'Get value in frame: 50, "hertz"'),
    220.0000755103521, tolerance = 1e-7)
  # oracle: Pitch Get value at time hertz linear => 220.00019532123906
  expect_equal (.uiform_query (files, "Pitch harm220",
    'Get value at time: 0.5, "hertz", "linear"'), 220.00019532123906, tolerance = 1e-7)
  # oracle: Ltas Get maximum none => 64.36903818143129 (kVector_peakInterpolation::NONE)
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get maximum: 0, 0, "none"'),
    64.36903818143129, tolerance = 1e-7)
  # oracle: Ltas Get frequency of maximum none => 250
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get frequency of maximum: 0, 0, "none"'),
    250, tolerance = 1e-7)
  # oracle: Ltas Get value at frequency nearest => 47.47427964315036
  #         (kVector_valueInterpolation::NEAREST)
  expect_equal (.uiform_query (files, "Ltas harm220",
    'Get value at frequency: 1500, "nearest"'), 47.47427964315036, tolerance = 1e-7)
  # the options after the first one were already right and must stay right:
  # oracle: Pitch Get mean mel => 185.05974201359584
  expect_equal (.uiform_query (files, "Pitch harm220", 'Get mean: 0, 0, "mel"'),
    185.05974201359584, tolerance = 1e-7)
  # oracle: Ltas Get maximum parabolic => 64.75389797256379
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get maximum: 0, 0, "parabolic"'),
    64.75389797256379, tolerance = 1e-7)
  # oracle: Ltas Get value at frequency linear => 29.919072861131877
  expect_equal (.uiform_query (files, "Ltas harm220",
    'Get value at frequency: 1500, "linear"'), 29.919072861131877, tolerance = 1e-7)
})

# ---- CHOICEx with base = 0, non-enum ------------------------------------
# "Pitch: Get value at time..." declares CHOICEx (interpolation, ..., 2, 0),
# so option 1 ("nearest") must give the C variable 0 and option 2 ("linear") 1.
# On the chirp the two answers differ, so a wrong base cannot hide.

test_that ("CHOICEx with base 0 maps option 1 to C value 0 (nearest vs linear)", {
  files <- .uiform_fixture_files ()
  # oracle: glide hertz nearest => 202.00401412686494
  expect_equal (.uiform_query (files, "Pitch glide", 'Get value at time: 0.505, "hertz", "nearest"'),
    202.00401412686494, tolerance = 1e-7)
  # oracle: glide hertz linear => 201.00394836198276
  expect_equal (.uiform_query (files, "Pitch glide", 'Get value at time: 0.505, "hertz", "linear"'),
    201.00394836198276, tolerance = 1e-7)
  # oracle: glide mel nearest => 172.0528610040556
  expect_equal (.uiform_query (files, "Pitch glide", 'Get value at time: 0.505, "mel", "nearest"'),
    172.0528610040556, tolerance = 1e-7)
  # oracle: glide mel linear => 171.32045940083566
  expect_equal (.uiform_query (files, "Pitch glide", 'Get value at time: 0.505, "mel", "linear"'),
    171.32045940083566, tolerance = 1e-7)
})

# ---- plain CHOICE with base = 1 -----------------------------------------
# e.g. CHOICE (averagingMethod, "Averaging method", 1) with options
# energy/sones/dB: the C variable must receive the 1-based option number.

test_that ("plain CHOICE arguments give the 1-based option number (Ltas units)", {
  files <- .uiform_fixture_files ()
  # oracle: Ltas Get mean energy => 42.85498973084085
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get mean: 0, 0, "energy"'),
    42.85498973084085, tolerance = 1e-7)
  # oracle: Ltas Get mean sones => 13.996730227319018
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get mean: 0, 0, "sones"'),
    13.996730227319018, tolerance = 1e-7)
  # oracle: Ltas Get mean dB => -8.192175799286025
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get mean: 0, 0, "dB"'),
    -8.192175799286025, tolerance = 1e-7)
  # oracle: Ltas Get standard deviation energy/sones/dB
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get standard deviation: 0, 0, "energy"'),
    52.8096559576987, tolerance = 1e-7)
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get standard deviation: 0, 0, "sones"'),
    31.816871544429798, tolerance = 1e-7)
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get standard deviation: 0, 0, "dB"'),
    18.20884656040197, tolerance = 1e-7)
  # CHOICE (averagingMethod, ...) again, in a command that tests == 3 for dB:
  # oracle: Ltas Get slope energy => -15.301287218608959
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get slope: 0, 1000, 1000, 4000, "energy"'),
    -15.301287218608959, tolerance = 1e-7)
  # oracle: Ltas Get slope sones => -17.807703997783488
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get slope: 0, 1000, 1000, 4000, "sones"'),
    -17.807703997783488, tolerance = 1e-7)
  # oracle: Ltas Get slope dB => -20.52713712587386
  expect_equal (.uiform_query (files, "Ltas harm220", 'Get slope: 0, 1000, 1000, 4000, "dB"'),
    -20.52713712587386, tolerance = 1e-7)
  # CHOICE (unit, "Unit", 1) with options Hertz/mel/semitones/ERB:
  # oracle: Pitch Get mean absolute slope hertz => 0.012623664883489502
  expect_equal (.uiform_query (files, "Pitch harm220", 'Get mean absolute slope: "hertz"'),
    0.012623664883489502, tolerance = 1e-7)
  # oracle: ... mel => 0.009016903069388368, semitones => 0.0009933870412944432,
  #         ERB => 0.00025558597468814764
  expect_equal (.uiform_query (files, "Pitch harm220", 'Get mean absolute slope: "mel"'),
    0.009016903069388368, tolerance = 1e-7)
  expect_equal (.uiform_query (files, "Pitch harm220", 'Get mean absolute slope: "semitones"'),
    0.0009933870412944432, tolerance = 1e-7)
  expect_equal (.uiform_query (files, "Pitch harm220", 'Get mean absolute slope: "ERB"'),
    0.00025558597468814764, tolerance = 1e-7)
})

# ---- plain OPTIONMENU with base = 1 -------------------------------------
# "Pitch: Get standard deviation..." uses OPTIONMENU (unit_i, "Unit", 1).

test_that ("plain OPTIONMENU arguments give the 1-based option number", {
  files <- .uiform_fixture_files ()
  expected <- c (                       # oracle_probe_raw.txt, lines 41-45
    hertz = 0.00012465470663975182,
    mel = 0.00008903907390336073,
    logHertz = 0.00000024607657442307607,
    semitones = 0.000009809384228005412,
    ERB = 0.0000025238309161965987
  )
  given <- sapply (names (expected), function (unit) .uiform_query (files,
    "Pitch harm220", paste0 ('Get standard deviation: 0, 0, "', unit, '"')))
  expect_equal (given, expected, tolerance = 1e-7)
})

# ---- numeric argument into a CHOICE field (pladdrr extension) -----------
# Praat 6.4.27 rejects numbers here:
#   Error: Option argument "Averaging method" should be a string, not a number.
# (audit/2026-11/evidence/uiform/oracle3_numeric_output.txt), so there is no
# oracle for this leg; what must hold is that a number counts the options the
# same way the strings do, i.e. 1 = energy, 2 = sones, 3 = dB.

test_that ("a numeric CHOICE argument counts options like the strings do", {
  files <- .uiform_fixture_files ()
  for (i in 1:3) {
    unit <- c ("energy", "sones", "dB") [[i]]
    expect_equal (.uiform_query (files, "Ltas harm220", paste0 ("Get mean: 0, 0, ", i)),
      .uiform_query (files, "Ltas harm220", paste0 ('Get mean: 0, 0, "', unit, '"')),
      tolerance = 1e-12, info = paste ("option", i, "should equal", unit))
  }
})

# ---- CHOICE_ENUM / OPTIONMENU_ENUM with enum MIN = 1 --------------------
# kMelder_string starts at 1, so base == 1 makes subtract 0 both in Praat and
# (by accident) in the old pladdrr code: the C variable was already right.
# Pinned here so the fix cannot move it.

test_that ("CHOICE_ENUM with enum MIN = 1 is unaffected", {
  files <- .uiform_fixture_files ()
  counts <- sapply (c ("is equal to", "contains", "starts with", "is not equal to"),
    function (cond) {
      interp <- .uiform_interp (files, "tg")
      interp$select_object ("TextGrid tg")
      interp$run (paste0 ('x = Count intervals where: 1, "', cond, '", "hi"'))
      interp$get_variable ("x")
    })
  # oracle (same tg.TextGrid): equal => 1, contains => 2, starts => 2,
  #   and "is not equal to" => 2 (3 intervals, 1 equal to "hi")
  expect_equal (counts, c (
    "is equal to" = 1, contains = 2, "starts with" = 2, "is not equal to" = 2
  ))
})

# ---- field kinds that must not change -----------------------------------
# REAL / POSITIVE / NATURAL / INTEGER / BOOLEAN / SENTENCE fields never read
# `subtract`; these rows pin that the fix did not move them.

test_that ("non-CHOICE field kinds are unchanged", {
  files <- .uiform_fixture_files ()
  # POSITIVE ("Bandwidth (Hz)" of To Ltas). Praat 6.4.27 answers
  #   Error: Argument “Bandwidth” must be greater than 0.
  interp <- .uiform_interp (files, "harm220")
  interp$select_object ("Sound harm220")
  expect_error (interp$run ("To Ltas: 0"), "must be greater than 0")
  # INTEGER ("Frame number"). Praat 6.4.27 answers
  #   Error: Argument “Frame number” should be a whole number.
  interp <- .uiform_interp (files, "harm220")
  interp$select_object ("Pitch harm220")
  expect_error (interp$run ('x = Get value in frame: 1.5, "hertz"'),
    "should be a whole number")
  # REAL ("Time (s)") + NATURAL ("Frame number"):
  # oracle: Pitch Get value in frame 50 hertz => 220.0000755103521
  expect_equal (.uiform_query (files, "Pitch harm220", 'Get value in frame: 50, "hertz"'),
    220.0000755103521, tolerance = 1e-7)
  # BOOLEAN: "To Spectrum: yes/no"; the answer is a Spectrum
  interp <- .uiform_interp (files, "harm220")
  interp$select_object ("Sound harm220")
  interp$run ('To Spectrum: "yes"')
  objs <- interp$list_objects ()
  expect_identical (objs$class [objs$name == "Spectrum harm220"], "Spectrum")
  # SENTENCE (the object name of "Create Sound as pure tone:") passes through
  interp <- PraatInterpreter$new ()
  interp$clear_objects ()
  interp$run ('Create Sound as pure tone: "tone", 1, 0, 1, 44100, 220, 0.8, 0.01, 0.01')
  expect_identical (interp$list_objects ()$name, "Sound tone")
})
