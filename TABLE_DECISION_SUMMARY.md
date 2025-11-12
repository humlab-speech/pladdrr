# Table Decision Summary

## Decision (2025-11-12)

Table object implementation **DEFERRED** to Interpreter Integration Phase.

## Rationale

1. Table's primary feature (formula evaluation) requires Praat Interpreter
2. Without interpreter, R's data.frame is superior for all use cases
3. Direct Object → data.frame conversions are more efficient
4. Avoids creating unnecessary intermediate Table objects

## Action

Implement  methods for all analysis objects:
- Formant, Pitch, Intensity, Harmonicity
- PitchTier, IntensityTier, DurationTier
- PointProcess, Matrix

## Next Steps

Proceed with Formant and Matrix object implementations as planned.

See TABLE_IMPLEMENTATION_ASSESSMENT.md and CLAUDE.md for full analysis.

