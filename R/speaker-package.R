#' speaker: Direct Access to Praat C Functionality from R
#'
#' The speaker package provides direct, efficient access to Praat C implemented
#' functionality from R using Rcpp. Similar to the parselmouth package for Python,
#' this package enables R users to leverage Praat's powerful phonetic analysis
#' capabilities.
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{praat_version()}: Get Praat version information
#'   \item \code{create_sound()}: Create a sound object
#'   \item \code{sound_stats()}: Calculate basic sound statistics
#'   \item \code{get_sound_duration()}: Get duration of a sound object
#' }
#'
#' @docType package
#' @name speaker-package
#' @aliases speaker
#' @useDynLib speaker, .registration = TRUE
#' @importFrom Rcpp evalCpp
NULL

#' @importFrom Rcpp evalCpp
#' @useDynLib speaker, .registration = TRUE
NULL
