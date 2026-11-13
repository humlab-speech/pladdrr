# as-matrix-fallback.R — one as.matrix() fallback for every object class
# (F-api-03). Before this, only Matrix and Polygon had a method, so R's default
# fired for the other 39 classes: it put a dim on the 2-element wrapper list
# (.xptr, .cpp) and kept the S3 class, so is.matrix() said TRUE, no error was
# raised, and printing the result died inside the class's own print(). Every
# object carries class(x) = c("<Class>", "PraatObject"), so one method here
# covers them all; classes with their own method (PraatMatrix, Polygon) still win,
# because S3 dispatches on the first class element.

#' Convert a pladdrr object to a matrix
#'
#' @description
#' Fallback `as.matrix()` method for every pladdrr object class: it returns the
#' numbers of the object's own `$as_matrix()` method (`frame` x `2` for Pitch
#' and the tiers, `frequency` x `time` for Spectrogram and the other 2-D
#' objects, `channel` x `sample` for Sound). Classes without `$as_matrix()`
#' (Formant, PointProcess, TextGrid, Table, ...) raise a `pladdrr_input_error`
#' naming the class and the accessor to use instead; they never silently return
#' a matrix-shaped wrapper. `PraatMatrix` and `Polygon` keep their own methods.
#'
#' @param x A pladdrr object (any class inheriting from \code{PraatObject}).
#' @param ... Passed on to the object's \code{$as_matrix()} method; used by
#'   \code{Spectrogram} (\code{include_dimnames}) and
#'   \code{MelSpectrogram}/\code{BarkSpectrogram} (\code{to_db}).
#' @return A numeric matrix. For classes with no \code{$as_matrix()}, an error
#'   of class \code{pladdrr_input_error} instead, naming whichever of
#'   \code{as.data.frame(x)} and \code{x$as_vector()} that class really offers
#'   (\code{Manipulation} offers neither and is pointed at its own accessors).
#' @seealso \code{\link{PraatMatrix}}, \code{\link{Pitch}},
#'   \code{\link{as.data.frame.Sound}}
#' @examples
#' sound <- Sound$create_tone(frequency = 440, duration = 0.2,
#'   sampling_rate = 16000)
#' m <- as.matrix(sound$to_pitch())
#' dim(m)
#' tryCatch(as.matrix(sound$to_point_process_periodic_cc()),
#'   pladdrr_input_error = function(e) conditionMessage(e))
#' @export
as.matrix.PraatObject <- function(x, ...) {
  as_matrix <- x$as_matrix
  if (!is.function(as_matrix)) {
    cls <- class(x)[1]
    # Offer only the conversions this class actually has. Manipulation has no
    # as.data.frame() method and LongSound's only stops with a redirect, so a
    # blanket "use as.data.frame(x)" sent users into R's own untagged
    # "cannot coerce class" error (fix/013 review).
    alts <- character()
    if (!is.null(utils::getS3method("as.data.frame", cls, optional = TRUE))) {
      alts <- c(alts, "as.data.frame(x)")
    }
    if (is.function(x$as_vector)) alts <- c(alts, "x$as_vector()")
    .stop_input("as.matrix", "x", paste0("class ", cls, " has no ",
      "$as_matrix(); use ",
      if (length(alts)) paste(alts, collapse = " or ") else "its own accessors",
      " instead (see ?", cls, ")"))
  }

  as_matrix(...)
}
