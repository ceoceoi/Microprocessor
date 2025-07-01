
import argparse
import os
import re
import sys

# Original problematic pattern:
INSTR_RE_OLD = re.compile(
    r"^\s*(?P<time>\d+(?:\.\d+)?)(?:\s+ns)?\s+(?P<cycle>\d+)\s+"
    r"(?P<pc>[0-9a-f]+)\s+(?P<bin>[0-9a-f]+)\s+(?P<instr>\S+\s+\S+)\s*"
)

# Fixed pattern - more flexible with instruction and operands:
INSTR_RE = re.compile(
    r"^\s*(?P<time>\d+(?:\.\d+)?)(?:\s+ns)?\s+(?P<cycle>\d+)\s+"
    r"(?P<pc>[0-9a-f]+)\s+(?P<bin>[0-9a-f]+)\s+(?P<instr>\S+(?:\s+[^\s]+)?)\s*"
)

# Even better - separate instruction name and operands:
INSTR_RE_BETTER = re.compile(
    r"^\s*(?P<time>\d+(?:\.\d+)?)(?:\s+ns)?\s+(?P<cycle>\d+)\s+"
    r"(?P<pc>[0-9a-f]+)\s+(?P<bin>[0-9a-f]+)\s+(?P<instr_name>\S+)(?:\s+(?P<operands>[^\s]+))?\s*"
)

# Test with your sample data:
sample_lines = [
    "810000 39 80000064 7f800237 lui x4,0x7f800 x4=0x7f800000",
    "830000 40 80000068 f0020053 fmvwx f0,x4 x4:0x00000000 f0=0x7f800000", 
    "850000 41 8000006c bc253237 lui x4,0xbc253 x4=0xbc253000",
    "870000 42 80000070 45720213 addi x4,x4,1111 x4:0x7f800000 x4=0xbc253457"
]

print("Testing original regex:")
for line in sample_lines:
    match = INSTR_RE_OLD.search(line)
    if match:
        print(f"✓ Matched: {match.group('instr')}")
    else:
        print(f"✗ No match: {line[:50]}...")

print("\nTesting improved regex:")
for line in sample_lines:
    match = INSTR_RE_BETTER.search(line)
    if match:
        instr_name = match.group('instr_name')
        operands = match.group('operands') or ""
        full_instr = f"{instr_name} {operands}".strip()
        print(f"✓ Matched: {full_instr}")
    else:
        print(f"✗ No match: {line[:50]}...")