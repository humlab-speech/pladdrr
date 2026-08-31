#' pladdrr: Direct Access to Praat's Core Algorithms from R
#'
#' Praat's C/C++ engine, called directly from R via Rcpp. No external Praat
#' installation, no scripting layer, no shelling out. pladdrr links against
#' Praat's own analysis code, so results match Praat to within a tight
#' numerical tolerance, and covers most of what Praat can do: acoustic
#' analysis, voice quality, articulatory synthesis, annotation and
#' multivariate statistics.
#'
#' @section Acoustic Analysis:
#'
#' \itemize{
#'   \item \strong{Sound}: read/write WAV, AIFF, FLAC, MP3, NIST; generate
#'         tones and noise; \code{LongSound} for streaming files too large to
#'         hold in memory
#'   \item \strong{Pitch}: F0 contours, autocorrelation and cross-correlation
#'         methods, quality-aware tracking
#'   \item \strong{Formant}: F1-F5 via LPC and Burg estimation,
#'         \code{FormantPath} for robust tracking, \code{FormantModeler}
#'   \item \strong{Intensity, Harmonicity, Spectrum/Spectrogram, Ltas,
#'         Cepstrum}: the standard Praat contour and spectral objects
#' }
#'
#' @section Voice Quality:
#'
#' \itemize{
#'   \item CPPS (smoothed cepstral peak prominence) and AVQI (Acoustic Voice
#'         Quality Index), both parameter-matched to Praat
#'   \item Jitter, shimmer and HNR in a single batched call
#'   \item Voice activity detection
#' }
#'
#' @section Synthesis, Annotation and Multivariate Tools:
#'
#' \itemize{
#'   \item \code{Manipulation} (PSOLA resynthesis) and \code{KlattGrid}
#'         (formant synthesis)
#'   \item \code{TextGrid} for reading, writing and querying annotations
#'   \item \code{PCA}, \code{DTW} and \code{Discriminant} for multivariate
#'         and comparative analysis
#'   \item \code{PraatInterpreter} to run raw Praat scripts when you need
#'         something pladdrr doesn't wrap directly
#' }
#'
#' @section Performance:
#'
#' Batch queries (e.g. formants or pitch at many time points) run in a
#' single C++ call rather than one R-level call per point. The
#'  CPPS/PowerCepstrogram
#' path is multi-threaded via Praat's own \code{MelderThread}, and
#' \code{\link{pladdrr_threads}} controls how many cores it uses.
#' \code{\link{simd_info}} reports whether the installed build is using SIMD
#' kernels.
#'
#' @section Object Model:
#'
#' Objects are lightweight S3 lists (e.g. class \code{c("Sound",
#'  "PraatObject")})
#' with a custom \code{$} method that dispatches to a shared method table:
#' this gives R6-style \code{sound$get_pitch()} call syntax at a fraction of
#' R6's per-object memory cost. \code{PraatInterpreter} is a plain R6 class,
#' since its state (a live Praat interpreter session) doesn't fit the
#'  shared-table
#' pattern.
#'
#' @section Undefined Values:
#'
#' Following R conventions, undefined analysis values (e.g. pitch in unvoiced
#' segments, formants in silence) are returned as \code{NA}. Quality warnings
#' are issued when a result may be unreliable, and can be suppressed with the
#' usual R warning-control mechanisms.
#'
#' @section Getting Started:
#'
#' \code{vignette("getting-started", package = "pladdrr")} is the place to
#' start. Other vignettes worth knowing about:
#'
#' \itemize{
#'   \item \code{vignette("formant-analysis")} - formant tracking, including
#'         \code{FormantPath}
#' \item \code{vignette("speech-synthesis-klattgrid")} - articulatory synthesis
#' \item \code{vignette("textgrid-workflows")} - reading and querying
#'  annotations
#' \item \code{vignette("performance-optimization")} - batching, threading, SIMD
#'   \item \code{vignette("migration-from-praat")} and
#'         \code{vignette("migration-from-parselmouth")} - for those coming
#'         from Praat scripting or Python
#' }
#'
#' @section License and Attribution:
#'
#' pladdrr is licensed under GPL-3, compatible with Praat's own GPL-2+
#' license. Praat was created by Paul Boersma and David Weenink at the
#' Institute of Phonetic Sciences, University of Amsterdam, and its source is
#' bundled here under \code{src/praat.github.io/}.
#'
#' Run \code{citation("pladdrr")} for up-to-date citation details for both
#' pladdrr and the bundled Praat version.
#'
#' @docType package
#' @name pladdrr-package
#' @aliases pladdrr
#' @useDynLib pladdrr, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @importFrom R6 R6Class
#' @importFrom rlang .data
#' @importFrom data.table data.table as.data.table is.data.table setDT setkeyv
#'  rbindlist
#' @importFrom stats aggregate approx fitted lm median predict quantile rnorm sd
#'  time
#' @importFrom utils head
#' @importFrom methods setLoadAction
#' @rawNamespace export(PraatInterpreter)
#' @keywords internal
"_PACKAGE"

# Declare NSE globals used by data.table/ggplot2 aes() to silence R CMD check's
# "no visible binding for global variable" notes.
utils::globalVariables(c(".data", "formant_number", "cpp", "quefrency",
                         "power_db"))

## Package initialization

# .onLoad lives in R/zzz.R. A second definition used to sit here; with no
# Collate field, files collate alphabetically, so zzz.R always overwrote it and
# this copy never ran. Its only extra effect was seeding
# options(pladdrr.return_datatable = TRUE), which was redundant (the helper
# that read it defaulted to TRUE) and has since been removed.

#' @keywords internal
#' @noRd
.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "pladdrr: direct access to Praat's core algorithms from R.\n",
    "See ?pladdrr for an overview, or citation(\"pladdrr\") for citation details."
  )
  # A -O0/-UNDEBUG shared object (devtools::load_all(), pkgbuild::compile_dll())
  # survives a later `R CMD INSTALL` because make keeps the stale .o files. It
  #  is
  # ~4x slower on the CPPS path with no other symptom, so say so out loud.
  if (isTRUE(tryCatch(.simd_info()$debug_build, error = function(e) FALSE))) {
    packageStartupMessage(
      "NOTE: pladdrr was compiled as a debug build (no NDEBUG, -O0). It is ",
      "several times slower than an optimised build and must not be used for ",
      "benchmarking. Reinstall with: R CMD INSTALL --preclean ."
    )
  }
}

#' Shared parameter documentation for pladdrr functions
#'
#' Common `@param` descriptions used across many functions. Functions inherit
#' from this topic via `@inheritParams pladdrr_shared_params <param>` to avoid
#' duplicating identical documentation.
#'
#' @param sound Sound object or external pointer
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param ... Additional arguments (currently unused)
#' @param sounds List of Sound objects (R6) or external pointers
#' @param time Time in seconds
#' @param sampling_rate Sampling rate in Hz (default: 44100)
#' @param return_r6 Logical. Return R6 Pitch objects (TRUE) or raw xptrs (FALSE)
#' @param time_step Numeric. Time step (0 = automatic)
#' @param name Parameter name for error messages
#' @param times Numeric vector of time points (in seconds)
#' @param intensity An Intensity R6 object
#' @param time_range Optional time range
#' @param pitch Pitch object or external pointer
#' @param pitch_floor Numeric. Pitch floor in Hz (default: 75)
#' @param pitch_ceiling Numeric. Pitch ceiling in Hz (default: 600)
#' @param max_candidates Integer. Max candidates per frame (default: 15)
#' @param unit Unit: "Hz" or "semitones"
#' @param row.names Ignored
#' @param optional Ignored
#' @param fmin Low frequency cutoff (Hz)
#' @param fmax High frequency cutoff (Hz)
#' @param x Object to check
#' @param smooth Smoothing bandwidth (Hz)
#' @param tmin Start time in seconds
#' @param tmax End time in seconds
#' @param title Character. Plot title (default: auto-generated)
#' @param tier Tier number (1-based) or tier name
#' @param textgrid TextGrid object
#' @param sound1 First Sound object
#' @param signal_outside Signal outside time domain: 1=zero, 2=similar
#' @param scaling Scaling: 1=integral, 2=sum, 3=normalize, 4=peak_0.99
#' @param pointprocess A PointProcess object
#' @param n_cores Integer. Number of cores (default: auto)
#' @param max_pitch Pitch ceiling in Hz (default: 600)
#' @param interpolate Whether to interpolate
#' @param from_freq Start frequency in Hz (NULL = from 0)
#' @param files Character vector of file paths
#' @param duration Duration in seconds (default: 1.0)
#' @param cepstrogram PowerCepstrogram object
#' @param max_formant Maximum formant frequency (Hz)





#' @rdname pladdrr_shared_params
pladdrr_shared_params <- function() invisible(NULL)

#' Shared parameter docs for functions taking a plain Sound object
#'
#' @param sound Sound object
#' @rdname pladdrr_shared_sound
pladdrr_shared_sound <- function() invisible(NULL)

#' Shared parameter docs for functions using 0-based time conventions
#'
#' @param from_time Start time (0 = beginning)
#' @param to_time End time (0 = end)
#' @rdname pladdrr_shared_time0
pladdrr_shared_time0 <- function() invisible(NULL)

#' Shared parameter docs for functions taking an R6 Sound object
#'
#' @param sound A Sound R6 object
#' @rdname pladdrr_shared_sound_r6
pladdrr_shared_sound_r6 <- function() invisible(NULL)

#' Shared parameter docs for functions taking an R6 Sound object (alternate)
#'
#' @param sound A Sound object
#' @rdname pladdrr_shared_sound_a
pladdrr_shared_sound_a <- function() invisible(NULL)

#' Shared parameter docs for functions taking a plain Pitch object
#'
#' @param pitch Pitch object
#' @rdname pladdrr_shared_pitch
pladdrr_shared_pitch <- function() invisible(NULL)

#' Shared parameter docs for functions taking an R6 Pitch object
#'
#' @param pitch A Pitch R6 object
#' @rdname pladdrr_shared_pitch_r6
pladdrr_shared_pitch_r6 <- function() invisible(NULL)

#' Shared parameter docs for functions taking an S3/R6 Sound
#'
#' @param sound A praat_sound (S3) or Sound (R6) object
#' @rdname pladdrr_shared_sound_legacy
pladdrr_shared_sound_legacy <- function() invisible(NULL)

#' Shared parameter docs for auto time-step functions
#'
#' @param time_step Time step (0 = auto)
#' @rdname pladdrr_shared_timeauto
pladdrr_shared_timeauto <- function() invisible(NULL)

#' Shared parameter docs for functions taking a TextGrid R6 object
#'
#' @param textgrid A TextGrid object
#' @rdname pladdrr_shared_textgrid_r6
pladdrr_shared_textgrid_r6 <- function() invisible(NULL)

#' Shared parameter docs for functions taking an R6 Pitch object (alt)
#'
#' @param pitch A Pitch object
#' @rdname pladdrr_shared_pitch_a
pladdrr_shared_pitch_a <- function() invisible(NULL)

#' Shared parameter docs for display-formant functions
#'
#' @param max_formant Maximum formant number to display (default: 3)
#' @rdname pladdrr_shared_maxformant
pladdrr_shared_maxformant <- function() invisible(NULL)

#' Shared parameter docs for functions using the 0.75/pitch_floor auto time-step
#'
#' @param time_step Time step (0 = auto, typically 0.75/pitch_floor)
#' @rdname pladdrr_shared_timeauto75
pladdrr_shared_timeauto75 <- function() invisible(NULL)
