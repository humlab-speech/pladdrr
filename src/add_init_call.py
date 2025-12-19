#!/usr/bin/env python3
"""Add ensure_numeric_libs_initialized() call to textgrid_read_from_file"""

with open('textgrid_wrappers.cpp', 'r') as f:
    lines = f.readlines()

output = []
for i, line in enumerate(lines):
    output.append(line)
    # After the "try {" line in textgrid_read_from_file
    if 'textgrid_read_from_file' in line and '{' not in line:
        # Next line should be "try {"
        if i+1 < len(lines) and 'try {' in lines[i+1]:
            output.append(lines[i+1])  # Add "try {"
            # Insert initialization call
            output.append('        // Initialize numeric libraries (required for text parsing)\n')
            output.append('        ensure_numeric_libs_initialized();\n')
            output.append('        \n')
            # Skip the original "try {" since we already added it
            lines[i+1] = ''  # Mark as processed

with open('textgrid_wrappers.cpp', 'w') as f:
    f.writelines([l for l in output if l])

print("✅ Added initialization call")
