#' @title Praat FormantGrid Object
#' @description
#' Praat FormantGrid object with direct C++ module binding for formant manipulation.
#'
#' @details
#' FormantGrid objects allow manipulation of formant frequencies and bandwidths
#' over time for voice transformation and synthesis. This is the editable
#' counterpart to the read-only Formant object.
#'
#' @return A \code{FormantGrid} object with methods for formant frequency and bandwidth manipulation.
#'
#' @examples
#' fg <- FormantGrid(0, 1, number_of_formants = 3)
#' fg$add_formant_point(1, 0.5, 700)
#' fg$get_formant_at_time(1, 0.5)
#' fg$get_number_of_formants()
#'
#' @name FormantGrid
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.formantgrid_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query - Time domain
.formantgrid_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.formantgrid_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.formantgrid_methods$get_number_of_formants <- function(.self) .self$.cpp$get_number_of_formants()

# Query - Values
.formantgrid_methods$get_formant_at_time <- function(.self, formant_number, time) {
  .self$.cpp$get_formant_at_time(as.integer(formant_number), as.numeric(time))
}
.formantgrid_methods$get_bandwidth_at_time <- function(.self, formant_number, time) {
  .self$.cpp$get_bandwidth_at_time(as.integer(formant_number), as.numeric(time))
}

# Modification (self-returning)
.formantgrid_methods$add_formant_point <- function(.self, formant_number, time, value) {
  .self$.cpp$add_formant_point(as.integer(formant_number), as.numeric(time), as.numeric(value))
  invisible(.self)
}
.formantgrid_methods$add_bandwidth_point <- function(.self, formant_number, time, value) {
  .self$.cpp$add_bandwidth_point(as.integer(formant_number), as.numeric(time), as.numeric(value))
  invisible(.self)
}
.formantgrid_methods$remove_formant_points_between <- function(.self, formant_number, tmin, tmax) {
  .self$.cpp$remove_formant_points_between(as.integer(formant_number), as.numeric(tmin), as.numeric(tmax))
  invisible(.self)
}
.formantgrid_methods$remove_bandwidth_points_between <- function(.self, formant_number, tmin, tmax) {
  .self$.cpp$remove_bandwidth_points_between(as.integer(formant_number), as.numeric(tmin), as.numeric(tmax))
  invisible(.self)
}

# Conversion
.formantgrid_methods$to_formant <- function(.self, time_step = 0.005, intensity = 1.0) {
  ptr_out <- .formantgrid_to_formant(.self$.xptr, time_step, intensity)
  Formant(.xptr = ptr_out)
}
.formantgrid_methods$to_sound <- function(.self, sampling_frequency = 44100,
                                          t_start = .self$get_start_time(),
                                          f0_start = 140,
                                          t_mid = (.self$get_start_time() + .self$get_end_time()) / 2,
                                          f0_mid = f0_start,
                                          t_end = .self$get_end_time(),
                                          f0_end = f0_mid,
                                          adapt_factor = 1.0,
                                          maximum_period = 0.05,
                                          open_phase = 0.7,
                                          collision_phase = 0.03,
                                          power1 = 3.0,
                                          power2 = 4.0) {
  ptr_out <- .formantgrid_to_sound(
    .self$.xptr, as.numeric(sampling_frequency),
    as.numeric(t_start), as.numeric(f0_start),
    as.numeric(t_mid), as.numeric(f0_mid),
    as.numeric(t_end), as.numeric(f0_end),
    as.numeric(adapt_factor), as.numeric(maximum_period),
    as.numeric(open_phase), as.numeric(collision_phase),
    as.numeric(power1), as.numeric(power2)
  )
  Sound(.xptr = ptr_out)
}

# Export
.formantgrid_methods$as_data_frame <- function(.self) {
  df <- .self$.cpp$as_data_frame(0.005)
  names(df) <- c("formant_number", "time", "frequency", "bandwidth")
  df
}
.formantgrid_methods$save <- function(.self, path) {
  .self$.cpp$save(as.character(path))
  invisible(.self)
}

# Utility
.formantgrid_methods$get_xptr <- function(.self) .self$.xptr

# Display
.formantgrid_methods$print <- function(.self) {
  cat("<Praat FormantGrid>\n")
  cat(sprintf("  Time domain: %.3f to %.3f s\n", .self$.cpp$get_xmin(), .self$.cpp$get_xmax()))
  cat(sprintf("  Number of formants: %d\n", .self$.cpp$get_number_of_formants()))
  invisible(.self)
}

.formantgrid_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.formantgrid_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ FormantGrid
#' @export
`$.FormantGrid` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .formantgrid_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
FormantGrid <- function(tmin = NULL, tmax = NULL, number_of_formants = 10,
                        initial_first_formant = 550, initial_formant_spacing = 1100,
                        initial_first_bandwidth = 60, initial_bandwidth_spacing = 50,
                        .xptr = NULL) {
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else {
    stopifnot(
      "tmin and tmax must be provided" = !is.null(tmin) && !is.null(tmax),
      "tmin must be less than tmax" = tmin < tmax,
      "number_of_formants must be positive" = number_of_formants > 0
    )
    ptr <- .formantgrid_create(
      tmin, tmax, as.integer(number_of_formants),
      initial_first_formant, initial_formant_spacing,
      initial_first_bandwidth, initial_bandwidth_spacing
    )
  }

  grid_mod <- get_module("formantgrid_module")
  cpp_obj <- grid_mod$RFormantGrid$new(ptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = ptr
  ), class = c("FormantGrid", "PraatObject"))
}

# ============================================================================
# S3 Methods
# ============================================================================

#' @export
print.FormantGrid <- function(x, ...) x$print()

#' @export
as.data.frame.FormantGrid <- function(x, ...) x$as_data_frame()
