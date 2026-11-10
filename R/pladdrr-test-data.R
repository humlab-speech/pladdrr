#' Data files shipped with pladdrr, and how the tests use them
#'
#' The package ships a few small files so that the examples and the test suite
#' can be run, and any test result reproduced, by a user. Find them with
#' \code{system.file()}; none is loaded into the session automatically.
#'
#' \itemize{
#'   \item \code{system.file("extdata", "test.wav", package = "pladdrr")}: a
#'     one-second, 44.1 kHz recording used by the examples.
#'   \item \code{system.file("extdata", "test.TextGrid", package = "pladdrr")}: a
#'     small TextGrid used by the TextGrid examples and tests.
#'   \item \code{system.file("extdata", "benchmarkdata1min.TextGrid", package =
#'     "pladdrr")}: a one-minute TextGrid used for the batch-query benchmarks.
#'   \item \code{system.file("testdata", "speech_sample_pitch_reference.csv",
#'     package = "pladdrr")}: reference pitch values (time, frequency, strength)
#'     that the faithfulness tests compare against.
#'   \item \code{system.file("signalfiles", "DSI", "input", package = "pladdrr")}:
#'     the voice recordings of the Dysphonia Severity Index example.
#' }
#'
#' Most tests need no file at all: they build their signals with
#' \code{\link{generate_sine_wave}}, \code{\link{generate_noise}},
#' \code{\link{sound_create_pure_tone}} or \code{\link{klattgrid_create_from_vowel}},
#' whose output is known exactly (a tone of given frequency and amplitude, or a
#' vowel with given formant targets). Those generators are exported so that a
#' user can recreate every synthetic test signal; the faithfulness tests
#' (\code{tests/testthat/test-praat-faithfulness.R}) compare pladdrr with the
#' Praat application on such signals and on \code{test.wav}.
#'
#' @return No return value; this page only documents the shipped data files.
#' @examples
#' file.exists(system.file("extdata", "test.wav", package = "pladdrr"))
#'
#' @name pladdrr-test-data
#' @seealso \code{\link{pladdrr-references}}
#' @keywords documentation
NULL
