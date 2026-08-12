#!/bin/bash
#
# Generate Reference Data from Original Praat Scripts
#
# This script runs the original Praat AVQI, DSI, and tremor scripts
# to generate reference output for cross-validation testing.

set -e

PRAAT="/Applications/Praat.app/Contents/MacOS/Praat"
PLABENCH_DIR="/Users/frkkan96/Documents/src/plabench"
TEST_DATA_DIR="${PLABENCH_DIR}/signalfiles"
OUTPUT_DIR="${PLABENCH_DIR}/reference_output"

# Check if Praat exists
if [ ! -f "$PRAAT" ]; then
    echo "Error: Praat not found at $PRAAT"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "============================================================="
echo "GENERATING PRAAT REFERENCE DATA"
echo "============================================================="
echo ""

# =============================================================================
# AVQI Reference Data
# =============================================================================

echo "=== Generating AVQI Reference Data ==="
echo ""

AVQI_SCRIPT="${PLABENCH_DIR}/AVQI301.praat"
AVQI_INPUT_DIR="${TEST_DATA_DIR}/AVQI/input"
AVQI_OUTPUT="${OUTPUT_DIR}/avqi_reference.csv"

if [ -f "$AVQI_SCRIPT" ] && [ -d "$AVQI_INPUT_DIR" ]; then
    echo "Running: $AVQI_SCRIPT"
    echo "Input:   $AVQI_INPUT_DIR"
    echo "Output:  $AVQI_OUTPUT"

    # Note: The Praat script may need modification to accept command-line
    # arguments for input/output paths. This is a placeholder.

    # Create a wrapper script that sets the paths
    WRAPPER_SCRIPT=$(mktemp)
    cat > "$WRAPPER_SCRIPT" <<EOF
# Wrapper for AVQI script with paths
input_directory\$ = "${AVQI_INPUT_DIR}"
output_directory\$ = "${OUTPUT_DIR}"
output_file\$ = "${AVQI_OUTPUT}"

# Include the main AVQI script
include ${AVQI_SCRIPT}
EOF

    "$PRAAT" --utf8 --run "$WRAPPER_SCRIPT" 2>&1 | tee "${OUTPUT_DIR}/avqi_log.txt"
    rm "$WRAPPER_SCRIPT"

    echo "✓ AVQI reference data generated"
    echo ""
else
    echo "⚠ AVQI script or test data not found, skipping"
    echo ""
fi

# =============================================================================
# DSI Reference Data
# =============================================================================

echo "=== Generating DSI Reference Data ==="
echo ""

DSI_SCRIPT="${PLABENCH_DIR}/DSI201.praat"
DSI_INPUT_DIR="${TEST_DATA_DIR}/DSI/input"
DSI_OUTPUT="${OUTPUT_DIR}/dsi_reference.csv"

if [ -f "$DSI_SCRIPT" ] && [ -d "$DSI_INPUT_DIR" ]; then
    echo "Running: $DSI_SCRIPT"
    echo "Input:   $DSI_INPUT_DIR"
    echo "Output:  $DSI_OUTPUT"

    WRAPPER_SCRIPT=$(mktemp)
    cat > "$WRAPPER_SCRIPT" <<EOF
# Wrapper for DSI script with paths
input_directory\$ = "${DSI_INPUT_DIR}"
output_directory\$ = "${OUTPUT_DIR}"
output_file\$ = "${DSI_OUTPUT}"

# Include the main DSI script
include ${DSI_SCRIPT}
EOF

    "$PRAAT" --utf8 --run "$WRAPPER_SCRIPT" 2>&1 | tee "${OUTPUT_DIR}/dsi_log.txt"
    rm "$WRAPPER_SCRIPT"

    echo "✓ DSI reference data generated"
    echo ""
else
    echo "⚠ DSI script or test data not found, skipping"
    echo ""
fi

# =============================================================================
# Tremor Reference Data
# =============================================================================

echo "=== Generating Tremor Reference Data ==="
echo ""

TREMOR_SCRIPT="${PLABENCH_DIR}/tremor3.05/tremor.praat"
TREMOR_CONSOLE_SCRIPT="${PLABENCH_DIR}/tremor3.05/console_tremor305.praat"

if [ -f "$TREMOR_CONSOLE_SCRIPT" ]; then
    echo "Running: $TREMOR_CONSOLE_SCRIPT"

    # For each test audio file, run tremor analysis
    if [ -d "${TEST_DATA_DIR}/tremor" ]; then
        for wav_file in "${TEST_DATA_DIR}/tremor"/*.wav; do
            if [ -f "$wav_file" ]; then
                basename=$(basename "$wav_file" .wav)
                output_csv="${OUTPUT_DIR}/tremor_${basename}.csv"

                echo "  Processing: $wav_file"

                # console_tremor305.praat arguments:
                # StartTime EndTime SelectionOffset SelectionLength WindowType WindowWidth
                # analysis_time_step min_pitch max_pitch silence_threshold voicing_threshold
                # octave_cost octave_jump_cost voiced_unvoiced_cost amplitude_method
                # min_tremor_freq max_tremor_freq contour_magnitude_threshold
                # tremor_cyclicality_threshold freq_tremor_octave_cost amp_tremor_octave_cost
                # output_indeterminate_values sound_path output_path

                "$PRAAT" --utf8 --run "$TREMOR_CONSOLE_SCRIPT" \
                    0.0 0.0 0.0 0.0 "Gaussian1" 1.0 \
                    0.015 60 350 0.03 0.3 0.01 0.35 0.14 2 \
                    1.5 15 0.01 0.15 0.01 0.01 2 \
                    "$wav_file" "$output_csv" \
                    2>&1 | tee -a "${OUTPUT_DIR}/tremor_log.txt"

                echo "    Output: $output_csv"
            fi
        done

        echo "✓ Tremor reference data generated"
        echo ""
    else
        echo "⚠ Tremor test data directory not found"
        echo ""
    fi
else
    echo "⚠ Tremor script not found, skipping"
    echo ""
fi

# =============================================================================
# Summary
# =============================================================================

echo "============================================================="
echo "REFERENCE DATA GENERATION COMPLETE"
echo "============================================================="
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "Files generated:"
ls -lh "$OUTPUT_DIR" 2>/dev/null || echo "  (none)"
echo ""
echo "These reference files can be used to validate R and Python"
echo "implementations against the original Praat scripts."
echo ""
