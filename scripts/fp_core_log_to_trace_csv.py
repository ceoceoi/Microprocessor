# Copyright lowRISC contributors.
# Copyright 2020 Lampro Mellon
#
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Convert Core log to the standard trace CSV format

import argparse
import os
import re
import sys

_CORE_ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '../'))
_DV_SCRIPTS = os.path.join(_CORE_ROOT, '../../../google_riscv_dv/scripts')
_OLD_SYS_PATH = sys.path

# Import riscv_trace_csv and lib from _DV_SCRIPTS before restoring sys.path
try:
    sys.path.insert(0, _DV_SCRIPTS)

    from riscv_trace_csv import (RiscvInstructionTraceCsv,
                                 RiscvInstructionTraceEntry,
                                 get_imm_hex_val)
    from lib import RET_FATAL, gpr_to_abi, sint_to_hex
    import logging
finally:
    sys.path = _OLD_SYS_PATH

# Regex to match full instruction line, including floating point
INSTR_RE = re.compile(
    r"^\s*(?P<time>\d+(?:\.\d+)?)(?:\s+ns)?\s+(?P<cycle>\d+)\s+"
    r"(?P<pc>[0-9a-f]+)\s+(?P<bin>[0-9a-f]+)\s+(?P<instr>.+?)(?:\s{2,}|$)"
)

# Regex for register values
RD_RE = re.compile(r"(x(?P<rd>[1-9]\d*)=0x(?P<rd_val>[0-9a-f]+))")
FPR_RE = re.compile(r"(f(?P<fpr>[0-9]+)=0x(?P<fpr_val>[0-9a-f]+))")

# Operand processing
ADDR_RE = re.compile(r"(?P<imm>[\-0-9]+?)\((?P<rs1>.*)\)")
OPERANDS_RE = re.compile(r"(?P<reg1>\w+),(?P<imm>[0-9a-fA-F-]+)\((?P<reg2>\w+)\)")
ECALL_RE = re.compile(r"^\s*(?P<time>\d+)\s+(?P<cycle>\d+)\s+(?P<pc>[0-9a-f]+)\s+(?P<bin>[0-9a-f]+)\s+ecall")

def _process_core_sim_log_fd(log_fd, csv_fd, full_trace=True):
    instr_cnt = 0
    trace_csv = RiscvInstructionTraceCsv(csv_fd)
    trace_csv.start_new_trace()
    trace_entry = None

    for line in log_fd:
        if re.search("ecall", line):
            instr_cnt += 1
            m = ECALL_RE.search(line)
            if m:
                trace_entry = RiscvInstructionTraceEntry()
                trace_entry.mode = 3
                trace_entry.instr_str = "ecall"
                trace_entry.pc = m.group("pc")
                trace_entry.binary = m.group("bin")
                trace_csv.write_trace_entry(trace_entry)
            break

        # Match instructions
        m = INSTR_RE.search(line)
        if m:
            instr_cnt += 1
            trace_entry = RiscvInstructionTraceEntry()
            trace_entry.mode = 3
            trace_entry.instr_str = m.group("instr").strip()
            trace_entry.instr = m.group("instr").split()[0]
            trace_entry.pc = m.group("pc")
            trace_entry.binary = m.group("bin")

            if full_trace:
                operands = " ".join(m.group("instr").split()[1:])
                trace_entry.operand = operands
                process_operands(trace_entry)
                trace_entry.operand = convert_operands_to_abi(trace_entry.operand)
                process_trace(trace_entry)

        # Match GPR writes
        c = RD_RE.search(line)
        if c:
            if trace_entry is not None:
                if not hasattr(trace_entry, 'gpr') or trace_entry.gpr is None:
                    trace_entry.gpr = []
                trace_entry.gpr.append('{}:{}'
                                       .format(gpr_to_abi("x{}".format(c.group("rd"))),
                                               c.group("rd_val")))
                trace_csv.write_trace_entry(trace_entry)

        # Match FPR writes
        f = FPR_RE.search(line)
        if f:
            if trace_entry is not None:
                if not hasattr(trace_entry, 'gpr') or trace_entry.gpr is None:
                    trace_entry.gpr = []
                trace_entry.gpr.append('{}:{}'
                                       .format(gpr_to_abi("f{}".format(f.group("fpr"))),
                                               f.group("fpr_val")))
                trace_csv.write_trace_entry(trace_entry)

    return instr_cnt


def process_core_sim_log(core_log, csv, full_trace=1):
    logging.info("Processing core log : %s" % core_log)
    try:
        with open(core_log, "r") as log_fd, open(csv, "w") as csv_fd:
            count = _process_core_sim_log_fd(log_fd, csv_fd, full_trace)
    except FileNotFoundError:
        raise RuntimeError("Logfile %s not found" % core_log)

    logging.info("Processed instruction count : %d" % count)
    if not count:
        raise RuntimeError("No instructions in logfile: %s" % core_log)

    logging.info("CSV saved to : %s" % csv)


def convert_operands_to_abi(operand_str):
    operand_list = operand_str.split(",")
    for i in range(len(operand_list)):
        converted_op = gpr_to_abi(operand_list[i].strip())
        if converted_op != "na":
            operand_list[i] = converted_op
    return ",".join(operand_list)


def process_trace(trace):
    process_imm(trace)
    if trace.instr == 'jalr':
        n = ADDR_RE.search(trace.operand)
        if n:
            trace.imm = get_imm_hex_val(n.group("imm"))


def process_operands(trace):
    ops = OPERANDS_RE.search(trace.operand)
    if ops:
        trace.operand = "{0},{1},{2}".format(ops.group('reg1'),
                                             ops.group('imm'),
                                             ops.group('reg2'))


def process_imm(trace):
    if trace.instr in ['beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu', 'c.beqz',
                       'c.bnez', 'beqz', 'bnez', 'bgez', 'bltz', 'blez',
                       'bgtz', 'c.j', 'j', 'c.jal', 'jal']:
        idx = trace.operand.rfind(',')
        if idx == -1:
            imm = trace.operand
            imm = str(sint_to_hex(int(imm, 16) - int(trace.pc, 16)))
            trace.operand = imm
        else:
            imm = trace.operand[idx + 1:]
            imm = str(sint_to_hex(int(imm, 16) - int(trace.pc, 16)))
            trace.operand = trace.operand[0:idx + 1] + imm


def check_core_uvm_log(uvm_log, core_name, test_name, report, write=True):
    passed = False
    failed = False
    with open(uvm_log, "r") as log:
        for line in log:
            if 'RISC-V UVM TEST PASSED' in line:
                passed = True
            if 'RISC-V UVM TEST FAILED' in line:
                failed = True
                break
    if failed:
        passed = False
    if write:
        fd = open(report, "a+") if report else sys.stdout
        fd.write("%s uvm log : %s\n" % (core_name, uvm_log))
        if passed:
            fd.write("%s : [PASSED]\n\n" % test_name)
        elif failed:
            fd.write("%s : [FAILED]\n\n" % test_name)
        if report:
            fd.close()
    return passed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", type=argparse.FileType('r'), default=sys.stdin,
                        help="Input core simulation log (default: stdin)")
    parser.add_argument("--csv", type=argparse.FileType('w'), default=sys.stdout,
                        help="Output trace csv file (default: stdout)")
    parser.add_argument("--full_trace", type=int, default=1,
                        help="Enable full log trace")

    args = parser.parse_args()

    _process_core_sim_log_fd(args.log, args.csv,
                             True if args.full_trace else False)


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as err:
        sys.stderr.write('Error: {}\n'.format(err))
        sys.exit(RET_FATAL)
