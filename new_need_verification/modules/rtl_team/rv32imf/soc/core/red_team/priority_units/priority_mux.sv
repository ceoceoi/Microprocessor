import riscv_types::*;

module priority_mux #(
    parameter PIPELINE_WIDTH = 151
)(
    input priority_t p_sel,

    // ARITHMITIC UNITS SIGNALS
    // ALU
    input logic [31:0] alu_result,
    input exe_p_mux_bus_type   alu_pipeline_signals,

    // FPU
    input logic [31:0] fpu_result,
    input exe_p_mux_bus_type   fpu_pipeline_signals,

    // MULTIPLICATION UNIT
    input logic [31:0] mul_result,
    input exe_p_mux_bus_type   mul_pipeline_signals,

    // DIVISION UNIT
    input logic [31:0] div_result,
    input exe_p_mux_bus_type   div_pipeline_signals,

    // FLOATING POINT MULTIPLICATION
    input logic [31:0] fmul_result,
    input exe_p_mux_bus_type   fmul_pipeline_signals,

    // FLOATING POINT DIVISION 
    input logic [31:0] fdiv_result,
    input exe_p_mux_bus_type   fdiv_pipeline_signals,

    // FLOATING POINT ADDITION/SUBTRACTION
    input logic [31:0] fadd_sub_result,
    input exe_p_mux_bus_type   fadd_sub_pipeline_signals,
    
    // FLOATING POINT SQUARE ROOT (Fsqrt)
    input logic [31:0] fsqrt_result,
    input exe_p_mux_bus_type  fsqrt_pipeline_signals,
    
    // FLOATING POINT R4 (FP_R4)
    input logic [31:0] R4_result,
    input exe_p_mux_bus_type  R4_pipeline_signals,
    
    // outputs ...
    output logic [31:0] p_result,
    output exe_p_mux_bus_type   p_pipeline_signals
);
    
    always_comb begin
        case(p_sel)
            FDIV_unit: begin
                p_result = fdiv_result;
                p_pipeline_signals = fdiv_pipeline_signals;
            end
            FMUL_unit: begin
                p_result = fmul_result;
                p_pipeline_signals = fmul_pipeline_signals;
            end
            FADD_SUB_unit: begin
                p_result = fadd_sub_result;
                p_pipeline_signals = fadd_sub_pipeline_signals;
            end
            DIV_unit: begin
                p_result = div_result;
                p_pipeline_signals = div_pipeline_signals;
            end
            MUL_unit: begin
                p_result = mul_result;
                p_pipeline_signals = mul_pipeline_signals;
            end
            FP_unit: begin
                p_result = fpu_result;
                p_pipeline_signals = fpu_pipeline_signals;
            end
            ALU_unit: begin
                p_result = alu_result;
                p_pipeline_signals = alu_pipeline_signals;
            end
            FSQRT_unit: begin
                p_result = fsqrt_result;
                p_pipeline_signals = fsqrt_pipeline_signals;
            end
            R4_unit: begin
                p_result = R4_result;
                p_pipeline_signals = R4_pipeline_signals;
            end
            
            // signals if she need it
            DEFAULT_unit: begin     // actually, it's"DEFAULT" but as enum value
                p_result = 'b0;  // nop result
                p_pipeline_signals = {{PIPELINE_WIDTH-12{1'b0}}, 12'h208};  // nop pipeline_signals
            end
            default: begin      // NOP instruction not ALU
                p_result = 'b0;  // nop result
                p_pipeline_signals = {{PIPELINE_WIDTH-12{1'b0}}, 12'h208};  // nop pipeline_signals
                
                /* NOTE:                pc_plus_4      ,        pc_jump     ,     zeros ,   reg_wriete, zero_flag
                -- bus_o = {temp_bus.pc_plus_4, temp_bus.pc_jump, {77{1'b0}},  2'b10, 8'h08}
                -- bus_o = {temp_bus.pc_plus_4, temp_bus.pc_jump, {75{1'b0}}, 12'h208}
                
                   we can represent NOP instruction using one of these 2 lines above, which only sets
                "reg_write" and "zero_flag" as 1 and others as zeros.
                   regard to "pc+plus_4" and "pc_jump", their values don't matter since NOP instruction
                doesn't have "branch" or "jump" signals.
                */
            end
        endcase
    end
endmodule