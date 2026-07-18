#' pladdrr: Direct Access to Praat C Functionality from R
#'
#' The pladdrr package provides direct access to Praat's C phonetic analysis
#' functionality from R. Praat is a widely-used tool for speech analysis in
#' phonetics research. This package wraps Praat's core C library using Rcpp,
#' providing efficient, native access to Praat's analysis capabilities without
#' requiring external Praat installation or scripting.
#'
#' @section Core Features:
#'
#' \strong{Sound Operations:}
#' \itemize{
#'   \item Create and manipulate sound objects
#'   \item Read and write audio files (WAV, AIFF, FLAC, MP3, NIST via native Praat)
#'   \item Extract basic sound properties (duration, sampling rate, etc.)
#'   \item Generate synthetic sounds (sine waves, white noise)
#' }
#'
#' \strong{Pitch Analysis:}
#' \itemize{
#'   \item Extract fundamental frequency (F0) contours
#'   \item Get pitch at specific time points
#'   \item Calculate pitch statistics (mean, median, range)
#'   \item Quality-aware pitch tracking with configurable parameters
#' }
#'
#' \strong{Formant Analysis:}
#' \itemize{
#'   \item Extract formant frequencies (F1-F5)
#'   \item Get formants at specific time points
#'   \item Calculate formant statistics and trajectories
#'   \item LPC-based formant estimation
#' }
#'
#' \strong{Intensity and Spectral Analysis:}
#' \itemize{
#'   \item Compute intensity contours
#'   \item Create spectrograms
#'   \item Extract spectral properties
#' }
#'
#' @section Design Principles:
#'
#' The pladdrr package follows these core principles:
#'
#' \enumerate{
#'   \item \strong{Scientific Accuracy}: All analyses must match Praat's output
#'         within 0.1\% relative error tolerance
#'   \item \strong{R Package Standards}: Full compliance with CRAN requirements
#'         and R package best practices
#'   \item \strong{Efficient C++ Integration}: Direct C++ access via Rcpp for
#'         performance
#'   \item \strong{Test-Driven Development}: Comprehensive test coverage with
#'         reference validation
#'   \item \strong{Comprehensive Documentation}: All functions fully documented
#'         with examples and vignettes
#' }
#'
#' @section Object Types:
#'
#' The package uses S3 classes to represent Praat objects:
#'
#' \describe{
#'   \item{\code{praat_sound}}{Sound object containing audio data and metadata}
#'   \item{\code{praat_pitch}}{Pitch contour with time-frequency pairs}
#'   \item{\code{praat_formant}}{Formant tracks (F1-F5) with bandwidths}
#'   \item{\code{praat_intensity}}{Intensity contour over time}
#'   \item{\code{praat_spectrogram}}{Time-frequency-power spectrogram}
#' }
#'
#' @section Undefined Values:
#'
#' Following R conventions, undefined analysis values (e.g., pitch in unvoiced
#' segments, formants in silence) are returned as \code{NA}. Quality warnings
#' are issued when analysis results may be unreliable, but can be suppressed
#' using standard R warning control mechanisms.
#'
#' @section Getting Started:
#'
#' See \code{vignette("basic-usage", package = "pladdrr")} for an introduction
#' to the package. Additional vignettes cover specific analysis types:
#'
#' \itemize{
#'   \item \code{vignette("pitch-analysis")} - Pitch extraction and analysis
#'   \item \code{vignette("formant-analysis")} - Formant tracking
#'   \item \code{vignette("spectral-analysis")} - Spectrograms and spectral features
#' }
#'
#' @section License and Attribution:
#'
#' This package is licensed under GPL-3, compatible with Praat's GPL-2+ license.
#' Praat was created by Paul Boersma and David Weenink of the Institute of
#' Phonetic Sciences, University of Amsterdam.
#'
#' When using this package in publications, please cite both this package and
#' Praat:
#'
#' Boersma, Paul & Weenink, David (2023). Praat: doing phonetics by computer
#' [Computer program]. Version 6.3.x, retrieved from https://praat.org/
#'
#' @docType package
#' @name pladdrr-package
#' @aliases pladdrr
#' @useDynLib pladdrr, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @importFrom R6 R6Class
#' @importFrom rlang .data
#' @importFrom data.table data.table as.data.table is.data.table setDT setkeyv rbindlist
#' @importFrom stats aggregate approx fitted lm median predict quantile rnorm sd time
#' @importFrom utils head
#' @rawNamespace export(PraatInterpreter)
#' @keywords internal
"_PACKAGE"

# Declare NSE globals used by data.table/ggplot2 aes() to silence R CMD check's
# "no visible binding for global variable" notes.
utils::globalVariables(c(".data", "formant_number", "cpp", "quefrency",
                         "power_db", ".matrix_read"))

## Package initialization

#' @keywords internal
.onLoad <- function(libname, pkgname) {
  # Initialize Praat library components
  praat_initialize()
  
  # Set default to return data.table (v4.0.0+)
  # Users can opt out with: options(pladdrr.return_datatable = FALSE)
  # but this is deprecated and will be removed in v5.0
  if (is.null(getOption("pladdrr.return_datatable"))) {
    options(pladdrr.return_datatable = TRUE)
  }
}

#' @keywords internal
.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "pladdrr v4.0: Now using data.table for high-performance data operations\n",
    "See ?pladdrr for an overview and citation information.\n",
    "Use citation('pladdrr') for citing this package in publications."
  )
}
