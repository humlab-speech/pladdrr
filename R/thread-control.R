# Runtime control of multi-threaded Praat analyses

#' Control multi-threading of Praat analyses
#'
#' Praat's compute kernels (pitch, formant, spectrogram, CPPS, ...) run
#' multi-threaded by default, using all available processor cores. Use this
#' function to cap or disable threading (e.g. inside a parallel `mclapply()`
#' pipeline where each worker should stay single-threaded), or to restore the
#' default.
#'
#' Threading never changes results: threads partition analysis frames and each
#' frame is computed exactly as in single-threaded mode.
#'
#' @param n Maximum number of concurrent threads. Use `1` to disable
#'   threading, `NULL` (default) to leave the setting unchanged and just
#'   return the current state, or `0` to restore automatic mode (all cores).
#'
#' @return Invisibly, a list describing the current state:
#'   \describe{
#'     \item{processors}{Number of logical cores detected.}
#'     \item{enabled}{Whether multi-threading is enabled.}
#'     \item{max_threads}{Effective maximum concurrent threads.}
#'     \item{min_elements_per_thread}{Minimum work per thread; 0 means each
#'       analysis routine uses its own tuned threshold.}
#'   }
#'
#' @examples
#' \dontrun{
#' pladdrr_threads()      # query current state
#' #> $processors [1] 10 ; $enabled [1] TRUE ; $max_threads [1] 10 ...
#' pladdrr_threads(1)     # single-threaded (e.g. inside mclapply workers)
#' pladdrr_threads(4)     # cap at 4 threads
#' pladdrr_threads(0)     # back to automatic (all cores)
#' }
#' @export
pladdrr_threads <- function(n = NULL) {
  if (!is.null(n)) {
    n <- as.integer(n)
    if (length(n) != 1L || is.na(n) || n < 0L) {
      stop("n must be a single non-negative integer (0 = automatic)")
    }
    .pladdrr_set_threads_cpp(
      use_multithreading = n != 1L,
      max_threads = n,
      min_elements_per_thread = 0L
    )
  }
  invisible(.pladdrr_get_threads_cpp())
}
