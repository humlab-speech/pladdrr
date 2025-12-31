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
