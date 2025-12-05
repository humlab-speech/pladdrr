#!/bin/bash
set -e

echo "=== Quick Build and Test ==="
echo "Building package..."

# Build in background, save output
R CMD INSTALL --preclean --no-multiarch . > build.log 2>&1 &
BUILD_PID=$!

echo "Build PID: $BUILD_PID"
echo "Waiting for build to complete..."

# Wait for build
wait $BUILD_PID
BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
    echo "❌ Build FAILED"
    tail -50 build.log
    exit 1
fi

echo "✅ Build succeeded"

# Test RNR
echo ""
echo "Testing RNR..."
Rscript -e "
library(pladdrr)
sound <- Sound\$create_tone(1.0, 44100, 440, 0.2)
spectrum <- sound\$to_spectrum()
cep <- spectrum\$to_powercepstrum()
tryCatch({
  rnr <- cep\$get_rnr(75, 300, 0.05)
  cat('✓ RNR SUCCESS:', rnr, 'dB\n')
}, error = function(e) {
  cat('✗ RNR Error:', e\$message, '\n')
})
"

# Test Cepstrum
echo ""
echo "Testing Cepstrum to Sound..."
Rscript -e "
library(pladdrr)
sound <- Sound\$create_tone(1.0, 44100, 440, 0.2)
cep <- sound\$to_cepstrum()
tryCatch({
  snd <- cep\$to_sound()
  cat('✓ Cepstrum_to_Sound SUCCESS\n')
}, error = function(e) {
  cat('✗ Cepstrum Error:', e\$message, '\n')
})
"

echo ""
echo "=== Test Complete ==="
