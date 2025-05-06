##============================
# # Paths and configuration
# #============================
# DV_DIR         := /home/Shahd_Abdulmohsan/core/riscv-dv
# RTL_DIR        := $(DV_DIR)/new_need_verification/modules/rtl_team/rv32imf
# SIM_DIR        := $(RTL_DIR)/soc
# TB_DIR         := $(DV_DIR)/new_need_verification/testbench
# OUT_DATE       := $(shell date +%Y-%m-%d)
# OUT_DIR        := $(DV_DIR)/out_$(OUT_DATE)
# TEST_NAME      := riscv_jump_stress_test
# LINKER_SCRIPT  := $(DV_DIR)/scripts/link.ld
# TARGET         := rv32i

# #============================
# # Output files
# #============================
# RV_ELF         := $(OUT_DIR)/asm_test/$(TEST_NAME)_0.o
# INST_HEX       := $(OUT_DIR)/inst.hex
# DATA_HEX       := $(OUT_DIR)/data.hex
# INST_CONV_HEX  := $(OUT_DIR)/inst_conv.hex
# DATA_CONV_HEX  := $(OUT_DIR)/data_conv.hex
# SPIKE_LOG      := $(OUT_DIR)/spike_sim/$(TEST_NAME)_0.log
# CORE_LOG       := $(SIM_DIR)/trace_core_00000001.log
# SPIKE_CSV      := $(OUT_DIR)/spike.csv
# CORE_CSV       := $(OUT_DIR)/core.csv

# #============================
# # Tools
# #============================
# OBJCOPY        := riscv32-unknown-elf-objcopy
# CONVERT_HEX    := python3 $(DV_DIR)/scripts/convert_hex.py
# CORE_LOG_2_CSV := python3 $(DV_DIR)/scripts/core_log_to_trace_csv.py
# SPIKE_LOG_2_CSV:= python3 $(DV_DIR)/scripts/spike_log_to_trace_csv.py
# COMPARE        := python3 $(DV_DIR)/scripts/instr_trace_compare.py

# .PHONY: all all_cus clean dv_gen extract_hex convert_hex_files simv exec_sim compare only_compare

# #============================
# # Master targets
# #============================
# all: clean dv_gen extract_hex convert_hex_files simv exec_sim compare
# all_cus: custom_asmtest extract_hex convert_hex_files simv exec_sim compare

# #============================
# # Step 1: Generate the test
# #============================
# dv_gen:
# 	@echo "🚀 [1/6] Generating test via riscv-dv..."
# 	cd $(DV_DIR) && \
# 	python3 run.py --test $(TEST_NAME) --simulator vcs --target $(TARGET)

# custom_asmtest:
# 	cd $(DV_DIR) && \
# 	python3 run.py --asm_test asm_cus_tests/asm_custom_test.S

# #============================
# # Step 2: Extract hex from ELF
# #============================
# extract_hex: $(INST_HEX) $(DATA_HEX)

# $(INST_HEX): $(RV_ELF)
# 	@echo "📦 Extracting .text to $(INST_HEX)"
# 	$(OBJCOPY) -O verilog -j .text $(RV_ELF) $(INST_HEX)

# $(DATA_HEX): $(RV_ELF)
# 	@echo "📦 Extracting .data to $(DATA_HEX)"
# 	$(OBJCOPY) -O verilog -j .data $(RV_ELF) $(DATA_HEX)

# #============================
# # Step 3: Convert HEX
# #============================
# convert_hex_files: $(INST_HEX) $(DATA_HEX)
# 	@echo "🔄 Converting HEX files..."
# 	$(CONVERT_HEX) $(INST_HEX) $(INST_CONV_HEX)
# 	$(CONVERT_HEX) $(DATA_HEX) $(DATA_CONV_HEX)

# #============================
# # Step 4: Build simv
# #============================
# simv:
# 	@echo "🔧 Building RTL simulation binary..."
# 	vcs -full64 -f $(DV_DIR)/filelist.f -o $(SIM_DIR)/simv

# #============================
# # Step 5: Run simulation
# #============================
# exec_sim: $(INST_CONV_HEX) $(DATA_CONV_HEX) simv
# 	@echo "🎥 Running simulation..."
# 	cp $(INST_CONV_HEX) $(TB_DIR)/inst_formatted.hex
# 	cp $(DATA_CONV_HEX) $(TB_DIR)/data_formatted.hex
# 	cd $(SIM_DIR) && ./simv +tracer_file_base=trace_core

# #============================
# # Step 6: Trace compare
# #============================
# $(CORE_CSV): $(CORE_LOG)
# 	$(CORE_LOG_2_CSV) --log $(CORE_LOG) --csv $(CORE_CSV)

# $(SPIKE_CSV): $(SPIKE_LOG)
# 	$(SPIKE_LOG_2_CSV) --log $(SPIKE_LOG) --csv $(SPIKE_CSV)

# compare: $(SPIKE_CSV) $(CORE_CSV)
# 	@echo " Comparing traces..."
# 	sed -i '2d' $(SPIKE_CSV)
# 	sed -i '2d' $(CORE_CSV)
# 	$(COMPARE) --csv_file_1 $(SPIKE_CSV) --csv_file_2 $(CORE_CSV) --csv_name_1 spike --csv_name_2 core > compare_output.log
# 	cat compare_output.log

# only_compare:
# 	$(COMPARE) --csv_file_1 $(SPIKE_CSV) --csv_file_2 $(CORE_CSV) --csv_name_1 spike --csv_name_2 core > compare_output.log
# 	cat compare_output.log

# f:
# 	@echo "Analyzing full mismatches line-by-line..."
# 	python3 $(DV_DIR)/scripts/mismatch_checker_smart.py
# c:
# 	@echo "Removing mismatch report..."
# 	rm -f $(DV_DIR)/out_*/mismatch_report.txt


# #============================
# # Clean everything
# #============================
# clean:
# 	@echo "🧹 Cleaning outputs..."
# 	rm -rf $(OUT_DIR)
# 	rm -f $(SIM_DIR)/simv
# 	rm -rf $(SIM_DIR)/simv.daidir
# 	rm -f $(SIM_DIR)/trace_core_*.log
 







#============================
# Paths and configuration-nm
#============================
DV_DIR         := /home/Shahd_Abdulmohsan/core/riscv-dv
RTL_DIR        := $(DV_DIR)/new_need_verification/modules/rtl_team/rv32imf
SIM_DIR        := $(RTL_DIR)/soc
TB_DIR         := $(DV_DIR)/new_need_verification/testbench
OUT_DATE       := $(shell date +%Y-%m-%d)
OUT_DIR        := $(DV_DIR)/out_$(OUT_DATE)
TEST_NAME      := riscv_arithmetic_basic_test
LINKER_SCRIPT  := $(DV_DIR)/scripts/link.ld
TARGET         := rv32imafdc #rv32i

#============================
# Output files
#============================
RV_ELF         := $(OUT_DIR)/asm_test/$(TEST_NAME)_0.o
INST_HEX       := $(OUT_DIR)/inst.hex
DATA_HEX       := $(OUT_DIR)/data.hex
INST_CONV_HEX  := $(OUT_DIR)/inst_conv.hex
DATA_CONV_HEX  := $(OUT_DIR)/data_conv.hex
SPIKE_LOG      := $(OUT_DIR)/spike_sim/$(TEST_NAME)_0.log
CORE_LOG       := $(SIM_DIR)/trace_core_00000001.log
SPIKE_CSV      := $(OUT_DIR)/spike.csv
CORE_CSV       := $(OUT_DIR)/core.csv

#============================
# Tools
#============================
OBJCOPY        := riscv32-unknown-elf-objcopy
CONVERT_HEX    := python3 $(DV_DIR)/scripts/convert_hex.py
CORE_LOG_2_CSV := python3 $(DV_DIR)/scripts/core_log_to_trace_csv.py
SPIKE_LOG_2_CSV:= python3 $(DV_DIR)/scripts/spike_log_to_trace_csv.py
COMPARE        := python3 $(DV_DIR)/scripts/instr_trace_compare.py

.PHONY: all all_cus clean dv_gen extract_hex convert_hex_files simv exec_sim compare only_compare

#============================
# Master targets
#============================
all: clean dv_gen extract_hex convert_hex_files simv exec_sim compare
all_cus: custom_asmtest extract_hex convert_hex_files simv exec_sim compare

#============================
# Step 1: Generate the test
#============================
dv_gen:
	@echo "🚀 [1/6] Generating test via riscv-dv..."
	cd $(DV_DIR) && \
	python3 run.py --test $(TEST_NAME) --simulator vcs --target $(TARGET)

custom_asmtest:
	cd $(DV_DIR) && \
	python3 run.py --asm_test asm_cus_tests/asm_custom_test.S

#============================
# Step 2: Extract hex from ELF
#============================
extract_hex: $(INST_HEX) $(DATA_HEX)

$(INST_HEX): $(RV_ELF)
	@echo "📦 Extracting .text to $(INST_HEX)"
	$(OBJCOPY) -O verilog -j .text $(RV_ELF) $(INST_HEX)

$(DATA_HEX): $(RV_ELF)
	@echo "📦 Extracting .data to $(DATA_HEX)"
	$(OBJCOPY) -O verilog -j .data $(RV_ELF) $(DATA_HEX)

#============================
# Step 3: Convert HEX
#============================
convert_hex_files: $(INST_HEX) $(DATA_HEX)
	@echo "🔄 Converting HEX files..."
	$(CONVERT_HEX) $(INST_HEX) $(INST_CONV_HEX)
	$(CONVERT_HEX) $(DATA_HEX) $(DATA_CONV_HEX)

#============================
# Step 4: Build simv
#============================
simv:
	@echo "🔧 Building RTL simulation binary..."
	vcs -full64 -f $(DV_DIR)/filelist.f -o $(SIM_DIR)/simv

#============================
# Step 5: Run simulation
#============================
exec_sim: $(INST_CONV_HEX) $(DATA_CONV_HEX) simv
	@echo "🎥 Running simulation..."
	cp $(INST_CONV_HEX) $(TB_DIR)/inst_formatted.hex
	cp $(DATA_CONV_HEX) $(TB_DIR)/data_formatted.hex
	cd $(SIM_DIR) && ./simv +tracer_file_base=trace_core

#============================
# Step 6: Trace compare
#============================
$(CORE_CSV): $(CORE_LOG)
	$(CORE_LOG_2_CSV) --log $(CORE_LOG) --csv $(CORE_CSV)

$(SPIKE_CSV): $(SPIKE_LOG)
	$(SPIKE_LOG_2_CSV) --log $(SPIKE_LOG) --csv $(SPIKE_CSV)

compare: $(SPIKE_CSV) $(CORE_CSV)
	@echo " Comparing traces..."
	sed -i '2d' $(SPIKE_CSV)
	sed -i '2d' $(CORE_CSV)
	$(COMPARE) --csv_file_1 $(SPIKE_CSV) --csv_file_2 $(CORE_CSV) --csv_name_1 spike --csv_name_2 core > compare_output.log
	cat compare_output.log

only_compare:
	$(COMPARE) --csv_file_1 $(SPIKE_CSV) --csv_file_2 $(CORE_CSV) --csv_name_1 spike --csv_name_2 core > compare_output.log
	cat compare_output.log

f:
	@echo "Analyzing full mismatches line-by-line..."
	python3 $(DV_DIR)/scripts/mismatch_checker_smart.py
c:
	@echo "Removing mismatch report..."
	rm -f $(DV_DIR)/out_*/mismatch_report.txt


#============================
# Clean everything
#============================
clean:
	@echo "🧹 Cleaning outputs..."
	rm -rf $(OUT_DIR)
	rm -f $(SIM_DIR)/simv
	rm -rf $(SIM_DIR)/simv.daidir
	rm -f $(SIM_DIR)/trace_core_*.log
