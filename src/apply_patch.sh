#!/bin/bash
# Apply the numeric initialization patch to textgrid_wrappers.cpp

INPUT="textgrid_wrappers.cpp.backup"
OUTPUT="textgrid_wrappers.cpp"

# Part 1: Lines 1-13 (up to and including dwtools include)
sed -n '1,13p' "$INPUT" > "$OUTPUT"

# Add numeric library headers
cat >> "$OUTPUT" << 'EOF'

// Numeric library headers for initialization
#include "praat.github.io/dwsys/NUMmachar.h"
#include "praat.github.io/melder/NUMrandom.h"
EOF

# Part 2: Lines 15-58 (warning handler code)
sed -n '15,58p' "$INPUT" >> "$OUTPUT"

# Add numeric initialization section
cat >> "$OUTPUT" << 'EOF'

// ============================================================================
// Numeric Library Initialization
// ============================================================================

// Global flag to ensure we only initialize numeric libraries once
static bool numeric_libs_initialized = false;

// Initialize numeric libraries (required for text parsing and data reading)
static void ensure_numeric_libs_initialized() {
    if (!numeric_libs_initialized) {
        NUMmachar();
        NUMrandom_initializeSafelyAndUnpredictably();
        numeric_libs_initialized = true;
    }
}
EOF

# Part 3: Lines 60-66 (TextGrid Creation & I/O header and function start)
sed -n '60,66p' "$INPUT" >> "$OUTPUT"

# Add initialization call in the function
cat >> "$OUTPUT" << 'EOF'
        // Initialize numeric libraries (required for text parsing)
        ensure_numeric_libs_initialized();
        
EOF

# Part 4: Rest of the file starting from line 67
sed -n '67,$p' "$INPUT" >> "$OUTPUT"

echo "Patch applied successfully"
