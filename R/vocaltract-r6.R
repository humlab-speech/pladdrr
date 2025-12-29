# vocaltract-r6.R
# R6 class for Praat VocalTract objects

#' @title VocalTract Class
#' @description
#' R6 class for Praat VocalTract objects representing vocal tract area functions.
#' Used for articulatory synthesis and vowel/consonant modeling.
#'
#' @details
#' A VocalTract represents the cross-sectional areas of the vocal tract from
#' glottis to lips, divided into sections. This can be used for:
#' - Articulatory synthesis (convert to Spectrum)
#' - Vowel modeling (create from phone)
#' - Acoustic tube modeling
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
VocalTract <- R6::R6Class(
  "VocalTract",
  inherit = PraatObject,

  public = list(
    #' @description Create VocalTract from parameters or external pointer
    #' @param nx Number of sections (default 17 for standard model)
    #' @param dx Section length in metres (default 0.01 = 1cm)
    #' @param .xptr External pointer (for internal use)
    initialize = function(nx = 17L, dx = 0.01, .xptr = NULL) {
      if (!is.null(.xptr)) {
        super$initialize(.xptr)
      } else {
        ptr <- .vocaltract_create(as.integer(nx), dx)
        super$initialize(ptr)
      }
    },

    #' @description Get total length of vocal tract
    #' @return Length in metres
    get_length = function() {
      private$check_valid()
      .vocaltract_get_length(private$ptr)
    },

    #' @description Get number of sections
    #' @return Integer number of sections
    get_number_of_sections = function() {
      private$check_valid()
      .vocaltract_get_number_of_sections(private$ptr)
    },

    #' @description Get section length
    #' @return Section length in metres
    get_section_length = function() {
      private$check_valid()
      .vocaltract_get_section_length(private$ptr)
    },

    #' @description Get area at specific section
    #' @param section Section index (1-based)
    #' @return Area in square metres
    get_area = function(section) {
      private$check_valid()
      .vocaltract_get_area(private$ptr, as.integer(section))
    },

    #' @description Set area at specific section
    #' @param section Section index (1-based)
    #' @param area Area in square metres (must be positive)
    #' @return Self (invisibly)
    set_area = function(section, area) {
      private$check_valid()
      .vocaltract_set_area(private$ptr, as.integer(section), area)
      invisible(self)
    },

    #' @description Get all areas as vector
    #' @return Numeric vector of areas (in square metres)
    get_areas = function() {
      private$check_valid()
      .vocaltract_get_areas(private$ptr)
    },

    #' @description Set all areas from vector
    #' @param areas Numeric vector of areas (length must match number of sections)
    #' @return Self (invisibly)
    set_areas = function(areas) {
      private$check_valid()
      .vocaltract_set_areas(private$ptr, areas)
      invisible(self)
    },

    #' @description Convert to Spectrum for articulatory synthesis
    #' @param number_of_frequencies Number of frequency bins (default 4096)
    #' @param maximum_frequency Maximum frequency in Hz (default 5000)
    #' @param glottal_damping Glottal damping coefficient (default 0.1)
    #' @param radiation_damping Include radiation damping (default TRUE)
    #' @param internal_damping Include internal damping (default TRUE)
    #' @return Spectrum object
    to_spectrum = function(number_of_frequencies = 4096L,
                           maximum_frequency = 5000.0,
                           glottal_damping = 0.1,
                           radiation_damping = TRUE,
                           internal_damping = TRUE) {
      private$check_valid()
      ptr <- .vocaltract_to_spectrum(
        private$ptr,
        as.integer(number_of_frequencies),
        maximum_frequency,
        glottal_damping,
        radiation_damping,
        internal_damping
      )
      Spectrum$new(.xptr = ptr)
    },

    #' @description Convert to Matrix
    #' @return Matrix object
    to_matrix = function() {
      private$check_valid()
      ptr <- .vocaltract_to_matrix(private$ptr)
      Matrix$new(.xptr = ptr)
    },

    #' @description Print method
    print = function() {
      cat("<Praat VocalTract>\n")
      if (!self$is_valid()) {
        cat("  [Invalid or deleted object]\n")
      } else {
        cat("  Total length:", sprintf("%.3f", self$get_length() * 100), "cm\n")
        cat("  Number of sections:", self$get_number_of_sections(), "\n")
        cat("  Section length:", sprintf("%.1f", self$get_section_length() * 1000), "mm\n")
        areas <- self$get_areas()
        cat("  Area range:", sprintf("%.2f - %.2f", min(areas) * 1e4, max(areas) * 1e4), "cm²\n")
      }
      invisible(self)
    }
  )
)

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
VocalTract$create_from_phone <- function(phone) {
  valid_phones <- c("a", "e", "i", "o", "u", "y1", "y2", "y3", "jery",
                    "p", "t", "k", "x",
                    "pa", "ta", "ka", "pi", "ti", "ki", "pu", "tu", "ku")
  if (!phone %in% valid_phones) {
    stop("Invalid phone '", phone, "'. Valid phones: ", paste(valid_phones, collapse = ", "))
  }

  ptr <- .vocaltract_create_from_phone(phone)
  vt <- VocalTract$new(.xptr = ptr)
  vt
}
