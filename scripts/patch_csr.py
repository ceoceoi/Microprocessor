#!/usr/bin/env python3
import sys

NOP_INSTRUCTION = 0x00000013  # integer form of 00000013
TARGET_CSRS = {0x300, 0x305, 0x341}
MHARTID_CSR = 0xF14
MRET_IMM = 0x302

def is_mret_or_target_csr_write(instr_word):
    opcode = instr_word & 0x7F
    if opcode != 0x73:
        return False

    funct3 = (instr_word >> 12) & 0x7
    csr    = (instr_word >> 20) & 0xFFF

    if funct3 == 0 and csr == MRET_IMM:
        return True
    if funct3 != 0 and csr in TARGET_CSRS:
        return True

    return False

def is_csr_read_from_mhartid(instr_word):
    opcode = instr_word & 0x7F
    funct3 = (instr_word >> 12) & 0x7
    csr    = (instr_word >> 20) & 0xFFF
    return opcode == 0x73 and funct3 != 0 and csr == MHARTID_CSR

def patch_specific_instructions(filename):
    with open(filename, 'r') as f:
        lines = [l.strip() for l in f if l.strip()]

    patched = []
    for line in lines:
        hex_str = line.lower()
        if hex_str.startswith('0x'):
            hex_str = hex_str[2:]

        try:
            instr = int(hex_str, 16)
        except ValueError:
            patched.append(line)
            continue

        if is_mret_or_target_csr_write(instr):
            print(f"Patching with NOP     : 0x{instr:08x}")
            patched.append(f"{NOP_INSTRUCTION:08x}")
        elif is_csr_read_from_mhartid(instr):
            rd = (instr >> 7) & 0x1F
            addi_instr = (0b0010011) | (0 << 20) | (rd << 7) | (0 << 15) | (0 << 12)
            # opcode=0x13 (0010011), imm=0, rs1=0, funct3=000, rd=rd
            print(f"Replacing mhartid read: 0x{instr:08x} -> addi x{rd}, x0, 0")
            patched.append(f"{addi_instr:08x}")
        else:
            patched.append(f"{instr:08x}")

    with open(filename, 'w') as f:
        for w in patched:
            f.write(w + '\n')

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 patch_specific_csrs_to_nop.py <hex_file>")
        sys.exit(1)

    patch_specific_instructions(sys.argv[1])
