"""
Copyright 2019 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Compare the instruction trace CSV
"""

"""
Compare the instruction trace CSV with float tolerance (IEEE 754 compliant).
"""

import argparse
import sys
import os
import struct
import math

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

from riscv_trace_csv import *

# ----------- Float Handling Utilities ------------

def is_float_register(reg_name):
    return reg_name.startswith("f") or reg_name.startswith("ft") or reg_name.startswith("fs")

def hex_to_float(hex_str):
    try:
        hex_str = hex_str.zfill(8)
        int_val = int(hex_str, 16)
        bytes_val = int_val.to_bytes(4, byteorder='big')
        return struct.unpack('>f', bytes_val)[0]
    except Exception:
        return None

def check_update_gpr(gpr_update, gpr, tolerance=0.05):
    gpr_state_change = 0
    for update in gpr_update:
        if update == "":
            return 0
        item = update.split(":")
        if len(item) != 2:
            sys.exit("Illegal GPR update format:" + update)
        rd = item[0]
        rd_val = item[1].lower()
        prev_val = gpr.get(rd, "0").lower()

        # Float register comparison
        if is_float_register(rd):
            f1 = hex_to_float(prev_val)
            f2 = hex_to_float(rd_val)

            if f1 is None or f2 is None:
                gpr_state_change = 1
            elif math.isnan(f1) and math.isnan(f2):
                pass  # Treat NaN == NaN
            elif f1 == 0.0 and f2 == 0.0:
                pass  # Treat +0.0 == -0.0
            elif f1 == f2:
                pass
            elif abs(f1 - f2) > tolerance:
                gpr_state_change = 1
        else:
            if rd in gpr:
                if rd_val != prev_val:
                    gpr_state_change = 1
            else:
                if int(rd_val, 16) != 0:
                    gpr_state_change = 1

        gpr[rd] = rd_val
    return gpr_state_change

# ------------- Main Comparison Logic ---------------

def compare_trace_csv(csv1, csv2, name1, name2, log,
                      in_order_mode=1,
                      coalescing_limit=0,
                      verbose=0,
                      mismatch_print_limit=5,
                      compare_final_value_only=0,
                      float_tol=0.05):
    matched_cnt = 0
    mismatch_cnt = 0

    if compare_final_value_only:
        in_order_mode = 0

    if log:
        fd = open(log, 'a+')
    else:
        fd = sys.stdout

    fd.write("{} : {}\n".format(name1, csv1))
    fd.write("{} : {}\n".format(name2, csv2))

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

        if in_order_mode:
            for trace in instr_trace_1:
                trace_1_index += 1
                if len(trace.gpr) == 0:
                    continue

                gpr_state_change_1 = check_update_gpr(trace.gpr, gpr_val_1, float_tol)
                if gpr_state_change_1 == 0:
                    continue

                gpr_state_change_2 = 0
                while (gpr_state_change_2 == 0 and trace_2_index < len(instr_trace_2)):
                    gpr_state_change_2 = check_update_gpr(instr_trace_2[trace_2_index].gpr, gpr_val_2, float_tol)
                    trace_2_index += 1

                if gpr_state_change_2 == 0:
                    mismatch_cnt += 1
                    fd.write("Mismatch[{}]:\n[{}] {} : {}\n".format(
                        mismatch_cnt, trace_1_index, name1, trace.get_trace_string()))
                    fd.write("{} instructions left in trace {}\n".format(
                        len(instr_trace_1) - trace_1_index + 1, name1))
                elif len(trace.gpr) != len(instr_trace_2[trace_2_index - 1].gpr):
                    mismatch_cnt += 1
                    if mismatch_cnt <= mismatch_print_limit:
                        fd.write("Mismatch[{}]:\n{}[{}] : {}\n".format(
                            mismatch_cnt, name1, trace_2_index - 1, trace.get_trace_string()))
                        fd.write("{}[{}] : {}\n".format(
                            name2, trace_2_index - 1, instr_trace_2[trace_2_index - 1].get_trace_string()))
                else:
                    found_mismatch = 0
                    for i in range(len(trace.gpr)):
                        # compare individual fields with tolerance
                        rd1, val1 = trace.gpr[i].split(":")
                        rd2, val2 = instr_trace_2[trace_2_index - 1].gpr[i].split(":")
                        temp_gpr1 = {rd1: val1}
                        mismatch = check_update_gpr([f"{rd1}:{val2}"], temp_gpr1, float_tol)
                        if mismatch:
                            mismatch_cnt += 1
                            found_mismatch = 1
                            if mismatch_cnt <= mismatch_print_limit:
                                fd.write("Mismatch[{}]:\n{}[{}] : {}\n".format(
                                    mismatch_cnt, name1, trace_2_index - 1, trace.get_trace_string()))
                                fd.write("{}[{}] : {}\n".format(
                                    name2, trace_2_index - 1, instr_trace_2[trace_2_index - 1].get_trace_string()))
                            break
                    if not found_mismatch:
                        matched_cnt += 1

                if trace_2_index == len(instr_trace_2):
                    break

            if trace_2_index != len(instr_trace_2):
                while trace_2_index < len(instr_trace_2):
                    gpr_state_change_2 = check_update_gpr(
                        instr_trace_2[trace_2_index].gpr, gpr_val_2, float_tol)
                    if gpr_state_change_2 == 1:
                        fd.write("Mismatch[{}]:\n[{}] {} : {}\n".format(
                            mismatch_cnt, trace_1_index, name1, trace.get_trace_string()))
                        fd.write("{} instructions left in trace {}\n".format(
                            len(instr_trace_2) - trace_2_index, name2))
                        mismatch_cnt += len(instr_trace_2) - trace_2_index
                        break
                    trace_2_index += 1

    if mismatch_cnt == 0:
        result = "[PASSED]: {} matched\n".format(matched_cnt)
    else:
        result = "[FAILED]: {} matched, {} mismatch\n".format(matched_cnt, mismatch_cnt)

    fd.write(result + "\n")
    if log:
        fd.close()

    return result

# --------------- CLI ----------------

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv_file_1", type=str, required=True)
    parser.add_argument("--csv_file_2", type=str, required=True)
    parser.add_argument("--csv_name_1", type=str, required=True)
    parser.add_argument("--csv_name_2", type=str, required=True)
    parser.add_argument("--log", type=str, default="")
    parser.add_argument("--in_order_mode", type=int, default=1)
    parser.add_argument("--gpr_update_coalescing_limit", type=int, default=1)
    parser.add_argument("--mismatch_print_limit", type=int, default=5)
    parser.add_argument("--verbose", type=int, default=0)
    parser.add_argument("--compare_final_value_only", type=int, default=0)
    parser.add_argument("--float_tol", type=float, default=0.05,
                        help="Tolerance for float comparisons (default: 0.05)")

    args = parser.parse_args()

    compare_trace_csv(
        args.csv_file_1, args.csv_file_2,
        args.csv_name_1, args.csv_name_2,
        args.log,
        args.in_order_mode,
        args.gpr_update_coalescing_limit,
        args.verbose,
        args.mismatch_print_limit,
        args.compare_final_value_only,
        args.float_tol
    )

if __name__ == "__main__":
    main()
