#!/bin/bash

echo "=== Building and Testing pladdrr ==="

# Remove any lock files
echo "Cleaning up..."
rm -rf /Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/00LOCK-pladdrr 2>/dev/null || true

# Build package
echo ""
echo "Building package (this may take 5-10 minutes)..."
R CMD INSTALL --preclean --no-multiarch . 2>&1 | tee build.log

# Check if build succeeded
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "❌ Build FAILED - see build.log for details"
    tail -30 build.log
    exit 1
fi

echo ""
echo "✅ Build succeeded!"

# Test RNR
echo ""
echo "=== Testing RNR Fix ==="
R --quiet --vanilla << 'RSCRIPT'
library(pladdrr)
sound <- Sound$create_tone(1.0, 44100, 440, 0.2)
spectrum <- sound$to_spectrum()
cep <- spectrum$to_powercepstrum()
tryCatch({
  rnr <- cep$get_rnr(75, 300, 0.05)
  cat('✅ RNR SUCCESS: RNR =', rnr, 'dB\n')
}, error = function(e) {
  cat('❌ RNR Error:', e$message, '\n')
})
RSCRIPT

# Test Cepstrum to Sound
echo ""
echo "=== Testing Cepstrum to Sound Fix ==="
R --quiet --vanilla << 'RSCRIPT'
library(pladdrr)
sound <- Sound$create_tone(1.0, 44100, 440, 0.2)
cep <- sound$to_cepstrum()
tryCatch({
  snd <- cep$to_sound()
  cat('✅ Cepstrum_to_Sound SUCCESS\n')
}, error = function(e) {
  cat('❌ Cepstrum Error:', e$message, '\n')
})
RSCRIPT

echo ""
echo "=== Test Complete ==="
