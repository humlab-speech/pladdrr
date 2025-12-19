#!/usr/bin/env python3
"""Apply numeric initialization patch to textgrid_wrappers.cpp"""

# Read the original backup
with open('textgrid_wrappers.cpp.backup', 'r') as f:
    lines = f.readlines()

# Output buffer
output = []

# Part 1: Lines up to line 13 (includes)
output.extend(lines[0:13])

# Add numeric library headers
output.append('\n')
output.append('// Numeric library headers for initialization\n')
output.append('#include "praat.github.io/dwsys/NUMmachar.h"\n')
output.append('#include "praat.github.io/melder/NUMrandom.h"\n')

# Part 2: Warning handler section (lines 14-58, indices 13-58)
output.extend(lines[13:58])

# Add numeric initialization section
output.append('\n')
output.append('// ============================================================================\n')
output.append('// Numeric Library Initialization\n')
output.append('// ============================================================================\n')
output.append('\n')
output.append('// Global flag to ensure we only initialize numeric libraries once\n')
output.append('static bool numeric_libs_initialized = false;\n')
output.append('\n')
output.append('// Initialize numeric libraries (required for text parsing and data reading)\n')
output.append('static void ensure_numeric_libs_initialized() {\n')
output.append('    if (!numeric_libs_initialized) {\n')
output.append('        NUMmachar();\n')
output.append('        NUMrandom_initializeSafelyAndUnpredictably();\n')
output.append('        numeric_libs_initialized = true;\n')
output.append('    }\n')
output.append('}\n')

# Part 3: TextGrid I/O header and function start (lines 59-66, indices 58-66)
output.extend(lines[58:66])

# Inject initialization call after "try {"
output.append('        // Initialize numeric libraries (required for text parsing)\n')
output.append('        ensure_numeric_libs_initialized();\n')
output.append('        \n')

# Part 4: Rest of function and file (from line 67 onwards, index 66)
output.extend(lines[66:])

# Write output
with open('textgrid_wrappers.cpp', 'w') as f:
    f.writelines(output)

print("✅ Patch applied successfully")
print(f"   Total lines: {len(output)}")
