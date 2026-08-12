# rOpenSci pre-submission enquiry — draft

Post as a new issue in [ropensci/software-review](https://github.com/ropensci/software-review/issues/new/choose),
using the "Pre-submission Enquiry" template.

---

**Package name**: pladdrr

**One-line description**: Direct access to the core algorithms of Praat (the
open-source phonetics software) from R, via Rcpp bindings to Praat's C/C++
sources.

**Description**: pladdrr wraps Praat's C++ implementation (from
`praat.github.io`, upstream: Boersma & Weenink) with R6 classes, exposing 38
Praat modules / 500+ methods for sound manipulation, formant tracking
(FormantPath, FormantModeler), speech synthesis (KlattGrid), pitch/intensity
analysis, spectral analysis (ComplexSpectrogram), cepstral coefficients
(MFCC/LFCC, incl. CPPS/AVQI voice-quality measures), statistical analysis
(PCA, Discriminant), auditory modeling (Cochleagram, Excitation), TextGrid
annotation, and a persistent Praat script interpreter with bidirectional
R–Praat object transfer.

Praat itself has no R interface beyond shelling out to the Praat binary and
scraping text output (the approach taken by existing packages like `PraatR`
and Python's `parselmouth`). pladdrr instead compiles Praat's C++ sources
directly into the R package via Rcpp, giving in-process, typed access to the
underlying objects rather than a script/subprocess boundary.

**Would this fit under one of these existing categories?**

Closest fit: rOpenSci's "Statistical Software" / general scientific-software
review, though pladdrr is a *binding to external, non-R scientific software*
(Praat) rather than a from-scratch statistical method. The closest precedent
package families are audio/bioacoustics or NLP wrapper packages already in
the rOpenSci review scope (e.g. `warbleR`-adjacent phonetics tooling).

**Who is the target audience?** Phoneticians, speech scientists, and
linguists who currently do Praat analysis by hand in the Praat GUI, via
Praat scripting, or via subprocess-based R/Python wrappers, and who want
programmatic, scriptable, in-process access to Praat's algorithms for
reproducible pipelines (batch voice-quality metrics, corpus-scale formant
extraction, etc.).

**Are there other R packages that accomplish the same thing?**
`PraatR` (shells out to Praat binary, writes/reads text files),
`rPraat` (reads/writes Praat file formats, no analysis),
`nasal.detect`/other narrow single-purpose wrappers. None compile Praat's
own C++ sources — pladdrr is the only in-process binding.

**Explicit question for the editors**: pladdrr bundles and compiles a
substantial third-party C++ codebase (Praat) rather than reimplementing
algorithms in R/C++ from scratch. Does this fit rOpenSci's scope, or does it
fall closer to "porting/wrapping existing software" that's out of scope? If
in scope, which category (stats software / community peer review) is the
right review track?

---

## Notes for Fredrik before posting

- Confirm GPL-3 compatibility is stated correctly (Praat is GPL-2+; check
  the `LICENSE` / `LICENSE.note` → `inst/COPYRIGHTS` chain matches).
- Link to the GitHub repo URL once you paste this in.
- This is a genuine scope question — the plan flags that if the answer is
  no, Phases 6–8 (code quality polish, submission) are wasted effort. Worth
  sending before investing further time.
