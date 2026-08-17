# Package initialization
# Module loading utilities for Rcpp Modules

# Cache for loaded modules
.module_cache <- new.env(parent = emptyenv())

#' Get a loaded Rcpp Module by name
#' @param name Module name (e.g., "pitch_module")
#' @return The loaded Rcpp Module
#' @keywords internal
get_module <- function(name) {
  if (!exists(name, envir = .module_cache)) {
    .module_cache[[name]] <- tryCatch(
      Rcpp::Module(name, PACKAGE = "pladdrr"),
      error = function(e) {
        stop("pladdrr: failed to load Rcpp module '", name, "' - ",
             conditionMessage(e), call. = FALSE)
      }
    )
  }
  .module_cache[[name]]
}

# Preload all modules on package load
.onLoad <- function(libname, pkgname) {
  # Initialize Praat library (CRITICAL: must come first)
  # This initializes memory allocator, encoding, and class registry
  tryCatch(
    praat_initialize(),
    error = function(e) stop("Failed to initialize Praat library: ", e$message)
  )
  
  # Sync global SIMD toggle from R option (default: TRUE)
  simd_opt <- getOption("pladdrr.use_simd", TRUE)
  tryCatch(
    set_global_simd_enabled(isTRUE(simd_opt)),
    error = function(e) {
      warning("pladdrr: SIMD initialization failed: ", conditionMessage(e),
              "; falling back to scalar code", call. = FALSE)
    }
  )
  
  # Modules load lazily on first use via get_module() (which caches them).
  # No eager preload: it slowed every library(pladdrr) — including each PSOCK
  # batch worker that runs library(pladdrr) — by loading all ~38 modules
  # whether or not they were needed.
}
