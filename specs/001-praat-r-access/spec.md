# Feature Specification: Praat C Functionality Access from R

**Feature Branch**: `001-praat-r-access`
**Created**: 2025-11-02
**Status**: Draft
**Input**: User description: "Direct access to Praat C functionality from R using Rcpp for phonetic analysis"

## Clarifications

### Session 2025-11-02

- Q: Performance optimization strategy regarding SIMD efficiency gains → A: SIMD is a future optimization consideration, prioritize correctness and Praat compatibility first
- Q: Handling undefined analysis values (pitch in unvoiced segments, formants in silence) → A: Return NA (R's standard missing value)
- Q: Praat source code licensing compliance (GPL-2+) → A: Package is GPL-3 compatible (already stated in README) - no additional action needed
- Q: Analysis quality warnings and logging for potentially poor results → A: Emit R warnings for quality issues, allow users to suppress with standard R mechanisms
- Q: Stereo audio file handling strategy → A: Process only left channel by default, provide channel selection parameter

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Sound Object Operations (Priority: P1)

A phonetics researcher wants to load an audio file, create a sound object, and perform basic operations like extracting duration, sampling rate, and computing simple statistics without needing external Praat software.

**Why this priority**: This is the foundational capability. Without the ability to work with sound objects, no phonetic analysis is possible. This provides immediate value for users who want to integrate Praat functionality into their R workflows.

**Independent Test**: Can be fully tested by loading a WAV file, creating a sound object, querying its properties (duration, sample rate), and computing basic statistics (mean, min, max), then verifying results match expected values.

**Acceptance Scenarios**:

1. **Given** a WAV audio file exists, **When** user loads it into a sound object, **Then** the object contains valid audio data with correct metadata (duration, sampling rate, channels)
2. **Given** a sound object is created, **When** user queries duration, **Then** the duration matches the actual audio length in seconds
3. **Given** a sound object with audio data, **When** user computes basic statistics (mean, min, max, RMS), **Then** statistics are accurate and match manual calculations
4. **Given** a user wants to generate test signals, **When** they request a sine wave of specific frequency and duration, **Then** a sound object is created with mathematically correct waveform

---

### User Story 2 - Pitch Analysis (Priority: P2)

A speech scientist needs to extract pitch contours from speech recordings to analyze intonation patterns, fundamental frequency (F0) over time, and identify pitch characteristics like minimum, maximum, and mean F0.

**Why this priority**: Pitch analysis is one of the most common phonetic analyses. This enables core research use cases for prosody, tone languages, and speaker characteristics without requiring external tools.

**Independent Test**: Can be tested by loading a speech recording, extracting pitch using standard Praat algorithms, and verifying the resulting pitch contour contains expected measurements (F0 values over time, min/max/mean pitch) that match Praat desktop application results.

**Acceptance Scenarios**:

1. **Given** a speech recording, **When** user extracts pitch contour, **Then** a pitch object is created with F0 values at regular time intervals
2. **Given** a pitch object, **When** user queries minimum and maximum pitch, **Then** values match the actual fundamental frequency range
3. **Given** a pitch object, **When** user queries pitch at a specific time point, **Then** the F0 value at that moment is returned with appropriate interpolation
4. **Given** voiced and unvoiced segments, **When** pitch is extracted, **Then** unvoiced segments are correctly identified (no pitch value or undefined)

---

### User Story 3 - Formant Analysis (Priority: P3)

A phonetician wants to measure vowel formants (F1, F2, F3) to study vowel quality, analyze acoustic phonetic properties, and compare formant patterns across speakers or phonetic contexts.

**Why this priority**: Formant analysis is essential for vowel studies and articulatory phonetics research. This completes the core trio of phonetic analyses (sound, pitch, formants) needed for most speech research.

**Independent Test**: Can be tested by loading a vowel recording, extracting formants at specific time points or across time, and verifying formant measurements (F1, F2, F3 frequencies and bandwidths) match Praat's LPC-based formant tracking algorithm results.

**Acceptance Scenarios**:

1. **Given** a speech recording with vowels, **When** user extracts formants, **Then** a formant object is created with F1-F5 values and bandwidths over time
2. **Given** a formant object and a specific time point, **When** user queries formant values, **Then** F1, F2, F3 frequencies are returned with appropriate interpolation
3. **Given** a formant object, **When** user queries formant statistics for a time range, **Then** mean formant values across that range are computed correctly
4. **Given** formant tracking settings (max formant, number of formants), **When** user extracts formants, **Then** the algorithm respects these parameters matching Praat's behavior

---

### User Story 4 - Intensity and Spectral Analysis (Priority: P4)

A researcher needs to measure sound intensity (loudness) over time and perform spectral analysis to study energy distribution across frequencies for applications like stress detection or spectral moment analysis.

**Why this priority**: While important, intensity and spectral analysis are less frequently the primary analysis target compared to pitch and formants. This extends the package's capabilities for specialized research needs.

**Independent Test**: Can be tested by loading audio, computing intensity contour and spectrogram, and verifying intensity values (dB) at time points and spectral characteristics match Praat's calculations.

**Acceptance Scenarios**:

1. **Given** a sound object, **When** user computes intensity, **Then** an intensity object with dB values over time is created
2. **Given** an intensity object, **When** user queries intensity at a specific time, **Then** the dB value at that moment is returned
3. **Given** a sound object, **When** user creates a spectrogram, **Then** a spectrogram object is created with time-frequency-amplitude representation
4. **Given** a spectrogram, **When** user queries power at specific time and frequency, **Then** spectral power value is returned matching Praat's FFT-based calculations

---

### Edge Cases

- What happens when an audio file is corrupted or has an unsupported format?
- How does the system handle extremely short audio files (< 0.1 seconds) where some analyses may be unreliable?
- Pitch tracking failures (whispered speech, very noisy audio) or poor quality results emit R warnings; analysis completes with available data
- Missing or undefined values (e.g., pitch in unvoiced segments, formants in silence) are represented as NA (R's standard missing value)
- Formant tracking divergence or implausible results trigger quality warnings; results returned with warning message
- How does the system handle very long audio files (> 1 hour) regarding memory usage?
- What happens when sampling rates are non-standard (not 16kHz, 22kHz, 44.1kHz, etc.)?
- Multi-channel (stereo) audio files process left channel by default; channel selection parameter allows choosing specific channel

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package MUST provide functions to create sound objects from numeric vectors and audio files; multi-channel files default to left channel with optional channel selection parameter
- **FR-002**: Package MUST provide functions to query sound object properties (duration, sampling rate, number of channels, number of samples)
- **FR-003**: Package MUST provide functions to generate test signals (sine waves, noise) with specified parameters
- **FR-004**: Package MUST provide functions to compute basic audio statistics (mean, minimum, maximum, RMS, intensity)
- **FR-005**: Package MUST provide functions to extract pitch (F0) contours from sound objects using Praat's autocorrelation method
- **FR-006**: Package MUST provide functions to query pitch measurements (minimum, maximum, mean pitch, pitch at time points)
- **FR-007**: Package MUST provide functions to extract formants using Praat's LPC analysis
- **FR-008**: Package MUST provide functions to query formant values (F1-F5 frequencies and bandwidths at time points or ranges)
- **FR-009**: Package MUST provide functions to compute intensity contours
- **FR-010**: Package MUST provide functions to create and query spectrograms
- **FR-011**: Package MUST handle errors gracefully with informative error messages when operations fail
- **FR-012**: All analysis results MUST match Praat desktop application output within acceptable numerical precision (< 0.1% relative error for most measurements)
- **FR-013**: Package MUST provide print methods for all Praat object types (sound, pitch, formant, intensity, spectrogram)
- **FR-014**: Package MUST document all exported functions with roxygen2 including parameters, return values, and working examples
- **FR-015**: Package MUST validate input parameters (e.g., frequency ranges, time points) and provide clear error messages for invalid inputs
- **FR-016**: Package MUST return NA (R's standard missing value) for undefined or unmeasurable analysis results (pitch in unvoiced segments, formants in silence)
- **FR-017**: Package MUST emit R warnings when analysis completes but with potentially poor quality (few pitch frames detected, unstable formant tracking, etc.), allowing users to suppress warnings via standard R mechanisms

### Key Entities

- **Sound Object**: Represents digitized audio data with attributes including sample values, sampling frequency, start time, duration, and number of channels. Created from files, numeric vectors, or generated signals.

- **Pitch Object**: Represents fundamental frequency (F0) measurements over time with attributes including F0 values at regular intervals, voicing decisions (voiced/unvoiced), pitch floor/ceiling, and time step. Created by analyzing sound objects.

- **Formant Object**: Represents formant frequencies and bandwidths over time with attributes including F1-F5 values, bandwidths, number of formants tracked, maximum formant frequency setting, and time step. Created by LPC analysis of sound objects.

- **Intensity Object**: Represents sound intensity (loudness) in dB over time with attributes including intensity values at regular intervals, minimum pitch used for computation, and time step. Created from sound objects.

- **Spectrogram Object**: Represents time-frequency-amplitude representation of sound with attributes including time step, frequency step, window length, dynamic range, and pre-emphasis. Created from sound objects using FFT analysis.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Researchers can load an audio file and extract basic properties in under 10 seconds for typical recordings (< 5 minutes)
- **SC-002**: All phonetic measurements (pitch, formants, intensity) match Praat desktop application results within 0.1% relative error for at least 95% of test cases
- **SC-003**: Users can complete a basic pitch analysis workflow (load file → extract pitch → query statistics → plot results) in under 5 minutes including plotting
- **SC-004**: Package passes R CMD check with zero errors, warnings, or notes demonstrating compliance with CRAN standards
- **SC-005**: Memory usage remains under 500 MB for audio files up to 10 minutes at 44.1 kHz sampling rate
- **SC-006**: All exported functions have complete documentation with at least one working example that executes successfully
- **SC-007**: Test coverage exceeds 80% for R code and 70% for C++ code as measured by standard coverage tools
- **SC-008**: Package can process audio files at least 10x faster than calling external Praat scripts due to direct C integration

## Assumptions

- Users have basic familiarity with R and phonetic concepts (F0, formants, spectrograms)
- Audio files are primarily mono (single channel); stereo files are supported by processing left channel by default with optional channel selection
- Standard sampling rates (8kHz to 48kHz) are used; exotic sampling rates may require special handling
- Praat C source code is available and compatible with Rcpp integration
- Users will primarily work with WAV format audio files; other formats can be supported via additional packages
- Computational precision matches Praat's algorithms, accepting minor floating-point differences across platforms
- Installation requires a C++ compiler compatible with Rcpp (Rtools on Windows, Xcode on macOS, g++ on Linux)
- Performance optimization (SIMD, vectorization) is deferred until correctness and Praat compatibility are validated
- Package licensing is GPL-3, which is compatible with Praat's GPL-2+ license for included C source code

