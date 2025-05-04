`timescale 1ns / 1ps

// NOTE: other modules defined in "busy_registers.sv" file
// ===================== Top modules (main) ============================
// Top Module: Generates Many Flip-Flops for Registers
module FP_busy_registers #(
    parameter num_rds = 3,
    parameter total_regs = 32  // number of registers in reg_file
) (
    input logic clk,
    input logic reset_n,
    input logic forward_flag,  // not used
    input logic [1:0] forward_rd1_exe,  // (new) width modified
    input logic [1:0] forward_rd2_exe,  // (new) width modified
    input logic reg_write_id,   // means "the instruction in ID/EXE register will write on int_reg_file later"
    input logic FP_reg_write_id,   // means "the instruction in ID/EXE register will write on FP_reg_file later"
    input logic FP_reg_write_p_mux,
    input logic [$clog2(total_regs)-1 : 0] waddr_wb,   // Address of rd from write-back stage
    input logic [$clog2(total_regs)-1 : 0] waddr_id,   // Address of rd from decode stage
    input logic [$clog2(total_regs)-1 : 0] rs1,
    input logic [$clog2(total_regs)-1 : 0] rs2,
    input logic [$clog2(total_regs)-1 : 0] rs3,
    input logic [1:0] forward_rd3_exe,
    input logic is_R4_instruction,
    
    output logic FP_rd_busy,
    // (new) for clear logic
    input logic [$clog2(total_regs)-1 : 0] all_uu_FP_rd [0 : num_rds-1],
    output logic [num_rds-1 :0] all_uu_FP_rd_busy,
    output logic no_FP_dependency   // (new)

);

    // Logic for tracking busy state of each register in reg-file
    logic [total_regs-1:0] rd_busy_reg;  // A vector of flip-flops
    logic no_dependency;
    logic rs3_not_busy ;  // (new)
    assign rs3_not_busy = is_R4_instruction? rd_busy_reg[rs3]=='b0 : 1'b1;  // (new)
    
    // check if there's no dependency (f0 included)
    assign no_dependency = (rd_busy_reg[rs1] == 0 && rd_busy_reg[rs2] == 0 && rs3_not_busy); // rd_busy_reg[rs3] == 0);
    assign no_FP_dependency = no_dependency;   // (new)
    
    // generate clear signals for each flip-flop
    logic [31:0] clr_flip_flop;
    n_bits_decoder # (
        .n(5)
    ) clear_generator (
    .in(waddr_wb),
    .out(clr_flip_flop)
    );
    
    // generate clear signals for each flip-flop
    logic [31:0] en_flip_flop;
    n_bits_decoder # (
        .n(5)
    ) enable_generator (
    .in(waddr_id),
    .out(en_flip_flop)
    );

    
    // Generate seperated flip-flops for each register (starting from 1 to avoid x0)
    generate
        genvar i;
        for (i = 0; i < total_regs; i = i + 1) begin : gen_flip_flops
            // Instantiatiate many a D flip-flops
            d_flip_flop_wclr ff (
                .clk(clk),
                .reset_n(reset_n),
                .en(no_dependency & FP_reg_write_id & en_flip_flop[i]),         // Write on that flip-flop only if there isn't any data-dependency
                .clear_n(clr_flip_flop[i] & FP_reg_write_p_mux),     // Clear busy flag of that register has been written on
                .d(1'b1),                  // Set busy-flag as 1 if the instruction in ID-stage needs to write
                .q(rd_busy_reg[i])              // Output of each flip-flop
            );
        end
    endgenerate

    // Output
    logic rd_is_FP, rd_busy;
    assign rd_is_FP = ~reg_write_id & FP_reg_write_id;
    assign rd_busy = (rd_busy_reg[rs1] && ~(|forward_rd1_exe))
                                    | (rd_busy_reg[rs2] && ~(|forward_rd2_exe))
                                    | (rd_busy_reg[rs3] && ~(|forward_rd3_exe));
    
    assign FP_rd_busy = rd_busy & rd_is_FP;
    
    // check if that uu_rd really used or not
    always_comb begin
        for(int i=0; i<=num_rds-1; i++) begin 
            all_uu_FP_rd_busy[i] = rd_busy_reg[all_uu_FP_rd[i]];
        end
    end

endmodule
