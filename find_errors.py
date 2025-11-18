#!/usr/bin/env python3
import sys

# Read install.log
with open('/Users/frkkan96/Documents/src/speaker/install.log', 'r') as f:
    lines = f.readlines()
    
print(f"Total lines in install.log: {len(lines)}")
print(f"\nLast 50 lines:")
print("="*80)
for line in lines[-50:]:
    print(line, end='')
