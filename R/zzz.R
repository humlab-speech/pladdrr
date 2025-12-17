#' @useDynLib pladdrr, .registration = TRUE
#' @importFrom Rcpp evalCpp
#' @importFrom methods new
NULL

#' Praat Module
#' 
#' The main Rcpp module exposing Praat functionality.
#' Access classes via: praat$Sound, praat$Pitch, etc.
#' 
#' @format An Rcpp module
#' @export
praat <- NULL

.onLoad <- function(libname, pkgname) {
    # Load the Rcpp module
    # This makes the C++ classes available to R
    praat <<- Rcpp::Module("praat", PACKAGE = pkgname)
    
    # Make praat module available in package namespace
    assign("praat", praat, envir = parent.env(environment()))
}

#' Read a sound file
#' 
#' Convenience function to read a sound file using Praat's Sound object.
#' This is equivalent to calling praat$Sound$new(path) but more R-like.
#' 
#' @param path Path to the sound file
#' @return A PraatSound object (C++ object exposed via Rcpp modules)
#' @export
#' @examples
#' \dontrun{
#' snd <- read_sound("audio.wav")
#' print(snd$duration)
#' pitch <- snd$to_pitch()
#' }
read_sound <- function(path) {
    if (!file.exists(path)) {
        stop("File not found: ", path)
    }
    praat$Sound$new(path)
}

#' Create a Pitch object
#' 
#' Note: In practice, you'd typically create Pitch objects via
#' Sound$to_pitch() rather than directly.
#' 
#' @param floor Pitch floor in Hz
#' @param ceiling Pitch ceiling in Hz
#' @param duration Duration in seconds
#' @return A PraatPitch object
#' @export
create_pitch <- function(floor = 75.0, ceiling = 600.0, duration = 1.0) {
    # This is mainly for testing purposes
    # In real usage, pitch is created from Sound
    .Call("_pladdrr_create_pitch_wrapper", floor, ceiling, duration, PACKAGE = "pladdrr")
}

#' Create a Formant object
#' 
#' Note: In practice, you'd typically create Formant objects via
#' Sound$to_formant() rather than directly.
#' 
#' @param max_formant Maximum formant frequency in Hz
#' @param duration Duration in seconds
#' @return A PraatFormant object
#' @export
create_formant <- function(max_formant = 5500.0, duration = 1.0) {
    # This is mainly for testing purposes
    .Call("_pladdrr_create_formant_wrapper", max_formant, duration, PACKAGE = "pladdrr")
}
