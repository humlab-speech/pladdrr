# Praat enum string-to-code maps shared across wrapper files.
#
# Functions keep their own match.arg() choice sets (signature = accepted
# values); these maps are only used for the string -> integer code lookup.
#
# kVector_peakInterpolation
.interp_map <- c("none" = 0, "parabolic" = 1, "cubic" = 2,
                 "sinc70" = 3, "sinc700" = 4)
# kCepstrum_trendType as accepted by the CPPS APIs: LINEAR=1, EXPONENTIAL_DECAY=2
# (no "parabolic" here — that value belongs to .trend_line_map below)
.cpps_trend_map <- c("straight" = 1, "exponential" = 2, "exponential decay" = 2)
# Trend-line type for PowerCepstrum fit/subtract methods (parabolic allowed)
.trend_line_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
# kCepstrum_trendFit: ROBUST_FAST=1, LEAST_SQUARES=2, ROBUST_SLOW=3
# (both spellings of least squares accepted)
.trend_fit_map <- c("robust" = 1, "least squares" = 2, "least_squares" = 2,
                    "robust slow" = 3)

# Canonical CPPS parameter profiles.
#
# pladdrr deliberately ships two CPPS parameter profiles, and neither matches
# the Praat GUI form defaults exactly. Function signatures keep literal
# defaults (self-documenting in help pages); this table is the single source
# of truth, and test-cpps-defaults.R fails if any signature drifts from its
# profile.
#
# Profiles:
#   r6    — PowerCepstrogram$get_cpps() and calculate_cpps_fast()/
#           calculate_cpps_ultra(): tighter smoothing (0.001 s) than the
#           Praat GUI, quefrency trend range 0.003-0.04 s, ceiling 333.3 Hz.
#   avqi  — get_cpps_fast(): the AVQI protocol parameters (Maryn & Weenink),
#           subtract_tilt = FALSE, 0.01/0.001 smoothing, ceiling 330 Hz,
#           trend fit from 0.001 s to frame end (qend_fit = 0).
# For reference, the Praat GUI's "PowerCepstrogram: Get CPPS..." form
# pre-fills yet another set of values — see
# praat.github.io/LPC/praat_LPC_init.cpp:759-775. pladdrr reproduces those
# exactly when passed explicitly, but no profile ships for them.
.cpps_profiles <- list(
  r6 = list(
    subtract_tilt = TRUE,
    time_averaging_window = 0.001,
    quefrency_averaging_window = 0.0005,
    pitch_floor = 60,
    pitch_ceiling = 333.3,
    delta_f0 = 0.05,
    interpolation = "parabolic",
    qstart_fit = 0.003,
    qend_fit = 0.04,
    trend_line_type = "straight",
    fit_method = "robust"
  ),
  avqi = list(
    subtract_tilt = FALSE,
    time_averaging_window = 0.01,
    quefrency_averaging_window = 0.001,
    pitch_floor = 60,
    pitch_ceiling = 330,
    delta_f0 = 0.05,
    interpolation = "parabolic",
    qstart_fit = 0.001,
    qend_fit = 0,
    trend_line_type = "straight",
    fit_method = "robust"
  )
)
