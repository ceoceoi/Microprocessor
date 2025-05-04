import csv
import glob
import os

def read_csv_to_dict(filename):
    data = {}
    with open(filename, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            pc = row.get("pc", None)
            if pc and pc != "N/A":
                data[pc] = row
    return data

def find_latest_out_dir(base_path):
    out_dirs = sorted(glob.glob(os.path.join(base_path, "out_*")), reverse=True)
    return out_dirs[0] if out_dirs else None

def compare_by_pc(spike_dict, core_dict, report_file):
    common_pcs = set(spike_dict.keys()) & set(core_dict.keys())
    mismatches = []
    matched = 0

    with open(report_file, 'w') as f:
        for pc in sorted(common_pcs):
            s = spike_dict[pc]
            c = core_dict[pc]

            instr_s = s.get("instr", "N/A")
            instr_c = c.get("instr", "N/A")
            rdval_s = s.get("rd_val", "N/A")
            rdval_c = c.get("rd_val", "N/A")

            if instr_s != instr_c or rdval_s != rdval_c:
                mismatches.append((pc, instr_s, instr_c, rdval_s, rdval_c))
                f.write(f"Mismatch at PC {pc}:\n")
                f.write(f"  spike -> instr: {instr_s}, rd_val: {rdval_s}\n")
                f.write(f"  core  -> instr: {instr_c}, rd_val: {rdval_c}\n")
                f.write("------\n")
            else:
                matched += 1

        total = len(common_pcs)
        f.write(f"\n[RESULT]: {matched} matched, {len(mismatches)} mismatch out of {total} instructions\n")

    print(f"\n[✓] PC-based comparison complete.")
    print(f"[✓] {matched} matched, {len(mismatches)} mismatch")
    print(f"[✓] Report saved to: {report_file}")

if __name__ == "__main__":
    base = "/home/Shahd_Abdulmohsan/core/riscv-dv"
    out_dir = find_latest_out_dir(base)

    if not out_dir:
        print("No output directory found!")
        exit(1)

    spike_file = os.path.join(out_dir, "spike.csv")
    core_file  = os.path.join(out_dir, "core.csv")
    report_file = os.path.join(out_dir, "mismatch_report.txt")

    spike_dict = read_csv_to_dict(spike_file)
    core_dict  = read_csv_to_dict(core_file)

    if not spike_dict or not core_dict:
        print("Trace files missing or empty.")
    else:
        compare_by_pc(spike_dict, core_dict, report_file)
