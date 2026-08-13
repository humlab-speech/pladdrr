# pointprocess-wrapper.R - PointProcess object using shared dispatch table (pladdrr 4.8.33)
# Architecture: minimal list + $.PointProcess S3 dispatch → shared method env

#' @title Praat PointProcess object
#'
#' @description
#' A PointProcess is a sequence of time points, typically representing glottal
#' pulse boundaries (moments of vocal fold closure). Used for voice quality
#' analysis: jitter (period perturbation) and shimmer (amplitude perturbation).
#'
#' @section Query methods:
#' \itemize{
#'   \item \code{get_number_of_points()} - total number of time points
#'   \item \code{get_time(index)} - time of point at index
#'   \item \code{get_nearest_index(time)} - index of point nearest to a given time
#'   \item \code{get_low_index(time)}, \code{get_high_index(time)} - index bounding a time
#'   \item \code{get_interval(time)} - time between surrounding points
#'   \item \code{get_mean_period(from_time, to_time, ...)} - mean glottal period
#'   \item \code{get_stdev_period(from_time, to_time, ...)} - SD of glottal period
#'   \item \code{get_number_of_periods(from_time, to_time, ...)} - number of periods in range
#'   \item \code{get_voice_breaks(from_time, to_time, ...)} - number of voice breaks
#' }
#'
#' @section Jitter methods:
#' Period perturbation measures. See the Note section for units.
#' \itemize{
#'   \item \code{get_jitter_local(from_time, to_time, ...)} - local jitter (Jloc)
#'   \item \code{get_jitter_local_absolute(from_time, to_time, ...)} - local absolute jitter
#'   \item \code{get_jitter_rap(from_time, to_time, ...)} - relative average perturbation
#'   \item \code{get_jitter_ppq5(from_time, to_time, ...)} - 5-period perturbation quotient
#'   \item \code{get_jitter_ddp(from_time, to_time, ...)} - difference of differences of periods
#' }
#'
#' @section Shimmer methods:
#' Amplitude perturbation measures; each takes a Sound. See the Note section for units.
#' \itemize{
#'   \item \code{get_shimmer_local(sound, from_time, to_time, ...)} - local shimmer (Shim)
#'   \item \code{get_shimmer_local_db(sound, from_time, to_time, ...)} - local shimmer in dB
#'   \item \code{get_shimmer_apq3(sound, from_time, to_time, ...)} - 3-period amplitude perturbation quotient
#'   \item \code{get_shimmer_apq5(sound, from_time, to_time, ...)} - 5-period APQ
#'   \item \code{get_shimmer_apq11(sound, from_time, to_time, ...)} - 11-period APQ
#'   \item \code{get_shimmer_dda(sound, from_time, to_time, ...)} - difference of differences of amplitude
#' }
#'
#' @section Batch and report methods:
#' \itemize{
#'   \item \code{get_jitter_shimmer_batch(pointprocess, sound, ...)} - all jitter and shimmer values as a named list, computed in one C++ call. Cache-aware: later calls with the same parameters return instantly.
#'   \item \code{voice_report(sound, pitch, ...)} - combined voice report (jitter, shimmer, HNR)
#' }
#'
#' @section Export and conversion methods:
#' \itemize{
#'   \item \code{as_vector()}, \code{as_data_frame()} - export as a vector or data.frame
#'   \item \code{to_textgrid_vuv(max_voiced_period, ...)} - create a voiced/unvoiced TextGrid
#'   \item \code{to_pitch_tier()} - convert to a PitchTier
#'   \item \code{to_sound_pulse_train(...)} - create a pulse train Sound
#' }
#'
#' @section Note:
#' Jitter and shimmer values are returned as decimals (0-1), not percentages.
#' Multiply by 100 for percentage display. The first shimmer call caches all 11
#' metrics; later jitter or shimmer calls with matching parameters return from
#' cache (no additional C++ call).
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++ PointProcess
#'   object; set internally when a method returns a new PointProcess.
#'
#' @seealso \code{\link{Sound}}, \code{\link{Pitch}}, \code{\link{AmplitudeTier}}
#'
#' @return A \code{PointProcess} object with methods for glottal pulse analysis, including jitter and shimmer.
#'
#' @examples
#' sound <- Sound$create_tone(duration = 1.0, frequency = 150, sampling_rate = 44100)
#' pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)
#' jitter <- pp$get_jitter_local()
#' shimmer <- pp$get_shimmer_local(sound)
#'
#' @name PointProcess
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.pp_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Basic Query ---
.pp_methods$is_valid <- function(.self) .self$.cpp$is_valid()
.pp_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.pp_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.pp_methods$get_duration <- function(.self) .self$.cpp$get_duration()
.pp_methods$get_number_of_points <- function(.self) .self$.cpp$get_number_of_points()
.pp_methods$get_time_from_index <- function(.self, index) .self$.cpp$get_time(as.integer(index))
.pp_methods$get_time <- function(.self, index) .self$.cpp$get_time(as.integer(index))
.pp_methods$get_nearest_index <- function(.self, time) .self$.cpp$get_nearest_index(as.numeric(time))
.pp_methods$get_low_index <- function(.self, time) .self$.cpp$get_low_index(as.numeric(time))
.pp_methods$get_high_index <- function(.self, time) .self$.cpp$get_high_index(as.numeric(time))
.pp_methods$get_interval <- function(.self, time) .self$.cpp$get_interval(as.numeric(time))

# --- Period statistics ---
.pp_methods$get_number_of_periods <- function(.self, from_time = 0, to_time = 0,
                                              period_floor = 0.0001, period_ceiling = 0.02,
                                              max_period_factor = 1.3) {
  .self$.cpp$get_number_of_periods(as.numeric(from_time), as.numeric(to_time),
    as.numeric(period_floor), as.numeric(period_ceiling), as.numeric(max_period_factor))
}
.pp_methods$get_mean_period <- function(.self, from_time = 0, to_time = 0,
                                        period_floor = 0.0001, period_ceiling = 0.02,
                                        max_period_factor = 1.3) {
  .self$.cpp$get_mean_period(as.numeric(from_time), as.numeric(to_time),
    as.numeric(period_floor), as.numeric(period_ceiling), as.numeric(max_period_factor))
}
.pp_methods$get_stdev_period <- function(.self, from_time = 0, to_time = 0,
                                         period_floor = 0.0001, period_ceiling = 0.02,
                                         max_period_factor = 1.3) {
  .self$.cpp$get_stdev_period(as.numeric(from_time), as.numeric(to_time),
    as.numeric(period_floor), as.numeric(period_ceiling), as.numeric(max_period_factor))
}
.pp_methods$get_voice_breaks <- function(.self, from_time = 0, to_time = 0,
                                         period_floor = 0.0001, period_ceiling = 0.02,
                                         max_period_factor = 1.3) {
  .self$.cpp$get_voice_breaks(as.numeric(from_time), as.numeric(to_time),
    as.numeric(period_floor), as.numeric(period_ceiling), as.numeric(max_period_factor))
}

# --- Modification (return invisible self) ---
.pp_methods$add_point <- function(.self, time) {
  .self$.cpp$add_point(as.numeric(time)); invisible(.self)
}
.pp_methods$remove_point <- function(.self, index) {
  .self$.cpp$remove_point(as.integer(index)); invisible(.self)
}
.pp_methods$remove_point_near <- function(.self, time) {
  .self$.cpp$remove_point_near(as.numeric(time)); invisible(.self)
}
.pp_methods$remove_points_between <- function(.self, from_time, to_time) {
  .self$.cpp$remove_points_between(as.numeric(from_time), as.numeric(to_time)); invisible(.self)
}
.pp_methods$fill <- function(.self, from_time, to_time, period) {
  .self$.cpp$fill(as.numeric(from_time), as.numeric(to_time), as.numeric(period)); invisible(.self)
}
.pp_methods$voice <- function(.self, period, max_period_factor = 1.3) {
  .self$.cpp$voice(as.numeric(period), as.numeric(max_period_factor)); invisible(.self)
}

# --- Set operations ---
.pp_methods$union_with <- function(.self, other_pp) {
  if (!inherits(other_pp, "PointProcess")) stop("Argument must be PointProcess")
  .self$.cpp$union_with(other_pp$.xptr); invisible(.self)
}
.pp_methods$intersection_with <- function(.self, other_pp) {
  if (!inherits(other_pp, "PointProcess")) stop("Argument must be PointProcess")
  .self$.cpp$intersection_with(other_pp$.xptr); invisible(.self)
}
.pp_methods$difference_with <- function(.self, other_pp) {
  if (!inherits(other_pp, "PointProcess")) stop("Argument must be PointProcess")
  .self$.cpp$difference_with(other_pp$.xptr); invisible(.self)
}

# --- Conversions ---
.pp_methods$upto_pitch_tier <- function(.self, ceiling = 600) {
  ptr <- .self$.cpp$upto_pitch_tier_ptr(as.numeric(ceiling))
  PitchTier(.xptr = ptr)
}
.pp_methods$upto_intensity_tier <- function(.self, intensity = 100) {
  ptr <- .self$.cpp$upto_intensity_tier_ptr(as.numeric(intensity))
  IntensityTier(.xptr = ptr)
}

# --- Batch operations ---
.pp_methods$get_values_from_sound <- function(.self, sound, channel = 1, interpolation = "cubic") {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  interp_code <- switch(tolower(interpolation),
    "nearest" = 0L, "linear" = 1L, "cubic" = 2L, "sinc70" = 3L, "sinc700" = 4L, 2L)
  .self$.cpp$get_values_from_sound(sound$.xptr, as.integer(channel), interp_code)
}
.pp_methods$get_periods_vector <- function(.self) .self$.cpp$get_periods_vector()
.pp_methods$get_periods_filtered <- function(.self, min_period = 0.0001, max_period = 0.02) {
  .self$.cpp$get_periods_filtered(as.numeric(min_period), as.numeric(max_period))
}
.pp_methods$get_jitter_batch <- function(.self, from_time = 0, to_time = 0,
                                         period_floor = 0.0001, period_ceiling = 0.02,
                                         max_period_factor = 1.3) {
  .self$.cpp$get_jitter_batch(as.numeric(from_time), as.numeric(to_time),
    as.numeric(period_floor), as.numeric(period_ceiling), as.numeric(max_period_factor))
}

# --- Export ---
.pp_methods$as_vector <- function(.self) .self$.cpp$as_vector()
.pp_methods$as_data_frame <- function(.self) .self$.cpp$as_data_frame()
.pp_methods$save <- function(.self, path) .self$.cpp$save(as.character(path))
.pp_methods$get_xptr <- function(.self) .self$.xptr

# --- Voice quality (jitter) ---
# --- Jitter/Shimmer with batch caching ---
# First call fetches all 11 metrics in one C++ call; subsequent calls return
# from cache when parameters match.  Shimmer cache includes sound identity.

.pp_methods$._bust_cache <- function(.self) {
  .self$.jscache <- NULL
}

.pp_methods$._get_js_batch <- function(.self, sound, from_time, to_time,
    period_floor, period_ceiling, max_period_factor, max_amplitude_factor) {
  ckey <- paste(from_time, to_time, period_floor, period_ceiling,
                max_period_factor, max_amplitude_factor,
                format(sound$.xptr))
  if (!is.null(.self$.jscache) && .self$.jscache$key == ckey) {
    return(.self$.jscache$data)
  }
  res <- get_jitter_shimmer_batch_cpp(.self$.xptr, sound$.xptr,
    from_time, to_time, period_floor, period_ceiling,
    max_period_factor, max_amplitude_factor)
  .self$.jscache <- list(key = ckey, data = res)
  res
}

.pp_methods$get_jitter_local <- function(.self, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3) {
  if (!is.null(.self$.my_scache)) {
    res <- .pp_methods$._get_js_batch(.self, .self$.my_scache$sound,
      from_time, to_time, period_floor, period_ceiling, max_period_factor, 1.6)
    return(res$jitter_local)
  }
  .pointprocess_get_jitter_local(.self$.xptr, from_time, to_time,
    period_floor, period_ceiling, max_period_factor)
}
.pp_methods$get_jitter_local_absolute <- function(.self, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3) {
  if (!is.null(.self$.my_scache)) {
    res <- .pp_methods$._get_js_batch(.self, .self$.my_scache$sound,
      from_time, to_time, period_floor, period_ceiling, max_period_factor, 1.6)
    return(res$jitter_local_abs)
  }
  .pointprocess_get_jitter_local_absolute(.self$.xptr, from_time, to_time,
    period_floor, period_ceiling, max_period_factor)
}
.pp_methods$get_jitter_rap <- function(.self, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3) {
  if (!is.null(.self$.my_scache)) {
    res <- .pp_methods$._get_js_batch(.self, .self$.my_scache$sound,
      from_time, to_time, period_floor, period_ceiling, max_period_factor, 1.6)
    return(res$jitter_rap)
  }
  .pointprocess_get_jitter_rap(.self$.xptr, from_time, to_time,
    period_floor, period_ceiling, max_period_factor)
}
.pp_methods$get_jitter_ppq5 <- function(.self, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3) {
  if (!is.null(.self$.my_scache)) {
    res <- .pp_methods$._get_js_batch(.self, .self$.my_scache$sound,
      from_time, to_time, period_floor, period_ceiling, max_period_factor, 1.6)
    return(res$jitter_ppq5)
  }
  .pointprocess_get_jitter_ppq5(.self$.xptr, from_time, to_time,
    period_floor, period_ceiling, max_period_factor)
}
.pp_methods$get_jitter_ddp <- function(.self, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3) {
  if (!is.null(.self$.my_scache)) {
    res <- .pp_methods$._get_js_batch(.self, .self$.my_scache$sound,
      from_time, to_time, period_floor, period_ceiling, max_period_factor, 1.6)
    return(res$jitter_ddp)
  }
  .pointprocess_get_jitter_ddp(.self$.xptr, from_time, to_time,
    period_floor, period_ceiling, max_period_factor)
}

# --- Voice quality (shimmer) ---
.pp_methods$get_shimmer_local <- function(.self, sound, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3, max_amplitude_factor = 1.6) {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  .self$.my_scache <- list(sound = sound)
  .pp_methods$._get_js_batch(.self, sound, from_time, to_time,
    period_floor, period_ceiling, max_period_factor, max_amplitude_factor)$shimmer_local
}
.pp_methods$get_shimmer_local_db <- function(.self, sound, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3, max_amplitude_factor = 1.6) {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  .pp_methods$._get_js_batch(.self, sound, from_time, to_time,
    period_floor, period_ceiling, max_period_factor, max_amplitude_factor)$shimmer_local_db
}
.pp_methods$get_shimmer_apq3 <- function(.self, sound, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3, max_amplitude_factor = 1.6) {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  .pp_methods$._get_js_batch(.self, sound, from_time, to_time,
    period_floor, period_ceiling, max_period_factor, max_amplitude_factor)$shimmer_apq3
}
.pp_methods$get_shimmer_apq5 <- function(.self, sound, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3, max_amplitude_factor = 1.6) {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  .pp_methods$._get_js_batch(.self, sound, from_time, to_time,
    period_floor, period_ceiling, max_period_factor, max_amplitude_factor)$shimmer_apq5
}
.pp_methods$get_shimmer_apq11 <- function(.self, sound, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3, max_amplitude_factor = 1.6) {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  .pp_methods$._get_js_batch(.self, sound, from_time, to_time,
    period_floor, period_ceiling, max_period_factor, max_amplitude_factor)$shimmer_apq11
}
.pp_methods$get_shimmer_dda <- function(.self, sound, from_time = 0, to_time = 0,
    period_floor = 0.0001, period_ceiling = 0.02,
    max_period_factor = 1.3, max_amplitude_factor = 1.6) {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  .pp_methods$._get_js_batch(.self, sound, from_time, to_time,
    period_floor, period_ceiling, max_period_factor, max_amplitude_factor)$shimmer_dda
}

# --- Voice report ---
.pp_methods$voice_report <- function(.self, sound, pitch,
                                     from_time = 0, to_time = 0,
                                     pitch_floor = 75, pitch_ceiling = 600,
                                     max_period_factor = 1.3, max_amplitude_factor = 1.6,
                                     silence_threshold = 0.03, voicing_threshold = 0.45) {
  if (!inherits(sound, "Sound")) stop("sound argument must be a Sound object")
  if (!inherits(pitch, "Pitch")) stop("pitch argument must be a Pitch object")
  .pointprocess_voice_report(
    sound$.xptr, pitch$.xptr, .self$.xptr,
    from_time, to_time, pitch_floor, pitch_ceiling,
    max_period_factor, max_amplitude_factor,
    silence_threshold, voicing_threshold
  )
}

# --- TextGrid/Sound conversion ---
.pp_methods$to_textgrid_vuv <- function(.self, max_voiced_period, max_unvoiced_period = 0.02) {
  tg_ptr <- .pointprocess_to_textgrid_vuv(.self$.xptr, as.numeric(max_voiced_period), as.numeric(max_unvoiced_period))
  TextGrid(.xptr = tg_ptr)
}
.pp_methods$to_sound_pulse_train <- function(.self, sampling_frequency = 44100,
                                              adapt_factor = 1.0, adapt_time = 0.05,
                                              interpolation_depth = 30L) {
  sound_ptr <- .pointprocess_to_sound_pulse_train(
    .self$.xptr, sampling_frequency, adapt_factor, adapt_time, as.integer(interpolation_depth))
  Sound(.xptr = sound_ptr)
}
.pp_methods$to_sound_hum <- function(.self) {
  sound_ptr <- .pointprocess_to_sound_hum(.self$.xptr)
  Sound(.xptr = sound_ptr)
}

# --- Print ---
.pp_methods$print <- function(.self) {
  cat("<Praat PointProcess>\n")
  cat(sprintf("  Time domain: [%.3f, %.3f] s (%.3f s)\n",
              .self$.cpp$get_xmin(), .self$.cpp$get_xmax(), .self$.cpp$get_duration()))
  cat(sprintf("  Points: %d\n", .self$.cpp$get_number_of_points()))
  invisible(.self)
}

lockEnvironment(.pp_methods, bindings = TRUE)

# ============================================================================
# Constructor
# ============================================================================

#' @export
#' @export
PointProcess <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("PointProcess objects must be created from a Sound or Pitch object using to_point_process_*() methods")
  }
  pp_mod <- get_module("pointprocess_module")
  cpp_pp <- pp_mod$RPointProcess$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_pp), class = c("PointProcess", "PraatObject"))
}

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ PointProcess
#' @export
`$.PointProcess` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .pp_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
print.PointProcess <- function(x, ...) x$print()

# Note: Old factory/helper functions below preserved
