---
title: 'pladdrr: Direct access to the core algorithms of Praat from R'
tags:
  - R
  - C++
  - phonetics
  - speech analysis
  - acoustics
  - voice quality
  - Praat
authors:
  - name: Fredrik Nylén
    orcid: 0000-0003-3373-0934
    affiliation: 1
    corresponding: true
  - name: Tomas Skotare
    orcid: 0000-0001-8445-0559
    affiliation: 2
  - name: Johan von Boer
    affiliation: 2
affiliations:
  - name: Speech and Language Therapy, Department of Clinical Sciences, Faculty of Medicine, Umeå University, Sweden
    index: 1
    ror: 05kb8h459
  - name: Humlab, Faculty of Arts, Umeå University, Sweden
    index: 2
    ror: 05kb8h459
date: 9 September 2026
bibliography: paper.bib
---

# Summary

Praat [@boersma2024praat] has developed into a strong contender to being the 
de facto standard platform for pitch and formant tracking, spectrography, and voice-quality
measurement, and Praat also has some fascilities for parametric speech synthesis. 
Its algorithms are implemented in
C++ and are normally reachable only through Praat's own GUI or its scripting
language, which makes the incorporation of the phonetic analyses inside a
reproducible statistical workflow fragile and inefficient.

Th R package `pladdrr` exposes 38 of the Praat's core analysis 
object classes ( in particular, the `Sound`, `Pitch`,
`Formant`, `FormantPath`, `Spectrum`, `Spectrogram`, `Harmonicity`,
`PowerCepstrogram`, `MFCC`, `TextGrid`, `KlattGrid`, `DTW`, `PCA`,
`Discriminant`, and `Polygon` objects) as R objects with over 500 methods, via
Rcpp modules [@eddelbuettel2011rcpp]. Praat objects live in C++ memory for
their whole lifetime, negating the requirement to interact with the Praat digital speech processing (DSP) using metaprogramming techniques and inter process communication via the shell or by other means.
A persistent Praat script interpreter
is also exposed, so existing Praat scripts can be executed and their results
handed back to R as native objects, which gives users an incremental migration
path rather than an all-or-nothing rewrite.

The package's central design commitment is faithfullness to the output of Praat, with processing 
speed being the secondary design goal. Great care has therefore been put into ensuring that the 
results are directly comparable with the published phonetic literature that used Praat.

# Statement of need

Speech scientists, phoneticians, and clinical voice researchers routinely
analyse acoustic data in Praat and then analyse the resulting measurements
statistically in R. The usual bridge between the two is fragile: a Praat script
writes CSV files, R reads them back, and the analysis is split across two
languages, two file formats, and two execution environments. This breaks
reproducibility, as the Praat version and script are rarely captured alongside the
R code. Further, it presents a barrier to diagnosing faults as there is not 
a fully developed developmental toolchain for Praat script development, and it makes per-file process launches the
dominant cost in corpus-scale studies.

The `pladdrr` R package bridges the gap between the DSP abilities of Praat and the more mature 
toolchain of R by allowing analysis code to run in the same
process as the statistical code. Thus, a complete phonetic investigation of a 
collected speech material can be captured as a single R script
or R Markdown document. This matters most for complex workloads such as the computatation of clinical
voice-quality indices such as the Acoustic Voice Quality Index
[@maryn2010avqi] and the Dysphonia Severity Index [@wuyts2000dsi], which
combine several Praat analyses (cepstral peak prominence, harmonics-to-noise
ratio, long-term average spectrum slope, shimmer, jitter, maximum phonation
frequency) into one score and is also based on two or more sound files that require appropriate attention in their
management when applied across large corpora. 

The final need met by the `pladdrr`  package is support for more sound file formats than what is currently
available in Praat. While Praat support the dominant phonetically safe sound file format, in lossless encodings, 
and some formats that discards acoustic information (MP3 and OGG), it was seen as desirable in the development of `pladdrr` 
to ensure a more general media loading structure to be used, to support a large variety of audio input formats, including sound tracks bundled inside of a container in a video file. 

# State of the field

Several R packages already touch Praat. `PraatR` [@albin2014praatr] and
`speakr` drive an installed Praat binary through system calls, so each
measurement costs a process launch and the results arrive as text.
`rPraat` [@boril2016rpraat] parses and writes Praat file formats
(TextGrid, PitchTier, Formant) but does not implement or call Praat's
analysis algorithms. The EMU-SDMS ecosystem [@winkelmann2017emu] provides
`wrassp`, a native signal-processing library, but its algorithms are
independently implmented algorithms that overlap in part with Praats DSP procedures in aims, 
but are very likelly to produce results that are different from that of Praat. In Python, `parselmouth`
[@jadoul2018parselmouth] takes the approach closest to `pladdrr`, embedding
Praat's C++ code directly. The new R package  `pladdrr` cannot fully take the same approach due to
bundle size expecations of the CRAN public repository for R packages, 

# Implementation

Wrapper objects are plain R lists holding an external pointer, dispatching
through a class-specific `$` S3 method into a single shared method environment
per class. The stateful Praat script interpreter is the one component modelled
as an R6 class [@chang2021r6]. The graphical user interface, audio playback, visual editors, 
and the ability to send commands to the shell are components of Praat 
that have been excluded from the library to reduce bundle size.

The implementation is structured into multiple tiers, to provide broad accessability
of the package, depending on the user's specific needs:

1. A Praat object based interface that provides transparent access that closely mimics how 
  objects are accessed and used in the Praat programming language, and with transparent 
  handoff to R objects.
2. A direct API with functions that take and returns external pointers, and that bypasses
   wrapper construction inside important, tight, loops.
3. Prepared batch operations many queries resolved in a single C++ call, aimed at minimizing 
   R to C++ transition of data when the same procedure is applied to many input signals.
4. Entire key pipelines involving many Praat objects that have fully been implmented inside of C++
  for efficient processing without transfer of data between R and C++. 

Selected inner loops have been made multi-threaded (cepstrogram computation, harmonicity)
and some kernels have SIMD paths, both gated on producing output identical to
the scalar reference.

# Development history

Package development started in 2025 with the initial implementation strategy being
to provide a thin Rcpp translation layer for exposing key Praat objects to R as S3 and later R7 objects. The translation layer
was observed to introduce a considerable bottleneck in performance when the implmentation reached the maturity and breath that was sufficient to start re-implementing simple Praat code using `pladdrr` and compare them in terms of  
performance and analysis output. The performance penalty and cumbersome development of the 
chosen strategy resulted in a strategy shift in early 2026 to the use of Rcpp modules to expose 
Praat classes, with S3 method dispatch. The strategy shift resulted in a 
rapid expansion to 38 Praat modules that is currently in the package in version 5.0.5, with the 
only remaining R6 class being the exposure of the Praat interpreter that require a persistant state across 
method calls.

Further development was guided by an informal analysis of Praat scripts available 
on github of sufficient complexity for them to be associated with a research publication. 
Often used patterns in Praat code were extracted, and from version 4.0.0, Praat object 
exposure to the package was expanded in parallell with an associated C++ level 
implmentation batching patterns (Tier 3 implmentations) and of the identified common
instances where two or more praat objects are used together to perform the analysis (Tier 4), 
which was given fast implmentations in C++ code to reduce object conversion in intermediate steps.
In parallel, a shared method environment was introduced, decreasing object construction speed to approximately 1/9th 
of the previous closure based implementation for Praat objects of the size often encountered, and reduced per-object memory roughly 160-fold, at the cost of
a small per-call dispatch overhead that would only come into play in situations with repeated creation of small objects, with was reasoned to not occur often in digital speech proceeding workflows.

In addition to the change in focus to Rcpp modules, a second pivot in the developmental direction
was spurred by the effort to utilize SIMD optimization to improve performance. 
Two separate SIMD optimisations were withdrawn after emitical evaluation. First, the 
`Sound` power, RMS, and energy measurement was found to not retain fidelity to the output 
of Praat with SIMD optimized, and was therefore reverted. Second, a repeated-median trend 
fit [@siegel1982robust] SIMD optimization in the cepstral peak prominence pipeline was
discarded due to benchmarking showing a 1.7–2.4× decrease in performance compared to the 
scalar based computation it replaced when the Xsimd library was avaliable. 

These episodes hardened into three house rules that the codebase now follows:
parity with Praat outranks speed wherever the two conflict; performance claims
are re-measured before they are trusted or published; and the API grows by
adding narrower tiers rather than by compromising a single interface.

# Quality control

Version 5.0.5 of the package has 1401 tests and currently an 82% test coverage. Continiuos integration 
ensure successful package checks including testing on on Linux, macOS, and Windows, 
and the package is also checked using a linter (`lintr`) and the rOpenSci `pkgcheck` on each commit.
Core principles guiding package development include faithfulness tests of re-implmentations of Praat code using the interface exposed by `pladdrr`. 

# Acknowledgements

The `pladdrr` package builds upon the Praat source code by Paul Boersma and
David Weenink, without which the package would not exist. It also uses 
pocketfft (Max-Planck-Society) and the Xiph.Org Vorbis, Ogg, and Opusfile
sources, and links against the GNU Scientific Library to provide the exposed functionality of Praat.

# References
