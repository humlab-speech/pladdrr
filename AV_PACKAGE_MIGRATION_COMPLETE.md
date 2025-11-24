# Audio Loading Migration to av Package - Complete

**Date**: 2025-11-24  
**Status**: ✅ Complete

## Summary

All audio/media file loading has been migrated to use exclusively the `av` package (humlab-speech/av fork). No other audio loading packages (tuneR, seewave, audio) are used anywhere in the codebase.

## Changes Made

### 1. R/sound.R - Legacy S3 read_sound()
**Changed**: Migrated from `tuneR::readWave()` to `av::read_audio_bin()`

**Before**:
- Used `tuneR::readWave()` for WAV files only
- Required tuneR package
- Limited to WAV format
- Manual bit-depth normalization

**After**:
- Uses `av::read_audio_bin()` via FFmpeg
- Supports WAV, MP3, FLAC, OGG, M4A, AAC, WMA, AIFF, and many more formats
- Automatic normalization to [-1, 1] range
- Consistent with R6 Sound class implementation

### 2. R/sound-r6-new.R - Sound R6 Class
**Status**: ✅ Already using av package (no changes needed)
- `Sound$new(path)` uses `av::read_audio_bin()` and `av::av_media_info()`
- `Sound$save(path)` uses `av::write_audio_bin()`
- Supports all FFmpeg-compatible formats

### 3. DESCRIPTION
**Changed**: Removed tuneR from Imports

**Before**:
```
Imports:
    av (>= 0.5.0),
    tuneR,
    ...
```

**After**:
```
Imports:
    av (>= 0.5.0),
    ...
Remotes: humlab-speech/av
```

### 4. src/sound_fileio_stub.cpp
**Changed**: Updated documentation to reference av package instead of tuneR

**Key Changes**:
- Error messages now direct users to `Sound$new(path)` or `av::read_audio_bin()`
- Removed references to tuneR, seewave, and audio packages
- Emphasized that all file I/O uses av package

## Verification

### ✅ No Praat C File I/O Used
The following Praat source files that handle file I/O are **excluded** from the build:
- `praat.github.io/fon/Sound_files.cpp` - NOT in Makevars FON_SRC
- `praat.github.io/fon/LongSound.cpp` - NOT in Makevars FON_SRC
- `praat.github.io/fon/Movie.cpp` - NOT in Makevars FON_SRC

The stub file `src/sound_fileio_stub.cpp` provides error messages if any code attempts to call Praat's file I/O functions.

### ✅ No tuneR References Remain
```bash
$ grep -r "tuneR" --include="*.R" --include="*.cpp" R/ src/
# No results (all removed)
```

### ✅ av Package Usage
All audio file operations now use:
- `av::read_audio_bin()` - Read audio files
- `av::write_audio_bin()` - Write audio files  
- `av::av_media_info()` - Get audio metadata
- Supports all FFmpeg-compatible formats

## Audio Format Support

### Previously (tuneR)
- ✅ WAV (various bit depths)
- ❌ MP3, FLAC, OGG, M4A, etc.

### Now (av package via FFmpeg)
- ✅ WAV (all variants)
- ✅ MP3 (MPEG Layer 3)
- ✅ FLAC (lossless)
- ✅ OGG (Vorbis/Opus)
- ✅ M4A/AAC (Apple/iTunes)
- ✅ WMA (Windows Media)
- ✅ AIFF (Apple)
- ✅ Many more FFmpeg-supported formats

## API Consistency

Both the legacy S3 interface and modern R6 interface now use av:

**Legacy S3 (R/sound.R)**:
```r
sound <- read_sound("audio.mp3", channel = 0)
```

**Modern R6 (R/sound-r6-new.R)**:
```r
sound <- Sound$new("audio.mp3")
```

**Direct av integration**:
```r
library(av)
audio_data <- av::read_audio_bin("audio.wav")
sound <- Sound$from_matrix(t(audio_data), sampling_rate = 44100)
```

## Benefits

1. **Unified Interface**: Single package for all audio I/O
2. **Format Support**: 30+ audio/video formats via FFmpeg
3. **No Praat File I/O**: Avoids complex Praat C file handling code
4. **Fewer Dependencies**: Removed tuneR dependency
5. **Better Integration**: av is from humlab-speech organization (same as pladdrr)
6. **Future-Proof**: av package actively maintained, FFmpeg industry-standard

## Testing

Users can verify the migration:

```r
library(pladdrr)

# Test various formats
sound_wav <- Sound$new("test.wav")
sound_mp3 <- Sound$new("test.mp3")
sound_flac <- Sound$new("test.flac")

# Legacy interface
sound <- read_sound("test.wav")

# Save in different formats
sound$save("output.wav")
sound$save("output.mp3", format = "mp3")
sound$save("output.flac", format = "flac")
```

## Files Modified

1. ✅ `R/sound.R` - Migrated read_sound() from tuneR to av
2. ✅ `src/sound_fileio_stub.cpp` - Updated documentation
3. ✅ `DESCRIPTION` - Removed tuneR from Imports
4. ✅ `R/sound-r6-new.R` - Already using av (verified, no changes)

## Files Excluded from Build

These Praat source files are NOT compiled (verified in Makevars):
- `praat.github.io/excluded_sources/Sound_files.cpp`
- `praat.github.io/excluded_sources/LongSound.cpp`
- `praat.github.io/excluded_sources/Movie.cpp`
- `praat.github.io/fon/Sound_files.cpp` (in fon/ but NOT in FON_SRC list)
- `praat.github.io/fon/LongSound.cpp` (in fon/ but NOT in FON_SRC list)
- `praat.github.io/fon/Movie.cpp` (in fon/ but NOT in FON_SRC list)

## Migration Complete ✅

All audio file loading now exclusively uses the av package (humlab-speech/av fork). No Praat C file I/O code is compiled or used. No tuneR, seewave, or other audio packages are required.

---
*Package: pladdrr v0.9.9*  
*Migration Date: 2025-11-24*
