# """ 
# Fixed spike_log_to_trace_csv.py
# - Always enables full_trace
# - No trampoline skipping
# - Clean indentation
# """

# import argparse
# import os
# import re
# import sys
# import logging

# sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

# from riscv_trace_csv import *
# from lib import *

# RD_RE = re.compile(
#     r"(core\s+\d+:\s+)?(?P<pri>\d)\s+0x(?P<addr>[a-f0-9]+?)\s+"     r"\((?P<bin>.*?)\)\s+(?P<reg>[xf]\s*\d*?)\s+0x(?P<val>[a-f0-9]+)"     r"(\s+(?P<csr>\S+)\s+0x(?P<csr_val>[a-f0-9]+))?")
# CORE_RE = re.compile(
#     r"core\s+\d+:\s+0x(?P<addr>[a-f0-9]+?)\s+\(0x(?P<bin>.*?)\)\s+(?P<instr>.*?)$")
# ADDR_RE = re.compile(
#     r"(?P<rd>[a-z0-9]+?),(?P<imm>[\-0-9]+?)\((?P<rs1>[a-z0-9]+)\)")
# ILLE_RE = re.compile(r"trap_illegal_instruction")

# LOGGER = logging.getLogger()


# def process_instr(trace):
#     if trace.instr == "jal":
#         idx = trace.operand.rfind(",")
#         imm = trace.operand[idx + 1:]
#         if imm[0] == "-":
#             imm = "-" + str(int(imm[1:], 16))
#         else:
#             imm = str(int(imm, 16))
#         trace.operand = trace.operand[0:idx + 1] + imm
#     m = ADDR_RE.search(trace.operand)
#     if m:
#         trace.operand = "{},{},{}".format(
#             m.group("rd"), m.group("rs1"), m.group("imm"))


# def read_spike_instr(match, full_trace):
#     disasm = match.group('instr')
#     disasm = disasm.replace('pc + ', '').replace('pc - ', '-')

#     instr = RiscvInstructionTraceEntry()
#     instr.pc = match.group('addr')
#     instr.instr_str = disasm
#     instr.binary = match.group('bin')

#     if full_trace:
#         opcode = disasm.split(' ')[0]
#         operand = disasm[len(opcode):].replace(' ', '')
#         instr.instr, instr.operand =             convert_pseudo_instr(opcode, operand, instr.binary)
#         process_instr(instr)

#     return instr


# def read_spike_trace(path, full_trace):
#     instr = None

#     with open(path, 'r') as handle:
#         for line in handle:
#             if instr is None:
#                 instr_match = CORE_RE.match(line)
#                 if not instr_match:
#                     continue
#                 instr = read_spike_instr(instr_match, full_trace)
#                 if instr.instr_str == 'ecall':
#                     break
#                 continue

#             instr_match = CORE_RE.match(line)
#             if instr_match:
#                 yield instr, False
#                 instr = read_spike_instr(instr_match, full_trace)
#                 if instr.instr_str == 'ecall':
#                     break
#                 continue

#             if 'trap_illegal_instruction' in line:
#                 yield (instr, True)
#                 instr = None
#                 continue

#             commit_match = RD_RE.match(line)
#             if commit_match:
#                 groups = commit_match.groupdict()
#                 instr.gpr.append(gpr_to_abi(groups["reg"].replace(' ', '')) +
#                                  ":" + groups["val"])
#                 if groups["csr"] and groups["csr_val"]:
#                     instr.csr.append(groups["csr"] + ":" + groups["csr_val"])
#                 instr.mode = commit_match.group('pri')

#         if instr is not None:
#             yield (instr, False)


# def process_spike_sim_log(spike_log, csv, full_trace=1):
#     logging.info("Processing spike log : {}".format(spike_log))
#     instrs_in = 0
#     instrs_out = 0

#     with open(csv, "w") as csv_fd:
#         trace_csv = RiscvInstructionTraceCsv(csv_fd)
#         trace_csv.start_new_trace()

#         for (entry, illegal) in read_spike_trace(spike_log, full_trace):
#             instrs_in += 1
#             if illegal and full_trace:
#                 logging.debug("Illegal instruction: {}, opcode:{}"
#                               .format(entry.instr_str, entry.binary))
#             if not (full_trace or entry.gpr or entry.instr_str in ['wfi', 'ecall']):
#                 continue
#             trace_csv.write_trace_entry(entry)
#             instrs_out += 1

#     logging.info("Processed instruction count : {}".format(instrs_in))
#     logging.info("CSV saved to : {}".format(csv))
#     return instrs_out


# def main():
#     parser = argparse.ArgumentParser()
#     parser.add_argument("--log", type=str, help="Input spike simulation log")
#     parser.add_argument("--csv", type=str, help="Output trace csv_buf file")
#     parser.add_argument("-v", "--verbose", dest="verbose", action="store_true",
#                         help="Verbose logging")
#     parser.set_defaults(verbose=False)
#     args = parser.parse_args()
#     setup_logging(args.verbose)
#     process_spike_sim_log(args.log, args.csv, full_trace=1)


# if __name__ == "__main__":
#     main()
