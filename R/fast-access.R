# Fast Data Access for Sound Objects
# Renamed from zerocopy-access.R (v4.8.34) — the original "zerocopy"
# name was misleading: these functions copy data via direct pointer
# access, which is faster than Praat's per-sample accessor but NOT
# zero-copy.

#' Get Sound Values (Fast Copy)
#'
#' Copies Sound sample data via direct pointer access, instead of going
#' through Praat's per-sample accessor as `sound$get_values()` does.
#'
#' @param sound A Sound object created with `Sound()`
#' @param channel Channel number (1-based, default 1)
#'
#' @return Numeric vector (independent copy of sample data).
#'   Has class `c("fast_vector", "numeric")` and a `readonly` attribute
#'   for backward compatibility.
#'
#' The returned vector is an independent R copy — safe to modify,
#' store, or use after the Sound object is garbage collected.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#  16000)
#'
#' # Fast copy for analysis
#' samples <- get_sound_values_fast(sound, channel = 1)
#' rms <- sqrt(mean(samples^2))
#' peak <- max(abs(samples))
#'
#' # Equivalent — also a copy
#' samples2 <- sound$get_values(channel = 1)
#'
#' @seealso
#' - [is_fast_vector()] to check if vector was created by fast access
#' - [sound_as_matrix_fast()] for matrix output
#'
#' @export
get_sound_values_fast <- function(sound, channel = 1) {
  if (!inherits(sound, "Sound")) {
    stop("Input must be a Sound object created with Sound()")
  }

  sound_values_fast(sound$get_xptr(), channel = channel)
}


#' Get Sound Sample Times (Fast Computation)
#'
#' Returns time values for each sample using a direct computation, instead of
#' `sound$get_sample_times()`. Still allocates memory for the result.
#'
#' @inheritParams pladdrr_shared_sound_a sound
#'
#' @return Numeric vector of sample times (in seconds)
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#  16000)
#' times <- get_sound_times_fast(sound)
#'
#' @export
get_sound_times_fast <- function(sound) {
  if (!inherits(sound, "Sound")) {
    stop("Input must be a Sound object")
  }

  sound_times_fast(sound$get_xptr())
}


#' Convert Sound to Matrix (Fast Copy)
#'
#' Copies Sound data into a matrix (samples x channels) via direct
#' pointer access.
#'
#' @inheritParams pladdrr_shared_sound_a sound
#' @param zerocopy Ignored (kept for backward compatibility). All paths copy.
#'
#' @return Numeric matrix (samples x channels)
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#  16000)
#' mat <- sound_as_matrix_fast(sound)
#'
#' @export
sound_as_matrix_fast <- function(sound, zerocopy = FALSE) {
  if (!inherits(sound, "Sound")) {
    stop("Input must be a Sound object")
  }

  sound_as_matrix_fast_impl(sound$get_xptr(), zerocopy = zerocopy)
}


#' Check if Vector is a Fast-Access Vector
#'
#' Tests whether a numeric vector was created by [get_sound_values_fast()].
#'
#' @param x A vector to test
#'
#' @return Logical. TRUE if vector has fast_vector/zerocopy_vector class.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#  16000)
#'
#' fast_vec <- get_sound_values_fast(sound, 1)
#' regular_vec <- sound$get_values(1)
#'
#' is_fast_vector(fast_vec)     # TRUE
#' is_fast_vector(regular_vec)  # FALSE
#'
#' @export
is_fast_vector <- function(x) {
  is_fast_access(x)
}


#' Print Method for Fast-Access Vectors
#'
#' @param x A fast_vector
#' @param ... Additional arguments passed to print
#' @return \code{x}, invisibly.
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate =
#  16000)
#' samples <- get_sound_values_fast(sound, channel = 1)
#' print(samples)
#' @export
print.fast_vector <- function(x, ...) {
  cat("Fast-Access Vector\n")
  cat("Length:", length(x), "\n")
  cat("Range: [", min(x), ",", max(x), "]\n\n")
  cat("First 10 values:\n")
  print(head(x, 10))
  if (length(x) > 10) {
    cat("... (", length(x) - 10, " more values)\n", sep = "")
  }
  invisible(x)
}


# ============================================================================
# Deprecated aliases — forward to new names with a deprecation warning
# ============================================================================

#' @rdname get_sound_values_fast
#' @usage # Deprecated: use get_sound_values_fast() instead
#' @export
get_sound_values_zerocopy <- function(sound, channel = 1) {
  .Deprecated("get_sound_values_fast")
  get_sound_values_fast(sound, channel = channel)
}

#' @rdname sound_as_matrix_fast
#' @usage # Deprecated: use sound_as_matrix_fast() instead
#' @export
sound_as_matrix_zerocopy <- function(sound, zerocopy = FALSE) {
  .Deprecated("sound_as_matrix_fast")
  sound_as_matrix_fast(sound, zerocopy = zerocopy)
}

#' @rdname is_fast_vector
#' @usage # Deprecated: use is_fast_vector() instead
#' @export
is_zerocopy_vector <- function(x) {
  .Deprecated("is_fast_vector")
  is_fast_vector(x)
}

#' Print method for legacy zerocopy_vector class (deprecated)
#' @param x A zerocopy_vector
#' @param ... Additional arguments
#' @return \code{x}, invisibly.
#' @examples
#' # zerocopy_vector is a deprecated class name; fast_vector is current.
#' legacy_vec <- structure(c(0.1, 0.2, 0.3), class = c("zerocopy_vector",
#  "numeric"))
#' print(legacy_vec)
#' @export
print.zerocopy_vector <- function(x, ...) {
  print.fast_vector(x, ...)
  invisible(x)
}
