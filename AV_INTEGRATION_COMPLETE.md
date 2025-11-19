# AV Package Integration for Sound I/O - Complete

**Date**: 2025-11-19  
**Version**: 0.5.5  
**Status**: ✅ Complete  
**Priority**: Critical - Sound file operations now use av package exclusively

---

## Summary

The `speaker` package now uses the **humlab-speech/av fork** exclusively for all Sound object file I/O operations. This provides support for a wide range of audio and video formats via FFmpeg while maintaining the Praat C++ core for all audio analysis and manipulation.

---

## Changes Made

### 1. DESCRIPTION Updates

**File**: `DESCRIPTION`

- Added `av` to `Imports:`
- Added `Remotes: humlab-speech/av` to specify the GitHub fork
- Updated package dependencies

```yaml
Imports:
    Rcpp (>= 1.0.0),
    R6 (>= 2.5.0),
    S7 (>= 0.1.0),
    av
    
Remotes: humlab-speech/av
```

### 2. Sound Class Initialization (Reading)

**File**: `R/sound-r6-new.R`

**Before**:
- Auto-detection of file format
- Used Praat C code for WAV/AIFF files
- Used av for other formats (MP3, FLAC, etc.)

**After**:
- **All file reading now uses av package** (humlab-speech/av fork)
- Removed `use_av` parameter (always TRUE now)
- Consistent behavior across all audio formats
- Better error messages with installation instructions

```r
initialize = function(path = NULL, .xptr = NULL) {
  if (!is.null(.xptr)) {
    super$initialize(.xptr)
  } else if (!is.null(path)) {
    # Always use av package for file I/O
    if (!requireNamespace("av", quietly = TRUE)) {
      stop("Package 'av' is required for loading audio files.\n",
           "Install from GitHub: remotes::install_github('humlab-speech/av')")
    }
    
    # Read using av::read_audio_bin()
    audio_info <- av::av_media_info(path)
    audio_data <- av::read_audio_bin(path)
    
    # Convert to Praat Sound object
    # ...
  }
}
```

### 3. Sound Save Method (Writing)

**File**: `R/sound-r6-new.R`

**Before**:
- Used Praat C code (`Sound_saveAsAudioFile`)
- Limited format support (WAV, AIFF, FLAC only)
- Fixed parameters

**After**:
- **All file writing now uses av package** (humlab-speech/av fork)
- Support for any FFmpeg-supported format (MP3, OGG, AAC, M4A, etc.)
- Flexible codec and quality options
- Auto-detection of format from file extension

```r
save = function(
  path,
  format = NULL,
  codec = NULL,
  sample_rate = NULL,
  channels = NULL
) {
  # Always use av package for file I/O
  if (!requireNamespace("av", quietly = TRUE)) {
    stop("Package 'av' is required for saving audio files.\n",
         "Install from GitHub: remotes::install_github('humlab-speech/av')")
  }
  
  # Get audio as matrix and write using av
  audio_data <- self$as_matrix()
  audio_data <- t(audio_data)  # av expects samples × channels
  
  av::write_audio_bin(
    audio = audio_data,
    output = path,
    format = format,
    codec = codec,
    sample_rate = sample_rate %||% self$get_sampling_frequency(),
    channels = channels
  )
}
```

### 4. Documentation Updates

**Files**: `R/sound-r6-new.R`, `README.md`

- Updated Sound class documentation to highlight av integration
- Added format support information
- Updated examples to show various formats
- Added installation instructions for av package
- Added FFmpeg system requirements

**README.md additions**:
```markdown
### Audio I/O

The `speaker` package uses the [humlab-speech/av](https://github.com/humlab-speech/av) 
fork for all audio file operations. This provides:

- Support for **any audio/video format** via FFmpeg (MP3, WAV, FLAC, OGG, AAC, M4A, etc.)
- Fast, efficient audio reading and writing
- No external Praat installation required
- Cross-platform compatibility
```

### 5. Test Script

**File**: `test_av_integration.R`

Created comprehensive test script to verify:
- av package availability
- Synthetic audio creation
- WAV file save/load cycle
- MP3 export (if supported)
- Loading existing test files

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│           R User Code (Sound$new)               │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│        av Package (humlab-speech/av)            │
│  • read_audio_bin()  - Load audio files         │
│  • write_audio_bin() - Save audio files         │
│  • av_media_info()   - Get file metadata        │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│            FFmpeg Libraries                     │
│  (Handles MP3, WAV, FLAC, OGG, AAC, etc.)      │
└────────────────┬────────────────────────────────┘
                 │
                 ▼ (numeric matrix)
┌─────────────────────────────────────────────────┐
│      Sound$from_values() / .as_matrix()         │
│      (Convert R matrix ↔ Praat Sound)           │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│        Praat C++ Sound Object (XPtr)            │
│  • All audio analysis (pitch, formants, etc.)   │
│  • All transformations (filtering, resampling)  │
│  • All in-memory operations                     │
└─────────────────────────────────────────────────┘
```

### Data Flow

**Reading**:
1. User: `sound <- Sound$new("audio.mp3")`
2. av: `audio_data <- av::read_audio_bin("audio.mp3")`
3. R matrix: `(samples × channels)` → transpose → `(channels × samples)`
4. Praat: `.sound_create_from_values(audio_data, sample_rate)`
5. Result: Praat Sound XPtr managed by R6 class

**Writing**:
1. User: `sound$save("output.mp3")`
2. R matrix: `audio_data <- sound$as_matrix()` (channels × samples)
3. Transpose: `(channels × samples)` → `(samples × channels)`
4. av: `av::write_audio_bin(audio_data, "output.mp3", format="mp3")`
5. Result: MP3 file created

---

## Benefits

### 1. Wide Format Support
- **Before**: WAV, AIFF, FLAC (Praat-supported formats)
- **After**: MP3, WAV, FLAC, OGG, AAC, M4A, WMA, and any FFmpeg-supported format

### 2. Consistent Behavior
- All audio files processed the same way
- No special cases for different formats
- Predictable error handling

### 3. Better Integration with R Ecosystem
- Works seamlessly with other av-using packages
- Consistent API across packages
- Easier to maintain

### 4. Reduced Dependencies
- No need for external audio libraries in Praat C code
- FFmpeg handles all format conversions
- Simpler build process

### 5. Enhanced Functionality
- Codec selection for compressed formats
- Quality/bitrate control
- Sample rate conversion on save
- Channel remixing on save

---

## Supported Formats

Via av/FFmpeg, the following formats are supported:

**Lossless**:
- WAV (PCM, 16/24/32-bit)
- FLAC (Free Lossless Audio Codec)
- ALAC (Apple Lossless)
- AIFF/AIFC
- WAV64

**Lossy**:
- MP3 (MPEG-1 Layer 3)
- AAC/M4A (Advanced Audio Coding)
- OGG Vorbis
- Opus
- WMA (Windows Media Audio)

**Container Formats** (audio extraction):
- MP4 (video files)
- MKV (Matroska)
- AVI
- MOV (QuickTime)
- WebM

---

## Migration Notes

### For Existing Code

No changes required for most code! Existing workflows will work identically:

```r
# This still works exactly as before
sound <- Sound$new("recording.wav")
pitch <- sound$to_pitch()
sound$save("output.wav")
```

### New Capabilities

You can now do things that weren't possible before:

```r
# Load MP3 files
sound_mp3 <- Sound$new("podcast.mp3")

# Save to compressed formats
sound$save("output.mp3", format = "mp3")
sound$save("output.ogg", format = "ogg")

# Extract audio from video
sound_video <- Sound$new("lecture.mp4")

# Control output quality
sound$save("output.mp3", format = "mp3", codec = "libmp3lame")
```

---

## Testing

Run the integration test:

```bash
Rscript test_av_integration.R
```

Expected output:
```
================================================================================
Testing av Integration for Sound I/O
================================================================================

Test 1: Checking av package availability...
✓ av package available

Test 2: Creating synthetic audio (440Hz tone)...
✓ Created tone: 1.000 seconds, 44100 Hz
  Channels: 1, Samples: 44100

Test 3: Saving to WAV file using av...
✓ Saved to: /tmp/RtmpXXX.wav
  File size: 86.5 KB

Test 4: Loading WAV file using av...
✓ Loaded sound: 1.000 seconds, 44100 Hz
  Channels: 1, Samples: 44100

Test 5: Saving to MP3 file using av...
✓ Saved to: /tmp/RtmpXXX.mp3
  File size: 15.2 KB

All core tests passed! ✓
```

---

## System Requirements

### R Packages
- `av` (humlab-speech/av fork) - **Required**
- Installation: `remotes::install_github("humlab-speech/av")`

### System Libraries

**macOS**:
```bash
brew install ffmpeg
```

**Ubuntu/Debian**:
```bash
sudo apt-get install libavfilter-dev
```

**Fedora/RHEL**:
```bash
sudo dnf install ffmpeg-devel
```

**Windows**:
- FFmpeg libraries included with av package
- No additional installation needed

---

## Future Enhancements

### Potential Additions
1. **Streaming support**: Process large files in chunks
2. **Format validation**: Check format compatibility before save
3. **Metadata support**: Preserve/edit audio metadata
4. **Multi-track support**: Handle multi-channel/multi-track files
5. **Real-time processing**: Integration with audio devices

### Integration Opportunities
1. **tuneR compatibility**: Convert to/from tuneR Wave objects
2. **seewave integration**: Seamless workflow with seewave functions
3. **phonR workflows**: Direct integration for sociophonetic analysis

---

## Deprecations

### Removed Functions
- `.sound_read_from_file()` - Replaced by av-based reading
- `.sound_save()` - Replaced by av-based writing (kept internally but not used)

### Removed Parameters
- `Sound$new(use_av=)` - No longer needed (always uses av)

---

## Conclusion

The integration of the humlab-speech/av package for Sound file I/O provides:

✅ **Wider format support** - Any FFmpeg-supported format  
✅ **Consistent behavior** - Same code path for all formats  
✅ **Better ecosystem integration** - Works with other av-using packages  
✅ **Simpler maintenance** - Less C++ file I/O code  
✅ **Enhanced functionality** - Codec control, quality settings  

The Praat C++ core remains for all audio **analysis and manipulation**, which is where its true value lies. File I/O is now handled by the robust, well-maintained av/FFmpeg ecosystem.

---

**Status**: ✅ **Implementation Complete**  
**Next Steps**: Test with real-world audio files, update vignettes with format examples  
**Version**: Ready for 0.5.5 release
