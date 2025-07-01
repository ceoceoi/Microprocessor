// ============== Physical's Macros ==============
//+define+PD_BUILD
//+define+USE_SRAM
// - ./pads.sv


// ============== RTL's Macros ==============
//- ./soc/core/data_mem.sv
// +define+DV_DEBUG


// ============== Verification's Macros ==============
+define+DV
+define+TRACER_ENABLE
+define+DV_DEBUG
//+define+USE_RS3
+define+NO_WAW
+define+LINEAR_SYSTEM
//+define+VCS
//+define+VCS_SIM -> maybe soc_verif + PD


//+define+tracer // replaced by "DV"
//+define+JTAG
//+define+JTAG_verf
//+define+dump_wave
//+define+dump_mem
// +define+PD_BUILD

// ========= all macros =========
// what are these macros??
//+define+VIVADO_BUILD  // JTAG on FPGA
//+define+GPIO_STRICT_32BIT_ACCESS
//+define+GPIO_AUX_IMPLEMENT
//+define+GPIO_CLKPAD
//+define+WAVES
//+define+PTC_IMPLEMENTED
//+define+PTC_RPTC_CNTR
//+define+PTC_RPTC_HRC
//+define+PTC_RPTC_LRC
//+define+PTC_RPTC_CTRL
//+define+PTC_FULL_DECODE
//+define+PTC_STRICT_32BIT_ACCESS
//+define+PTC_READREGS
//+define+UART_HAS_BAUDRATE_OUTPUT
//+define+PRESCALER_PRESET_HARD
//+define+ViDBo
//+define+USE_SRAM
//+define+VCS_SIM    
//+define+dump_mem
//+define+USE_RS3
//+define+DV
//+define+TRACER_ENABLE

// ./modules/tracer_modules/Tracer/pkg.sv
// ./modules/tracer_modules/Tracer/tracer_pkg.sv

// ============== Debugging Macros ==============
//+define+dump_mem



//  TODO: check why verif needs "tracer", "debug", and "VCS_SIM" ???
// ============= new_need filelist, please merge them ... ====================
# Filelist for VCS simulation

# Compilation Flags
-timescale=1ns/10ps
-sverilog

+define+VCS_SIM
+define+tracer
+define+TRACER_ENABLE
+define+debug

# ============================
# Tracer Files & Packages
# ============================
+incdir+RV32_SoC/modules/rtl_team/rv32imf/soc/rom
+incdir+RV32_SoC/modules/rtl_team/rv32imf/soc/sram
+incdir+RV32_SoC/modules/rtl_team/rv32imf/pads/tpz018nv_270a
+incdir+RV32_SoC/modules/tracer_modules/Tracer/
//+incdir+RV32_SoC/testbench  // simJTAG

RV32_SoC/modules/rtl_team/rv32imf/soc/core/lib.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/glbl.v

RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/debug/debug_pkg.sv


# ============================
# Core Files
# ============================
RV32_SoC/modules/rtl_team/rv32imf/soc/core/core_dbg_fsm.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/linearization.sv
RV32_SoC/modules/tracer_modules/rvfi_tracker_delay.sv

RV32_SoC/modules/rtl_team/rv32imf/soc/core/alignment_units.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/alu_control.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/alu.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/branch_controller.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/control_unit.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/data_mem.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/data_path.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/forwarding_unit.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/hazard_controller.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/imm_gen.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/main_control.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/pipeline_controller.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/program_counter.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/reg_file.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/rom.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/rv32i_top.sv

# ============================
# M-Extension Files
# ============================
RV32_SoC/modules/rtl_team/rv32imf/soc/core/red_team/int_units/int_div_rem.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/red_team/int_units/int_mul.sv
// RV32_SoC/modules/rtl_team/rv32imf/soc/core/red_team/int_units/mul_unit.sv // Qamar
RV32_SoC/modules/rtl_team/rv32imf/soc/core/red_team/priority_units/priority_controller.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/red_team/priority_units/priority_mux.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/red_team/priority_units/P_Decoder.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/red_team/FP_units/FP_final_multiplier.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/red_team/FP_units/R4_unit.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/red_team/FP_units/fdiv.sv

# ============================
# F-Extension Files
# ============================
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fpu_units/fpu.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fadd_sub_modules/FP_add_sub_top.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fadd_sub_modules/add_sub_FP.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fadd_sub_modules/extract_align_FP.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fadd_sub_modules/normalize_FP.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fadd_sub_modules/round_FP.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/block_sqrt/fp_sqrt_Multicycle.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/block_sqrt/Register.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fpu_units/fcvt/float2int.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fpu_units/fcvt/float2ints.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fpu_units/fcvt/int2float.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fpu_units/fcvt/int2floats.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/fpu_units/fcvt/FP_converter.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/raw_waw_units/FP_busy_registers.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/raw_waw_units/busy_registers.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/raw_waw_units/clear_units_decoder.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/raw_waw_units/n_bit_delayer.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/core/green_team/raw_waw_units/value_capture.sv

# ============================
# Peripheral Files ...
# ============================
# ============================
# Debug Files
# ============================
// RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/debug/bscan_tap.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/debug/debug_top.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/debug/dm.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/debug/dtm.sv

# ============================
# I2C Files
# ============================
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/i2c/rtl/i2c_master_defines.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/i2c/bench/verilog/spi_slave_model.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/i2c/bench/verilog/i2c_slave_model.v
//RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/i2c/bench/verilog/tst_bench_top.v
//RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/i2c/bench/verilog/wb_master_model.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/i2c/rtl/i2c_master_bit_ctrl.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/i2c/rtl/i2c_master_byte_ctrl.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/i2c/rtl/i2c_master_top.v

# ============================
# PTC Files
# ============================
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/ptc/ptc_defines.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/ptc/ptc_top.v

# ============================
# SPI & SPI-Flash Files
# ============================
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/spi/fifo4.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/spi/simple_spi_top.v

# ============================
# UART Files
# ============================
+incdir+RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart

RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart/raminfr.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart/uart_defines.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart/uart_receiver.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart/uart_regs.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart/uart_rfifo.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart/uart_sync_flops.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart/uart_tfifo.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart/uart_top.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart/uart_transmitter.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/uart/uart_wb.v

# ============================
# GPIO Files
# ============================
+incdir+RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/gpio
// RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/gpio/bidirec.sv  // deleted
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/gpio/gpio_defines.v
RV32_SoC/modules/rtl_team/rv32imf/soc/uncore/gpio/gpio_top.sv

# ============================
# Wishbone Files
# ============================
RV32_SoC/modules/rtl_team/rv32imf/soc/WishboneInterconnect/wb_intercon_1.2.2-r1/wb_mux.v
RV32_SoC/modules/rtl_team/rv32imf/soc/WishboneInterconnect/wb_intercon.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/WishboneInterconnect/wishbone_controller.sv

# ============================
# TSMC Files
# ============================


# ============================
# SoC Files
# ============================
+incdir+RV32_SoC/modules/rtl_team/rv32imf/soc
// RV32_SoC/modules/rtl_team/rv32imf/soc/sram_wrappers.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/dump_mem.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/io_mux.sv
RV32_SoC/modules/rtl_team/rv32imf/soc/rv32i_soc.sv

# ============================
# I/O Pads & FPGA Files
# ============================
// RV32_SoC/modules/rtl_team/rv32imf/pads.sv
// RV32_SoC/modules/rtl_team/rv32imf/soc/rv32i_soc_fpga_top.sv

# ============================
# Testbench Files
# ============================
RV32_SoC/modules/tracer_modules/Tracer/pkg.sv
RV32_SoC/modules/tracer_modules/Tracer/tracer_pkg.sv
RV32_SoC/modules/tracer_modules/Tracer/tracer.sv
RV32_SoC/testbench/tracer_rv32i_soc_tb.sv
//RV32_SoC/testbench/rv32i_tb.sv
//RV32_SoC/testbench/rv32i_soc_tb.sv
//RV32_SoC/testbench/rv32i_soc_jtag_tb.sv



