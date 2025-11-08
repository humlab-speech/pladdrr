# speaker 0.1.0 (Development)

## Initial Development

This is the initial development version of the speaker package.

### Planned Features

* **Sound Object Operations**: Load audio files, create sound objects, query properties, compute statistics
* **Pitch Analysis**: Extract F0 contours, query pitch measurements (min, max, mean)
* **Formant Analysis**: Extract formants (F1-F5), query formant values and statistics
* **Intensity Analysis**: Compute intensity contours, measure loudness
* **Spectral Analysis**: Create spectrograms, query spectral power

### Development Status

- [x] Project structure initialized
- [x] Package metadata configured (DESCRIPTION, LICENSE, NEWS)
- [ ] Praat C source integration
- [ ] Rcpp wrapper implementation
- [ ] R function implementation
- [ ] Test suite with TDD
- [ ] Documentation and vignettes
- [ ] CRAN submission preparation

### Notes

This package provides direct access to Praat C functionality via Rcpp, enabling
phonetic analysis directly in R without external Praat software.

For detailed progress, see `specs/001-praat-r-access/tasks.md`.
