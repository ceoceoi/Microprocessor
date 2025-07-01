import argparse
import re
import sys
import os
import struct
import math

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from riscv_trace_csv import *

def float32(hex_val):
    return struct.unpack('!f', bytes.fromhex(f"{hex_val:08x}"))[0]

def is_nan_bitpattern(val):
    return (val & 0x7f800000) == 0x7f800000 and (val & 0x007fffff) != 0

def compare_trace_csv(csv1, csv2, name1, name2, log,
                      in_order_mode=1,
                      coalescing_limit=0,
                      verbose=0,
                      mismatch_print_limit=5,
                      compare_final_value_only=0,
                      float_instr_set=None,
                      float_tolerance=0.0,
                      ignore_instr_set=None):
    matched_cnt = 0
    mismatch_cnt = 0

    if float_instr_set is None:
        float_instr_set = []
    if ignore_instr_set is None:
        ignore_instr_set = []

    fd = open(log, 'a+') if log else sys.stdout
    fd.write(f"{name1} : {csv1}\n{name2} : {csv2}\n")

    with open(csv1, "r") as fd1, open(csv2, "r") as fd2:
        instr_trace_1 = []
        instr_trace_2 = []
        trace_csv_1 = RiscvInstructionTraceCsv(fd1)
        trace_csv_2 = RiscvInstructionTraceCsv(fd2)
        trace_csv_1.read_trace(instr_trace_1)
        trace_csv_2.read_trace(instr_trace_2)

        trace_1_index = 0
        trace_2_index = 0
        gpr_val_1 = {}
        gpr_val_2 = {}

        while trace_1_index < len(instr_trace_1) and trace_2_index < len(instr_trace_2):
            trace1 = instr_trace_1[trace_1_index]
            trace2 = instr_trace_2[trace_2_index]
            trace_1_index += 1
            trace_2_index += 1

            trace1_instr = trace1.instr_str.strip()
            trace2_instr = trace2.instr_str.strip()
            if any(trace1_instr.startswith(instr) for instr in ignore_instr_set):
                continue

            if len(trace1.gpr) == 0:
                continue

            gpr_state_change_1 = check_update_gpr(trace1.gpr, gpr_val_1)
            gpr_state_change_2 = check_update_gpr(trace2.gpr, gpr_val_2)
            if not gpr_state_change_1 and not gpr_state_change_2:
                continue

            if len(trace1.gpr) != len(trace2.gpr):
                mismatch_cnt += 1
                if mismatch_cnt <= mismatch_print_limit:
                    fd.write(f"Mismatch[{mismatch_cnt}]: Length mismatch\n{name1}[{trace_1_index - 1}] : {trace1.get_trace_string()}\n{name2}[{trace_2_index - 1}] : {trace2.get_trace_string()}\n")
                continue

            found_mismatch = False
            for i in range(len(trace1.gpr)):
                rd1 = trace1.gpr[i].split(":")
                rd2 = trace2.gpr[i].split(":")
                if len(rd1) != 2 or len(rd2) != 2:
                    continue
                reg1, val1 = rd1
                reg2, val2 = rd2
                if reg1 != reg2:
                    found_mismatch = True
                    break

                int_val1 = int(val1, 16)
                int_val2 = int(val2, 16)

                if reg1.startswith("f"):
                    is_nan1 = is_nan_bitpattern(int_val1)
                    is_nan2 = is_nan_bitpattern(int_val2)

                    if is_nan1 and is_nan2:
                        continue  # Skip NaN-to-NaN comparison
                    elif is_nan1 or is_nan2:
                        if mismatch_cnt <= mismatch_print_limit:
                            fd.write(f"[NaN mismatch]: {reg1} val1=0x{int_val1:08x}, val2=0x{int_val2:08x}\n")
                        continue

                    fval1 = float32(int_val1)
                    fval2 = float32(int_val2)
                    diff = abs(fval1 - fval2)
                    ref = max(abs(fval1), abs(fval2), 1e-30)
                    rel_err = diff / ref
                    if rel_err > float_tolerance:
                        found_mismatch = True
                        if mismatch_cnt <= mismatch_print_limit:
                            fd.write(f"⚠️ Float mismatch in {trace1_instr} ({reg1}):\n")
                            fd.write(f"    {name1} {reg1} = {fval1:.8f} ({val1})\n")
                            fd.write(f"    {name2} {reg2} = {fval2:.8f} ({val2})\n")
                            fd.write(f"    abs_diff = {diff:.8e}, rel_error = {rel_err:.6f}, tolerance = {float_tolerance:.6f}\n")
                        break
                else:
                    if int_val1 != int_val2:
                        found_mismatch = True
                        break

            if found_mismatch:
                mismatch_cnt += 1
                if mismatch_cnt <= mismatch_print_limit:
                    fd.write(f"Mismatch[{mismatch_cnt}]:\n{name1}[{trace_1_index - 1}] : {trace1.get_trace_string()}\n{name2}[{trace_2_index - 1}] : {trace2.get_trace_string()}\n")
            else:
                matched_cnt += 1

    result_msg = f"[PASSED]: {matched_cnt} matched\n" if mismatch_cnt == 0 else f"[FAILED]: {matched_cnt} matched, {mismatch_cnt} mismatch\n"
    fd.write(result_msg)
    if log:
        fd.close()
    return result_msg

def check_update_gpr(gpr_update, gpr):
    gpr_state_change = 0
    for update in gpr_update:
        if update == "":
            return 0
        item = update.split(":")
        if len(item) != 2:
            sys.exit("Illegal GPR update format:" + update)
        rd = item[0]
        rd_val = item[1]
        if rd in gpr:
            if rd_val != gpr[rd]:
                gpr_state_change = 1
        else:
            if int(rd_val, 16) != 0:
                gpr_state_change = 1
        gpr[rd] = rd_val
    return gpr_state_change

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv_file_1", required=True)
    parser.add_argument("--csv_file_2", required=True)
    parser.add_argument("--csv_name_1", required=True)
    parser.add_argument("--csv_name_2", required=True)
    parser.add_argument("--log", default="")
    parser.add_argument("--in_order_mode", type=int, default=1)
    parser.add_argument("--gpr_update_coalescing_limit", type=int, default=1)
    parser.add_argument("--mismatch_print_limit", type=int, default=5)
    parser.add_argument("--verbose", type=int, default=0)
    parser.add_argument("--compare_final_value_only", type=int, default=0)
    parser.add_argument("--float_instr_list", type=str, default="fadd.s")
    parser.add_argument("--ignore_instr_list", type=str, default="csrrw,csrrs,csrrc,csrw,csrr")
    parser.add_argument("--float_tolerance", type=float, default=50.0)

    args = parser.parse_args()
    float_instrs = [i.strip() for i in args.float_instr_list.split(",") if i.strip()]
    ignore_instrs = [i.strip() for i in args.ignore_instr_list.split(",") if i.strip()]

    compare_trace_csv(
        args.csv_file_1, args.csv_file_2,
        args.csv_name_1, args.csv_name_2,
        args.log,
        args.in_order_mode,
        args.gpr_update_coalescing_limit,
        args.verbose,
        args.mismatch_print_limit,
        args.compare_final_value_only,
        float_instr_set=float_instrs,
        float_tolerance=args.float_tolerance,
        ignore_instr_set=ignore_instrs
    )

if __name__ == "__main__":
    main()