# klattgrid-module.R
# R wrapper for KlattGrid Rcpp module
# Phase 2.3 - Klatt formant synthesizer for articulatory speech synthesis

#' Create a KlattGrid object
#'
#' A KlattGrid is a speech synthesizer based on the Klatt formant synthesizer.
#' It allows detailed control over phonation, vocal tract resonances, frication,
#' and other articulatory parameters.
#'
#' @param tmin Start time in seconds
#' @param tmax End time in seconds
#' @param numberOfFormants Number of oral formants (typically 6)
#' @param numberOfNasalFormants Number of nasal formants (typically 1)
#' @param numberOfNasalAntiFormants Number of nasal antiformants (typically 1)
#' @param numberOfTrachealFormants Number of tracheal formants (typically 1)
#' @param numberOfTrachealAntiFormants Number of tracheal antiformants
#  (typically 1)
#' @param numberOfFricationFormants Number of frication formants (typically 6)
#' @param numberOfDeltaFormants Number of delta formants (typically 1)
#'
#' @return KlattGrid object with S3 class
#' @export
#'
#' @examples
#' \donttest{
#' # Create empty KlattGrid
#' kg <- KlattGrid(0, 1, numberOfFormants = 6)
#'
#' # Set pitch contour and voicing amplitude (both required for synthesis)
#' kg$add_pitch_point(0.5, 100)      # 100 Hz at 0.5s
#' kg$add_voicing_amplitude_point(0.5, 90)
#'
#' # Set oral formant frequencies (formantType 1 = ORAL)
#' kg$add_formant_point(1, 1, 0.5, 500)  # F1 = 500 Hz
#' kg$add_formant_point(1, 2, 0.5, 1500) # F2 = 1500 Hz
#'
#' # Synthesize
#' sound <- kg$to_sound()
#' }
#'
#' @name KlattGrid
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.klattgrid_methods <- new.env(hash = TRUE, parent = emptyenv())

# Validation
.klattgrid_methods$is_valid <- function(.self) .self$.cpp$is_valid()

# Time domain
.klattgrid_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.klattgrid_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.klattgrid_methods$get_duration <- function(.self) .self$.cpp$get_duration()

# Synthesis
.klattgrid_methods$to_sound <- function(.self) {
  sound_xptr <- .self$.cpp$to_sound()
  Sound(.xptr = sound_xptr)
}

.klattgrid_methods$to_sound_phonation <- function(.self) {
  sound_xptr <- .self$.cpp$to_sound_phonation()
  Sound(.xptr = sound_xptr)
}

# Pitch manipulation
.klattgrid_methods$get_pitch_at_time <- function(.self,
  t) .self$.cpp$get_pitch_at_time(t)

.klattgrid_methods$add_pitch_point <- function(.self, t, value) {
  .self$.cpp$add_pitch_point(t, value)
  invisible(.self)
}

.klattgrid_methods$remove_pitch_points <- function(.self, t1, t2) {
  .self$.cpp$remove_pitch_points(t1, t2)
  invisible(.self)
}

# Voicing amplitude
.klattgrid_methods$get_voicing_amplitude_at_time <- function(.self, t) {
  .self$.cpp$get_voicing_amplitude_at_time(t)
}

.klattgrid_methods$add_voicing_amplitude_point <- function(.self, t, value) {
  .self$.cpp$add_voicing_amplitude_point(t, value)
  invisible(.self)
}

# Formant manipulation
# formantType: 1=oral, 2=nasal, 3=frication, 4=tracheal, 5=nasal_anti,
#  6=tracheal_anti, 7=delta
.klattgrid_methods$get_formant_at_time <- function(.self, formantType,
  iformant, t) {
  .self$.cpp$get_formant_at_time(as.integer(formantType),
    as.integer(iformant), t)
}

.klattgrid_methods$add_formant_point <- function(.self, formantType, iformant,
  t, value) {
  .self$.cpp$add_formant_point(as.integer(formantType), as.integer(iformant),
    t, value)
  invisible(.self)
}

.klattgrid_methods$remove_formant_points <- function(.self, formantType,
  iformant, t1, t2) {
  .self$.cpp$remove_formant_points(as.integer(formantType),
    as.integer(iformant), t1, t2)
  invisible(.self)
}

# Bandwidth manipulation
.klattgrid_methods$get_bandwidth_at_time <- function(.self, formantType,
  iformant, t) {
  .self$.cpp$get_bandwidth_at_time(as.integer(formantType),
    as.integer(iformant), t)
}

.klattgrid_methods$add_bandwidth_point <- function(.self, formantType,
  iformant, t, value) {
  .self$.cpp$add_bandwidth_point(as.integer(formantType),
    as.integer(iformant), t, value)
  invisible(.self)
}

# File I/O
.klattgrid_methods$save <- function(.self, path) {
  .self$.cpp$save(path)
  invisible(.self)
}

# Display
.klattgrid_methods$print <- function(.self) {
  cat("KlattGrid object\n")
  cat("  Duration:", .self$.cpp$get_duration(), "s\n")
  cat("  Time range: [", .self$.cpp$get_xmin(), ",", .self$.cpp$get_xmax(),
    "]\n")
  invisible(.self)
}

lockEnvironment(.klattgrid_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ KlattGrid
#' @export
`$.KlattGrid` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .klattgrid_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructors
# ============================================================================

#' @export
KlattGrid <- function(tmin = 0.0,
                      tmax = 1.0,
                      numberOfFormants = 6L,
                      numberOfNasalFormants = 1L,
                      numberOfNasalAntiFormants = 1L,
                      numberOfTrachealFormants = 1L,
                      numberOfTrachealAntiFormants = 1L,
                      numberOfFricationFormants = 6L,
                      numberOfDeltaFormants = 1L) {
  mod <- get_module("klattgrid_module")
  xptr <- mod$klattgrid_create(
    tmin, tmax,
    as.integer(numberOfFormants),
    as.integer(numberOfNasalFormants),
    as.integer(numberOfNasalAntiFormants),
    as.integer(numberOfTrachealFormants),
    as.integer(numberOfTrachealAntiFormants),
    as.integer(numberOfFricationFormants),
    as.integer(numberOfDeltaFormants)
  )
  cpp_obj <- mod$RKlattGrid$new(xptr)

  structure(list(
    .cpp = cpp_obj
  ), class = c("KlattGrid", "PraatObject"))
}

#' Create KlattGrid from vowel parameters
#'
#' Creates a KlattGrid pre-configured for synthesizing a vowel sound
#' with specified formant frequencies and bandwidths.
#'
#' @param duration Duration in seconds
#' @param f0start Starting F0 in Hz
#' @param f1 First formant frequency in Hz
#' @param b1 First formant bandwidth in Hz
#' @param f2 Second formant frequency in Hz
#' @param b2 Second formant bandwidth in Hz
#' @param f3 Third formant frequency in Hz
#' @param b3 Third formant bandwidth in Hz
#' @param f4 Fourth formant frequency in Hz (optional)
#' @param bandWidthFraction Bandwidth as fraction of frequency (default 0.05)
#' @param formantFrequencyInterval Formant spacing interval in Hz (default 1000)
#'
#' @return KlattGrid object configured for vowel
#' @examples
#' kg <- klattgrid_create_from_vowel(duration = 0.3, f0start = 120)
#' sound <- kg$to_sound()
#' @export
klattgrid_create_from_vowel <- function(duration = 0.5,
                                      f0start = 100.0,
                                      f1 = 500.0, b1 = 50.0,
                                      f2 = 1500.0, b2 = 100.0,
                                      f3 = 2500.0, b3 = 150.0,
                                      f4 = 3500.0,
                                      bandWidthFraction = 0.05,
                                      formantFrequencyInterval = 1000.0) {
  mod <- get_module("klattgrid_module")
  xptr <- mod$klattgrid_create_from_vowel(
    duration, f0start,
    f1, b1, f2, b2, f3, b3, f4,
    bandWidthFraction,
    formantFrequencyInterval
  )
  cpp_obj <- mod$RKlattGrid$new(xptr)

  structure(list(
    .cpp = cpp_obj
  ), class = c("KlattGrid", "PraatObject"))
}

#' Create example KlattGrid
#'
#' Creates a demonstration KlattGrid with pre-configured parameters
#' for testing the synthesizer.
#'
#' @return KlattGrid example object
#' @examples
#' kg <- klattgrid_create_example()
#' sound <- kg$to_sound()
#' @export
klattgrid_create_example <- function() {
  mod <- get_module("klattgrid_module")
  xptr <- mod$klattgrid_create_example()
  cpp_obj <- mod$RKlattGrid$new(xptr)

  structure(list(
    .cpp = cpp_obj
  ), class = c("KlattGrid", "PraatObject"))
}

# ============================================================================
# Deprecated aliases — forward to new names with a deprecation warning
# ============================================================================

#' @rdname klattgrid_create_from_vowel
#' @usage # Deprecated: use klattgrid_create_from_vowel() instead
#' @export
KlattGrid_createFromVowel <- function(duration = 0.5,
                                      f0start = 100.0,
                                      f1 = 500.0, b1 = 50.0,
                                      f2 = 1500.0, b2 = 100.0,
                                      f3 = 2500.0, b3 = 150.0,
                                      f4 = 3500.0,
                                      bandWidthFraction = 0.05,
                                      formantFrequencyInterval = 1000.0) {
  .Deprecated("klattgrid_create_from_vowel")
  klattgrid_create_from_vowel(duration, f0start, f1, b1, f2, b2, f3, b3, f4,
                               bandWidthFraction, formantFrequencyInterval)
}

#' @rdname klattgrid_create_example
#' @usage # Deprecated: use klattgrid_create_example() instead
#' @export
KlattGrid_createExample <- function() {
  .Deprecated("klattgrid_create_example")
  klattgrid_create_example()
}

# ============================================================================
# S3 Methods
# ============================================================================
