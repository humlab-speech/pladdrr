# KlattGrid Usage Guide

**Module**: Phase 2.3 - Speech Synthesis  
**Status**: 90% functional  
**Version**: 1.9.3

---

## Quick Start

### ✅ RECOMMENDED: Use Pre-configured Helpers

```r
library(pladdrr)

# Synthesize /a/ vowel (works perfectly)
kg <- KlattGrid_createFromVowel(
  duration = 0.5,
  f0start = 120,           # Pitch in Hz
  f1 = 800, b1 = 80,       # F1 formant + bandwidth
  f2 = 1200, b2 = 120,     # F2 formant + bandwidth
  f3 = 2500, b3 = 150      # F3 formant + bandwidth
)

# Synthesize sound
sound <- kg$to_sound()
sound$save("vowel_a.wav", "WAV")
```

### ✅ Use Example Grid

```r
# Pre-configured example with complex synthesis
kg_ex <- KlattGrid_createExample()
sound_ex <- kg_ex$to_sound()
```

---

## ⚠️ AVOID: Empty Grid Manual Initialization

```r
# ❌ THIS WILL SEGFAULT
kg <- KlattGrid(tmin = 0, tmax = 1, numberOfFormants = 5)
kg$add_pitch_point(0.5, 100)
sound <- kg$to_sound()  # CRASH - needs more initialization
```

**Why?** Empty `KlattGrid()` requires complete initialization of:
1. **Pitch tier** (fundamental frequency)
2. **Voicing amplitude tier** (phonation)
3. **Formant frequency tiers** (F1, F2, F3, ...)
4. **Formant bandwidth tiers** (B1, B2, B3, ...)

Missing any of these causes segfault during synthesis.

---

## Vowel Synthesis Examples

### Standard Vowels

```r
# /i/ - high front vowel
kg_i <- KlattGrid_createFromVowel(
  duration = 0.3, f0start = 200,
  f1 = 280, b1 = 50,
  f2 = 2250, b2 = 100,
  f3 = 2890, b3 = 120
)

# /a/ - low central vowel
kg_a <- KlattGrid_createFromVowel(
  duration = 0.3, f0start = 200,
  f1 = 730, b1 = 80,
  f2 = 1090, b2 = 120,
  f3 = 2440, b3 = 140
)

# /u/ - high back vowel
kg_u <- KlattGrid_createFromVowel(
  duration = 0.3, f0start = 200,
  f1 = 310, b1 = 60,
  f2 = 870, b2 = 90,
  f3 = 2250, b3 = 140
)

# Synthesize all
sound_i <- kg_i$to_sound()
sound_a <- kg_a$to_sound()
sound_u <- kg_u$to_sound()
```

### Voice Types

```r
# Male voice (low pitch, lower formants)
kg_male <- KlattGrid_createFromVowel(
  duration = 0.5, f0start = 100,
  f1 = 750, b1 = 80,
  f2 = 1100, b2 = 120,
  f3 = 2400, b3 = 150
)

# Female voice (higher pitch, higher formants)
kg_female <- KlattGrid_createFromVowel(
  duration = 0.5, f0start = 220,
  f1 = 850, b1 = 70,
  f2 = 1300, b2 = 110,
  f3 = 2800, b3 = 140
)

# Child voice (very high pitch)
kg_child <- KlattGrid_createFromVowel(
  duration = 0.4, f0start = 300,
  f1 = 900, b1 = 60,
  f2 = 1400, b2 = 100,
  f3 = 3000, b3 = 130
)
```

---

## Pitch Contour Manipulation

```r
# Start with base vowel
kg <- KlattGrid_createFromVowel(
  duration = 0.6, f0start = 120,
  f1 = 500, b1 = 50,
  f2 = 1500, b2 = 100,
  f3 = 2500, b3 = 150
)

# Add pitch points for rising intonation
kg$add_pitch_point(0.2, 110)  # Slight dip
kg$add_pitch_point(0.4, 105)  # Lower
kg$add_pitch_point(0.6, 150)  # Rise (question)

sound <- kg$to_sound()
```

**Available pitch contours:**
- **Flat**: No additional points
- **Rising**: End point > start
- **Falling**: End point < start
- **Question**: Dip then rise (H-L-H pattern)
- **Statement**: Rise then fall (L-H-L pattern)

---

## Formant Transitions (Diphthongs)

```r
# /ai/ diphthong: /a/ → /i/
kg <- KlattGrid_createFromVowel(
  duration = 0.5, f0start = 150,
  f1 = 730, b1 = 80,      # Start: /a/
  f2 = 1090, b2 = 120,
  f3 = 2440, b3 = 140
)

# Transition to /i/ at end
kg$add_formant_frequency_point(1, 0.5, 280)   # F1 rises
kg$add_formant_frequency_point(2, 0.5, 2250)  # F2 rises
kg$add_formant_frequency_point(3, 0.5, 2890)  # F3 rises

sound <- kg$to_sound()
```

---

## Analysis → Synthesis Workflow

```r
# 1. Analyze real speech
sound_orig <- Sound("speech.wav")
fp <- sound_orig$to_formant_path(num_steps_up_down = 2L)
formant <- fp$extract_formant()

# 2. Extract mean formant values
df <- as.data.frame(formant)
f1_mean <- mean(df[df$formant == 1, "frequency"], na.rm = TRUE)
f2_mean <- mean(df[df$formant == 2, "frequency"], na.rm = TRUE)
f3_mean <- mean(df[df$formant == 3, "frequency"], na.rm = TRUE)

# 3. Resynthesize with extracted formants
kg <- KlattGrid_createFromVowel(
  duration = min(sound_orig$get_duration(), 1.0),
  f0start = 120,  # Or extract from pitch
  f1 = f1_mean, b1 = 80,
  f2 = f2_mean, b2 = 120,
  f3 = f3_mean, b3 = 150
)

sound_resynth <- kg$to_sound()
```

---

## File I/O

```r
# Save KlattGrid parameters
kg$save("vowel.KlattGrid")

# Save synthesized sound
sound <- kg$to_sound()
sound$save("vowel.wav", "WAV")
```

---

## Available Methods

### Creation
- `KlattGrid_createFromVowel(duration, f0start, f1, b1, f2, b2, f3, b3)` - **Recommended**
- `KlattGrid_createExample()` - Complex pre-configured example
- `KlattGrid(tmin, tmax, numberOfFormants)` - **Avoid (see warning above)**

### Query
- `kg$is_valid()` - Check if grid is valid
- `kg$get_xmin()`, `kg$get_xmax()` - Time bounds
- `kg$get_duration()` - Duration in seconds

### Synthesis
- `kg$to_sound()` - Full synthesis (all tiers)
- `kg$to_sound_phonation()` - Phonation only

### Manipulation
- `kg$add_pitch_point(time, frequency)` - Add pitch point
- `kg$add_voicing_amplitude_point(time, amplitude)` - Add voicing
- `kg$add_formant_frequency_point(formant_num, time, freq)` - Add formant frequency ⚠️ *Untested*
- `kg$add_formant_bandwidth_point(formant_num, time, bw)` - Add formant bandwidth ⚠️ *Untested*

### File I/O
- `kg$save(filename)` - Save to `.KlattGrid` file
- `kg$print()` - Print summary

---

## Known Limitations

1. **Empty grid synthesis fails**
   - **Workaround**: Always use `KlattGrid_createFromVowel()` or `KlattGrid_createExample()`
   - **Future**: Add `KlattGrid_setDefaults()` helper

2. **Formant manipulation methods untested**
   - `add_formant_frequency_point()` and `add_formant_bandwidth_point()` may not work
   - **Workaround**: Create new grid with desired formants instead of modifying

3. **No formant amplitude control**
   - Only frequency and bandwidth can be set
   - Amplitude relative to voicing is automatic

4. **Limited tier access**
   - Cannot query tier contents
   - Cannot remove points
   - One-way: set parameters → synthesize

---

## Typical Formant Values

### Vowels (Adult Male, ~120 Hz pitch)
| Vowel | F1 (Hz) | F2 (Hz) | F3 (Hz) | Description |
|-------|---------|---------|---------|-------------|
| /i/   | 280     | 2250    | 2890    | High front  |
| /ɪ/   | 400     | 2000    | 2550    | Near-high front |
| /e/   | 550     | 1770    | 2490    | Mid front   |
| /ɛ/   | 660     | 1720    | 2410    | Low-mid front |
| /æ/   | 860     | 1760    | 2390    | Near-low front |
| /a/   | 730     | 1090    | 2440    | Low central |
| /ɑ/   | 710     | 1100    | 2540    | Low back    |
| /ɔ/   | 570     | 840     | 2410    | Low-mid back |
| /o/   | 500     | 700     | 2410    | Mid back    |
| /ʊ/   | 440     | 1020    | 2240    | Near-high back |
| /u/   | 310     | 870     | 2250    | High back   |

### Bandwidths (Typical)
- B1: 50-100 Hz
- B2: 100-150 Hz
- B3: 120-170 Hz

### Pitch Ranges
- **Male**: 80-180 Hz (typical ~120 Hz)
- **Female**: 160-250 Hz (typical ~220 Hz)
- **Child**: 250-400 Hz (typical ~300 Hz)

---

## Best Practices

### ✓ DO

1. **Use `KlattGrid_createFromVowel()` for all synthesis**
2. **Start with known formant values** (see table above)
3. **Adjust formants gradually** (±50-100 Hz)
4. **Keep bandwidths proportional** (B2 > B1, B3 > B2)
5. **Match pitch to speaker type** (male/female/child)
6. **Export to WAV** for analysis in other tools
7. **Test with short durations** (0.3-0.5s) before scaling up

### ✗ DON'T

1. **Don't use empty `KlattGrid()` constructor** (segfault risk)
2. **Don't set extreme formant values** (F1 > F2 > F3 must hold)
3. **Don't use zero bandwidth** (causes synthesis artifacts)
4. **Don't expect phonetic transcription** (formants only, no articulation model)
5. **Don't assume formant manipulation works** (untested methods)

---

## Troubleshooting

### Segfault on `to_sound()`
**Cause**: Incomplete grid initialization  
**Solution**: Use `KlattGrid_createFromVowel()` instead of empty grid

### "Attempt to apply non-function"
**Cause**: Method not implemented in R wrapper  
**Solution**: Check available methods with `names(kg)`

### Unnatural sounding synthesis
**Cause**: Formant values out of range or wrong bandwidths  
**Solution**: Refer to formant table, adjust B1/B2/B3 proportionally

### No sound output
**Cause**: Voicing amplitude too low or pitch too high/low  
**Solution**: Check f0start is in range 50-400 Hz

---

## References

- Klatt, D. H. (1980). "Software for a cascade/parallel formant synthesizer". *Journal of the Acoustical Society of America*, 67(3), 971-995.
- Praat manual: [KlattGrid](http://www.fon.hum.uva.nl/praat/manual/KlattGrid.html)
- Package tests: `dev/test_klattgrid_comprehensive.R`

---

**Last Updated**: 2026-01-02  
**Module Status**: Production-ready with `createFromVowel()`, avoid empty grid  
**Test Coverage**: 83% (20/24 tests passing)
