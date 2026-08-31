#' VocalTract
#'
#' Praat VocalTract object: the cross-sectional areas of the vocal tract, from
#' glottis to lips, divided into sections.
#'
#' Used for articulatory synthesis (convert to a Spectrum), vowel modeling
#' (create from a phone), and acoustic tube modeling.
#'
#' @section Usage:
#' \preformatted{
#' VocalTract(nx, dx) # create an empty vocal tract with nx sections
#' VocalTract$create_from_phone(phone)      # create from a phone name
#' }
#'
#' @section Query methods:
#' \itemize{
#'   \item \code{get_length()} - total length in metres
#'   \item \code{get_number_of_sections()} - number of sections
#'   \item \code{get_section_length()} - section length in metres
#'   \item \code{get_area(section)} - area at a section (m^2)
#'   \item \code{get_areas()} - all areas as a vector
#' }
#'
#' @section Modification:
#' \itemize{
#'   \item \code{set_area(section, area)} - set the area at a section
#'   \item \code{set_areas(areas)} - set all areas from a vector
#' }
#'
#' @section Transformation:
#' \itemize{
#'   \item \code{to_spectrum(...)} - convert to a Spectrum for synthesis
#'   \item \code{to_matrix()} - convert to a Matrix
#' }
#'
#' @param nx Number of sections. Default 17.
#' @param dx Section length in metres. Default 0.01.
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   VocalTract object; set internally when a method returns a new VocalTract.
#' @return A \code{VocalTract} object with methods for articulatory tube-model
#  access.
#'
#' @examples
#' vt <- VocalTract$create_from_phone("a")
#' print(vt)
#'
#' areas <- vt$get_areas()
#'
#' spectrum <- vt$to_spectrum()
#'
#' @seealso [Spectrum], [Matrix]
#' @name VocalTract
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.vocaltract_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query
.vocaltract_methods$get_length <- function(.self) .self$.cpp$get_length()
.vocaltract_methods$get_number_of_sections <- function(
  .self) .self$.cpp$get_number_of_sections()
.vocaltract_methods$get_section_length <- function(
  .self) .self$.cpp$get_section_length()
.vocaltract_methods$get_area <- function(.self,
  section) .self$.cpp$get_area(as.integer(section))
.vocaltract_methods$get_areas <- function(.self) .self$.cpp$get_areas()

# Modification (self-returning)
.vocaltract_methods$set_area <- function(.self, section, area) {
  .self$.cpp$set_area(as.integer(section), as.numeric(area))
  invisible(.self)
}
.vocaltract_methods$set_areas <- function(.self, areas) {
  .self$.cpp$set_areas(as.numeric(areas))
  invisible(.self)
}

# Transformation
.vocaltract_methods$to_spectrum <- function(.self,
  number_of_frequencies = 4096L,
                                             maximum_frequency = 5000.0,
                                             glottal_damping = 0.1,
                                             radiation_damping = TRUE,
                                             internal_damping = TRUE) {
  result_ptr <- .self$.cpp$to_spectrum_ptr(
    as.integer(number_of_frequencies),
    as.numeric(maximum_frequency),
    as.numeric(glottal_damping),
    radiation_damping,
    internal_damping
  )
  Spectrum(.xptr = result_ptr)
}

.vocaltract_methods$to_matrix <- function(.self) {
  result_ptr <- .self$.cpp$to_matrix_ptr()
  Matrix(.xptr = result_ptr)
}

# Compatibility
.vocaltract_methods$is_valid <- function(.self) .self$.cpp$is_valid()
.vocaltract_methods$get_ptr <- function(.self) .self$.xptr
.vocaltract_methods$get_xptr <- function(.self) .self$.xptr

# Display
.vocaltract_methods$print <- function(.self) {
  cat("<Praat VocalTract>\n")
  if (.self$.cpp$is_valid()) {
    cat("  Total length:", sprintf("%.3f", .self$.cpp$get_length() * 100),
      "cm\n")
    cat("  Number of sections:", .self$.cpp$get_number_of_sections(), "\n")
    cat("  Section length:",
      sprintf("%.1f", .self$.cpp$get_section_length() * 1000), "mm\n")
    areas <- .self$.cpp$get_areas()
    cat("  Area range:",
      sprintf("%.2f - %.2f", min(areas) * 1e4, max(areas) * 1e4), "cm^2\n")
  } else {
    cat("  [Invalid or deleted object]\n")
  }
  invisible(.self)
}

lockEnvironment(.vocaltract_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ VocalTract
#' @export
`$.VocalTract` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .vocaltract_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
VocalTract <- function(nx = 17L, dx = 0.01, .xptr = NULL) {
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else {
    ptr <- .vocaltract_create(as.integer(nx), dx)
  }

  vt_mod <- get_module("vocaltract_module")
  cpp_obj <- vt_mod$RVocalTract$new(ptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = ptr
  ), class = c("VocalTract", "PraatObject"))
}

# ============================================================================
# Static Methods (backward compatibility: VocalTract$create_from_phone)
# ============================================================================

#' Create VocalTract from phone
#'
#' @param phone Phone name. Valid phones:
#' \itemize{
#'   \item Vowels: a, e, i, o, u
#'   \item Special vowels: y1, y2, y3, jery
#'   \item Plosives: p, t, k, x
#'   \item Syllables: pa, ta, ka, pi, ti, ki, pu, tu, ku
#' }
#' @return VocalTract object
#' @export
#' @examples
#' vt_a <- VocalTract$create_from_phone("a")
#' vt_i <- VocalTract$create_from_phone("i")
#'
#' # Compare spectra
#' spec_a <- vt_a$to_spectrum()
#' spec_i <- vt_i$to_spectrum()
vocaltract_create_from_phone <- function(phone) {
  valid_phones <- c("a", "e", "i", "o", "u", "y1", "y2", "y3", "jery",
                    "p", "t", "k", "x",
                    "pa", "ta", "ka", "pi", "ti", "ki", "pu", "tu", "ku")
  if (!phone %in% valid_phones) {
    stop("Invalid phone '", phone, "'. Valid phones: ", toString(valid_phones))
  }
  ptr <- .vocaltract_create_from_phone(phone)
  VocalTract(.xptr = ptr)
}

.vocaltract_static_env <- new.env(parent = emptyenv())
.vocaltract_static_env$create_from_phone <- vocaltract_create_from_phone
.vocaltract_static_env$new <- VocalTract

#' @exportS3Method "$" vocaltract_constructor
`$.vocaltract_constructor` <- function(x, name) {
  .vocaltract_static_env[[name]]
}

class(VocalTract) <- c("vocaltract_constructor", "function")

# ============================================================================
# S3 Methods
# ============================================================================
