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
    .module_cache[[name]] <- Rcpp::Module(name, PACKAGE = "pladdrr")
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
  
  # Preload all modules into cache
  modules <- c(
    "pitch_module", "sound_module", "formant_module",
    "intensity_module", "spectrum_module", "spectrogram_module",
    "harmonicity_module", "pitchtier_module", "intensitytier_module",
    "durationtier_module", "amplitudetier_module", "pointprocess_module",
    "ltas_module", "matrix_module", "cepstrum_module",
    "powercepstrum_module", "cochleagram_module", "excitation_module",
    "electroglottogram_module", "formantgrid_module", "formanttier_module",
    "vocaltract_module", "longsound_module", "lpc_module",
    "table_module", "textgrid_module", "manipulation_module",
    "polygon_module", "formantpath_module", "complexspectrogram_module",
    "klattgrid_module", "sound_operations_module", "interpreter_module"
  )
  
  for (mod in modules) {
    tryCatch(
      get_module(mod),
      error = function(e) warning("Failed to load module: ", mod, " - ", e$message)
    )
  }
}
