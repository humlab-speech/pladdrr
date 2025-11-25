\name{pladdrr-package}
\alias{pladdrr-package}
\alias{pladdrr}
\docType{package}
\title{
  Object-Oriented Interface to Praat Phonetic Analysis
}
\description{
  Provides direct, efficient access to Praat C implemented functionality from R 
  using Rcpp and R6 object-oriented design. Similar in concept to the Parselmouth 
  package for Python, this package allows R users to leverage Praat's powerful 
  phonetic analysis capabilities directly from R.
  
  Features include 17+ Praat object types with 300+ methods for sound manipulation, 
  pitch analysis, formant extraction, intensity measurements, spectral analysis, 
  TextGrid annotation, and voice quality assessment. The package includes SIMD 
  optimization for 2-4x performance improvements on modern CPUs.
}
\details{
  \tabular{ll}{
    Package: \tab pladdrr\cr
    Type: \tab Package\cr
    Version: \tab 0.9.9\cr
    Date: \tab 2025-11-22\cr
    License: \tab GPL-3\cr
  }
  
  \strong{Core Analysis Objects:}
  \itemize{
    \item \code{\link{Sound}} - Audio I/O, manipulation, filtering
    \item \code{\link{Pitch}} - F0 extraction and analysis
    \item \code{\link{Formant}} - Formant tracking and queries
    \item \code{\link{Intensity}} - Intensity contours
    \item \code{\link{Harmonicity}} - Voice quality (HNR)
  }
  
  \strong{Spectral Analysis:}
  \itemize{
    \item \code{\link{Spectrogram}} - Time-frequency representation
    \item \code{\link{Spectrum}} - Frequency-domain analysis
    \item \code{\link{Ltas}} - Long-term average spectrum
  }
  
  \strong{Manipulation & Tiers:}
  \itemize{
    \item \code{\link{Manipulation}} - PSOLA pitch/duration modification
    \item \code{\link{PitchTier}} - Pitch contour editing
    \item \code{\link{IntensityTier}} - Intensity modification
    \item \code{\link{DurationTier}} - Duration control
  }
  
  \strong{Annotation & Data:}
  \itemize{
    \item \code{\link{TextGrid}} - Annotation and segmentation
    \item \code{\link{PointProcess}} - Time points (glottal pulses)
    \item \code{\link{Matrix}} - 2D numerical arrays
    \item \code{\link{Table}} - Tabular data structures
  }
  
  \strong{Performance Features:}
  \itemize{
    \item SIMD acceleration (2-4x speedup on modern CPUs)
    \item Zero-copy operations via external pointers
    \item Automatic CPU detection (ARM NEON, AVX2, SSE2)
    \item Efficient large file handling
  }
}
\author{
  Fredrik Nylén <fredrik.nylen@umu.se>
  
  Maintainer: Fredrik Nylén <fredrik.nylen@umu.se>
}
\references{
  Boersma, P., & Weenink, D. (2023). Praat: doing phonetics by computer 
  [Computer program]. Version 6.3, retrieved from \url{https://www.praat.org/}
}
\seealso{
  \code{\link{Sound}}, \code{\link{Pitch}}, \code{\link{Formant}}, 
  \code{\link{TextGrid}}
}
\examples{
# Create a pure tone
sound <- Sound$create_tone(440, duration = 1.0, sampling_frequency = 44100)

# Extract pitch
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Extract formants
formant <- sound$to_formant_burg(
  time_step = 0.01,
  max_number_of_formants = 5,
  maximum_formant = 5500
)

# Get formant values at midpoint
f1 <- formant$get_value_at_time(1, 0.5, "hertz")
f2 <- formant$get_value_at_time(2, 0.5, "hertz")
}
\keyword{package}
