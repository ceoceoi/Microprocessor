/* prioirity now ...
 p_signal [8] alu     (single-cycle)
 p_signal [7] fpu     (single-cycle)
 p_signal [6] mul     (single-cycle).
p_signal [5] f_add_sub     (pipeline)
p_signal [4] f_mul     (pipeline)
p_signal [3] R4     (pipeline) -> it has 2 cycles
p_signal [2] f_div     (multi-cycle)
p_signal [1] div     (multi-cycle)
p_signal [0]  fsqrt     (multi-cycle)
*/


`timescale 1ns / 1ps
import riscv_types::*;

module P_Decoder (
    input alu_t alu_ctrl,
    input logic rd_busy,
    output logic [8:0] P_signal_start
);

logic [8:0] P_signal_start_temp;

// "don't generate p_signal_start if there is a data-dependecy that causes stall the system"
assign P_signal_start = P_signal_start_temp; // & {9{~rd_busy}};

always @(alu_ctrl) begin
    if (alu_ctrl==ADD|| alu_ctrl==SUB || alu_ctrl==SLL || alu_ctrl==SLT ||alu_ctrl==SLTU
    || alu_ctrl==XOR || alu_ctrl==SRL || alu_ctrl==SRA || alu_ctrl==AND || alu_ctrl==OR)
        P_signal_start_temp = 9'b100000000;      // ALU
        // NOTE: instrucitons FLW and FSW are also included here since they are using ALU to get the desired address in DMEM
    
    // FP_unit instructions ...
    else if (alu_ctrl==FCVTW  || alu_ctrl==FCVTWU || alu_ctrl==FCVTSW || alu_ctrl==FCVTSWU
                || alu_ctrl==FMVXW || alu_ctrl==FCLASS || alu_ctrl==FMVWX
                || alu_ctrl==FSGNJ || alu_ctrl==FSGNJN|| alu_ctrl==FSGNJX
                || alu_ctrl==FLE || alu_ctrl==FEQ || alu_ctrl==FLT
                || alu_ctrl==FMIN || alu_ctrl==FMAX)
        P_signal_start_temp = 9'b010000000;      // FPU
    
    else if (alu_ctrl==MUL || alu_ctrl==MULH || alu_ctrl==MULHSU || alu_ctrl==MULHU)
        P_signal_start_temp = 9'b001000000;      // MUL_unit
    
    else if (alu_ctrl==FADD || alu_ctrl==FSUB)
        P_signal_start_temp = 9'b000100000;     // FADD_SUB_unit
            
    else if (alu_ctrl==FMUL)
        P_signal_start_temp = 9'b000010000;      // FMUL_unit

    else if (alu_ctrl==FMADD || alu_ctrl==FMSUB || alu_ctrl==FNMADD || alu_ctrl==FNMSUB )
        P_signal_start_temp = 9'b000001000;      // R4_unit

    else if (alu_ctrl==FDIV)
        P_signal_start_temp = 9'b000000100;      // FDIV_unit
        
    else if (alu_ctrl==DIV || alu_ctrl==DIVU || alu_ctrl==REM || alu_ctrl==REMU)
        P_signal_start_temp = 9'b000000010;      // DIV_unit
    
    else if (alu_ctrl==FSQRT)
        P_signal_start_temp = 9'b000000001;      // FSQRT_unit
        
    else
        P_signal_start_temp = 9'b000000000;      // DEFAULT (don't use any unit)
    end

endmodule
