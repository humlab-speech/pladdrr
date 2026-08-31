#' Get SIMD Capabilities
#' 
#' Reports the SIMD (Single Instruction Multiple Data) capabilities
#' available in the current installation, for diagnostics and debugging.
#' 
#' @return A list with the following components:
#' \describe{
#'   \item{enabled}{Logical indicating if SIMD is currently enabled}
#'   \item{available}{Logical indicating if SIMD support was compiled in}
#'   \item{architecture}{Character string describing the SIMD instruction set
#'     (e.g., "AVX2", "SSE4.2", "NEON")}
#' \item{batch_size_double}{Integer number of doubles processed per SIMD
#  operation}
#' \item{batch_size_float}{Integer number of floats processed per SIMD
#  operation}
#'   \item{version}{Character string describing the SIMD library in use}
#'   \item{debug_build}{Logical indicating the shared object was compiled
#'     without \code{NDEBUG}, i.e. by \code{devtools::load_all()} /
#'     \code{pkgbuild::compile_dll()}, which force
#'     \code{-UNDEBUG -Wall -pedantic -g -O0}. Such a build is not
#'     representative of normal operation and must not be used for timing
#'     comparisons; reinstall with \code{R CMD INSTALL --preclean .} to get
#'     optimised objects.}
#' }
#' 
#' @details
#' The pladdrr package uses SIMD acceleration for computationally intensive
#' operations like autocorrelation, windowing, and statistical computations.
#' The effect varies by code path and platform; use [pladdrr_simd()] to
#' toggle SIMD at runtime and compare a given workload directly.
#'
#' Common SIMD instruction sets:
#' \itemize{
#' \item \strong{AVX2}: 256-bit vectors (4 doubles or 8 floats) - Intel/AMD
#  x86_64
#' \item \strong{SSE4.2}: 128-bit vectors (2 doubles or 4 floats) - Older x86_64
#' \item \strong{NEON}: 128-bit vectors (2 doubles or 4 floats) - ARM (Apple
#  Silicon)
#' }
#' 
#' Set \code{options(pladdrr.use_simd = FALSE)} before loading the package to
#' start in scalar mode, or use [pladdrr_simd()] after load for runtime A/B
#' checks. The option is read during \code{.onLoad}.
#' 
#' @examples
#' # Check SIMD capabilities
#' info <- simd_info()
#' print(info)
#'
#' if (info$architecture == "AVX2") {
#'   message("AVX2 SIMD support detected")
#' }
#'
#' # Disable SIMD temporarily for testing
#' pladdrr_simd(FALSE)
#' # ... run tests ...
#' pladdrr_simd(TRUE)
#'
#' @export
simd_info <- function() {
  .simd_info()
}

#' Get or set runtime SIMD usage
#'
#' @param enabled Logical scalar to enable or disable SIMD at runtime.
#'   Use `NULL` (default) to query the current state without changing it.
#'
#' @return Invisibly, the same list returned by [simd_info()].
#'
#' @examples
#' pladdrr_simd()      # query current state
#' pladdrr_simd(FALSE) # force scalar fallbacks when available
#' pladdrr_simd(TRUE)  # restore SIMD
#'
#' @export
pladdrr_simd <- function(enabled = NULL) {
  if (!is.null(enabled)) {
    if (!is.logical(enabled) || length(enabled) != 1L || is.na(enabled)) {
      stop("enabled must be TRUE, FALSE, or NULL")
    }
    set_global_simd_enabled(enabled)
  }
  invisible(simd_info())
}
