#' Primary references for the algorithms in pladdrr
#'
#' pladdrr does not implement new methods: it compiles Praat's own C/C++
#' routines and returns what the Praat application returns. The methods below
#' are the published sources those routines are based on, grouped by what you
#' call in pladdrr. Praat's own documentation (\url{https://www.fon.hum.uva.nl/praat/manual/})
#' describes the exact variant each command uses, and states where Praat departs
#' from the paper. Where a pladdrr result is checked against the Praat
#' application, the check is in \code{tests/testthat/test-praat-faithfulness.R}.
#'
#' @section Software:
#' \itemize{
#'   \item Boersma, P. & Weenink, D. Praat: doing phonetics by computer.
#'     \url{https://praat.org/}. Cite the Praat version bundled with the
#'     package (see \code{citation("pladdrr")}).
#' }
#'
#' @section Pitch (\code{to_pitch_ac}, \code{to_pitch_cc}, \code{to_pitch_shs}) and harmonicity (\code{to_harmonicity_ac}, \code{to_harmonicity_cc}):
#' \itemize{
#'   \item Boersma, P. (1993). Accurate short-term analysis of the fundamental
#'     frequency and the harmonics-to-noise ratio of a sampled sound.
#'     \emph{Proceedings of the Institute of Phonetic Sciences, University of
#'     Amsterdam}, 17, 97-110. (autocorrelation and cross-correlation pitch,
#'     harmonics-to-noise ratio)
#'   \item Hermes, D. J. (1988). Measurement of pitch by subharmonic summation.
#'     \emph{Journal of the Acoustical Society of America}, 83(1), 257-264.
#'     \doi{10.1121/1.396427} (\code{to_pitch_shs})
#' }
#'
#' @section Formants (\code{to_formant_burg}, \code{to_lpc_burg}):
#' \itemize{
#'   \item Burg, J. P. (1975). \emph{Maximum entropy spectral analysis}. PhD
#'     thesis, Stanford University. (Burg's linear-prediction algorithm)
#' }
#'
#' @section Cepstral peak prominence and voice-quality indices (\code{get_cpps}, \code{calculate_cpps_ultra}, \code{get_cpps_fast}):
#' \itemize{
#'   \item Hillenbrand, J., Cleveland, R. A. & Erickson, R. L. (1994). Acoustic
#'     correlates of breathy vocal quality. \emph{Journal of Speech and Hearing
#'     Research}, 37(4), 769-778. \doi{10.1044/jshr.3704.769}
#'   \item Hillenbrand, J. & Houde, R. A. (1996). Acoustic correlates of breathy
#'     vocal quality: dysphonic voices and continuous speech. \emph{Journal of
#'     Speech and Hearing Research}, 39(2), 311-321. \doi{10.1044/jshr.3902.311}
#'   \item Maryn, Y., Corthals, P., Van Cauwenberge, P., Roy, N. & De Bodt, M. (2010). Toward improved ecological
#'     validity in the acoustic measurement of overall voice quality: combining
#'     continuous speech and sustained vowels. \emph{Journal of Voice}, 24(5),
#'     540-555. \doi{10.1016/j.jvoice.2008.12.014} (AVQI)
#'   \item Maryn, Y. & Weenink, D. (2015). Objective dysphonia measures in the
#'     program Praat: smoothed cepstral peak prominence and acoustic voice
#'     quality index. \emph{Journal of Voice}, 29(1), 35-43.
#'     \doi{10.1016/j.jvoice.2014.06.015} (the Praat implementation of both)
#'   \item Siegel, A. F. (1982). Robust regression using repeated medians.
#'     \emph{Biometrika}, 69(1), 242-244. \doi{10.1093/biomet/69.1.242} (the
#'     default robust trend fit for CPPS)
#' }
#'
#' @section Cepstral coefficients (\code{to_mfcc}):
#' \itemize{
#'   \item Davis, S. B. & Mermelstein, P. (1980). Comparison of parametric
#'     representations for monosyllabic word recognition in continuously spoken
#'     sentences. \emph{IEEE Transactions on Acoustics, Speech, and Signal
#'     Processing}, 28(4), 357-366. \doi{10.1109/TASSP.1980.1163420}
#' }
#'
#' @section Speech synthesis (KlattGrid):
#' \itemize{
#'   \item Klatt, D. H. (1980). Software for a cascade/parallel formant
#'     synthesizer. \emph{Journal of the Acoustical Society of America}, 67(3),
#'     971-995. \doi{10.1121/1.383940}
#'   \item Klatt, D. H. & Klatt, L. C. (1990). Analysis, synthesis, and
#'     perception of voice quality variations among female and male talkers.
#'     \emph{Journal of the Acoustical Society of America}, 87(2), 820-857.
#'     \doi{10.1121/1.398894}
#' }
#'
#' @section Dynamic time warping (DTW):
#' \itemize{
#'   \item Sakoe, H. & Chiba, S. (1978). Dynamic programming algorithm
#'     optimization for spoken word recognition. \emph{IEEE Transactions on
#'     Acoustics, Speech, and Signal Processing}, 26(1), 43-49.
#'     \doi{10.1109/TASSP.1978.1163055}
#' }
#'
#' @section Other modules:
#' Jitter, shimmer, intensity, LTAS, spectrograms, PCA, discriminant analysis,
#' the Cochleagram and Excitation auditory models and the remaining classes
#' follow the definitions in Praat's manual rather than a single primary
#' paper; \code{vignette("terminology")} states the definition each result uses.
#'
#' @return No return value; this page only documents the references.
#' @examples
#' # Open the reference list from within R
#' help("pladdrr-references", package = "pladdrr")
#'
#' @name pladdrr-references
#' @aliases pladdrr_references
#' @seealso \code{\link{pladdrr-package}}
#' @keywords documentation
NULL

#' @srrstats {G1.0} Primary references for each algorithm family, with DOIs checked against Crossref, are in `R/pladdrr-references.R` (`?pladdrr-references`), linked from `?pladdrr`.
#'
#' @noRd
NULL
