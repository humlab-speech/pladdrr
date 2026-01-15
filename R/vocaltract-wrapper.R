#' @title Praat VocalTract Object
#' @description
#' Praat VocalTract object with direct C++ module binding for articulatory synthesis.
#'
#' @details
#' A VocalTract represents the cross-sectional areas of the vocal tract from
#' glottis to lips, divided into sections. This can be used for:
#' - Articulatory synthesis (convert to Spectrum)
#' - Vowel modeling (create from phone)
#' - Acoustic tube modeling
#'
#' ## Creating VocalTract Objects
#'
#' - `VocalTract(nx, dx)` - Create empty vocal tract with nx sections
#' - `VocalTract$create_from_phone(phone)` - Create from phone name
#'
#' ## Querying
#'
#' - `$get_length()` - Total length in metres
#' - `$get_number_of_sections()` - Number of sections
#' - `$get_section_length()` - Section length in metres
#' - `$get_area(section)` - Area at section (m²)
#' - `$get_areas()` - All areas as vector
#'
#' ## Modification
#'
#' - `$set_area(section, area)` - Set area at section
#' - `$set_areas(areas)` - Set all areas from vector
#'
#' ## Transformation
#'
#' - `$to_spectrum(...)` - Convert to Spectrum for synthesis
#' - `$to_matrix()` - Convert to Matrix
#'
#' @examples
#' \dontrun{
#' # Create from phone
#' vt <- VocalTract$create_from_phone("a")
#' print(vt)
#'
#' # Get areas
#' areas <- vt$get_areas()
#'
#' # Convert to spectrum for synthesis
#' spectrum <- vt$to_spectrum()
#' }
#'
#' @export
VocalTract <- function(nx = 17L, dx = 0.01, .xptr = NULL) {
  
  # Handle creation modes
  if (!is.null(.xptr)) {
    # From existing C++ object
    ptr <- .xptr
  } else {
    # Create new
    ptr <- .vocaltract_create(as.integer(nx), dx)
  }
  
  vt_mod <- get_module("vocaltract_module")
  cpp_obj <- vt_mod$RVocalTract$new(ptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = ptr,
    
    # Query Methods
    get_length = function() {
      cpp_obj$get_length()
    },
    
    get_number_of_sections = function() {
      cpp_obj$get_number_of_sections()
    },
    
    get_section_length = function() {
      cpp_obj$get_section_length()
    },
    
    get_area = function(section) {
      cpp_obj$get_area(as.integer(section))
    },
    
    get_areas = function() {
      cpp_obj$get_areas()
    },
    
    # Modification
    set_area = function(section, area) {
      cpp_obj$set_area(as.integer(section), as.numeric(area))
      invisible(obj)
    },
    
    set_areas = function(areas) {
      cpp_obj$set_areas(as.numeric(areas))
      invisible(obj)
    },
    
    # Transformation
    to_spectrum = function(number_of_frequencies = 4096L,
                          maximum_frequency = 5000.0,
                          glottal_damping = 0.1,
                          radiation_damping = TRUE,
                          internal_damping = TRUE) {
      result_ptr <- cpp_obj$to_spectrum_ptr(
        as.integer(number_of_frequencies),
        as.numeric(maximum_frequency),
        as.numeric(glottal_damping),
        radiation_damping,
        internal_damping
      )
      Spectrum(.xptr = result_ptr)
    },
    
    to_matrix = function() {
      result_ptr <- cpp_obj$to_matrix_ptr()
      Matrix(.xptr = result_ptr)
    },
    
    # Compatibility
    is_valid = function() {
      cpp_obj$is_valid()
    },
    
    get_ptr = function() {
      ptr
    },
    
    get_xptr = function() {
      ptr
    },
    
    # Print method
    print = function() {
      cat("<Praat VocalTract>\n")
      if (!cpp_obj$is_valid()) {
        cat("  [Invalid or deleted object]\n")
      } else {
        cat("  Total length:", sprintf("%.3f", cpp_obj$get_length() * 100), "cm\n")
        cat("  Number of sections:", cpp_obj$get_number_of_sections(), "\n")
        cat("  Section length:", sprintf("%.1f", cpp_obj$get_section_length() * 1000), "mm\n")
        areas <- cpp_obj$get_areas()
        cat("  Area range:", sprintf("%.2f - %.2f", min(areas) * 1e4, max(areas) * 1e4), "cm²\n")
      }
      invisible(obj)
    }
  ), class = c("VocalTract", "PraatObject"))
  
  obj
}

#' Create VocalTract from phone
#' @param phone Phone name. Valid phones are:
#'   - Vowels: a, e, i, o, u
#'   - Special vowels: y1, y2, y3, jery
#'   - Plosives: p, t, k, x
#'   - Syllables: pa, ta, ka, pi, ti, ki, pu, tu, ku
#' @return VocalTract object
#' @export
#' @examples
#' \dontrun{
#' vt_a <- VocalTract$create_from_phone("a")
#' vt_i <- VocalTract$create_from_phone("i")
#'
#' # Compare spectra
#' spec_a <- vt_a$to_spectrum()
#' spec_i <- vt_i$to_spectrum()
#' }
vocaltract_create_from_phone <- function(phone) {
  valid_phones <- c("a", "e", "i", "o", "u", "y1", "y2", "y3", "jery",
                    "p", "t", "k", "x",
                    "pa", "ta", "ka", "pi", "ti", "ki", "pu", "tu", "ku")
  if (!phone %in% valid_phones) {
    stop("Invalid phone '", phone, "'. Valid phones: ", paste(valid_phones, collapse = ", "))
  }

  ptr <- .vocaltract_create_from_phone(phone)
  VocalTract(.xptr = ptr)
}

# Static method support
.vocaltract_static_env <- new.env(parent = emptyenv())
.vocaltract_static_env$create_from_phone <- vocaltract_create_from_phone
.vocaltract_static_env$new <- VocalTract

#' @exportS3Method
`$.vocaltract_constructor` <- function(x, name) {
  .vocaltract_static_env[[name]]
}

class(VocalTract) <- c("vocaltract_constructor", "function")

#' @export
print.VocalTract <- function(x, ...) {
  x$print()
}
