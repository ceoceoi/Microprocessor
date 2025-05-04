`timescale 1ns / 1ps

module value_capture #(
    parameter n = 32,
    parameter FP_type = 0
    ) (
    input logic clk,
    input logic reset_n,
    input logic rd_not_busy,    // from "busy_reg" which indicates if system stalled cause of data dependency
    input logic [n-1:0] result_mem,          // forwarded data from MEM stage
    input logic [n-1:0] reg_wdata_wb,     // forwarded data data WB stage
    input logic [1:0] forward_rd1_exe,            // forwarding_mux_a selector
    input logic [1:0] forward_rd2_exe,            // forwarding_mux_b selector
    input logic [1:0] forward_rd3_exe,            // forwarding_mux_c selector
    input logic no_dependency, 
    input logic no_collision,  
    
    // outputs (forwarding values) ...
    output logic [n-1:0] captured_1_result_mem,
    output logic [n-1:0] captured_1_reg_wdata_wb,
    output logic [1:0] captured_1_forward_rd1_exe,
    
    output logic [n-1:0] captured_2_result_mem,
    output logic [n-1:0] captured_2_reg_wdata_wb,
    output logic [1:0] captured_2_forward_rd2_exe
    
    , output logic [n-1:0] captured_3_result_mem,
    output logic [n-1:0] captured_3_reg_wdata_wb,  
    output logic [1:0] captured_3_forward_rd3_exe
    );

    // internal signals ...
    // some enable signals
    logic rs1_frw_flag_exe;     // does rs1 need the captured forwarded value?
    logic rs2_frw_flag_exe;     // does rs2 need the captured forwarded value?
    assign rs1_frw_flag_exe =  (|forward_rd1_exe);  // 2 bits -> {MEM, WB}
    assign rs2_frw_flag_exe =  (|forward_rd2_exe);  // 2 bits -> {MEM, WB}
    logic rs3_frw_flag_exe;     // does rs3 need the captured forwarded value?
    assign rs3_frw_flag_exe =  (|forward_rd3_exe);  // 2 bits -> {MEM, WB}
    
    
    // registers to capture forwarding signals (copies stored)
    logic [n-1:0] cap_result_1_mem;   // rs1 = forward_mem
    logic [n-1:0] cap_data_1_wb;         // rs1 = forward_wb
    logic [1:0] cap_mux_a_sel;
    
    logic [n-1:0] cap_result_2_mem;  // rs2 = forward_mem
    logic [n-1:0] cap_data_2_wb;        // rs2 = forward_wb
    logic [1:0] cap_mux_b_sel;
    
    logic [n-1:0] cap_result_3_mem;  // rs3 = forward_mem
    logic [n-1:0] cap_data_3_wb;        // rs3 = forward_wb
    logic [1:0] cap_mux_c_sel;

    
    // ========= Registers to capture signals  =========
    logic capture_next1;  // don't capture next cycle
    logic capture_next2;
    logic capture_next3;
    
    logic stall_occurred;
    // Separate signals to avoid universal capture for rs1, rs2, and rs3
    logic stall_occurred_rs1_ff, stall_occurred_rs2_ff, stall_occurred_rs3_ff;
    
    assign stall_occurred = (~(no_dependency & no_collision));
    assign capture_next1 = stall_occurred_rs1_ff;
    assign capture_next2 = stall_occurred_rs2_ff;
    assign capture_next3 = stall_occurred_rs3_ff;
    
    always_ff @(posedge clk, negedge reset_n) begin
        if (!reset_n) begin
            stall_occurred_rs1_ff <= 1'b0;
            stall_occurred_rs2_ff <= 1'b0;
            stall_occurred_rs3_ff <= 1'b0;
        end else begin
            if (stall_occurred) begin
                stall_occurred_rs1_ff <= stall_occurred_rs1_ff | rs1_frw_flag_exe;
                stall_occurred_rs2_ff <= stall_occurred_rs2_ff | rs2_frw_flag_exe;
                stall_occurred_rs3_ff <= stall_occurred_rs3_ff | rs3_frw_flag_exe;
            end else  begin
                stall_occurred_rs1_ff <= 1'b0;
                stall_occurred_rs2_ff <= 1'b0;
                stall_occurred_rs3_ff <= 1'b0;
            end
        end
    end
    
    
    // capture MEM_forwarded value (rs1)
    n_bit_reg #(
        .n (32)
    ) captured_frw1_mem_reg ( .*,
        .wen(~capture_next1),
        .data_i(result_mem),
        .data_o(cap_result_1_mem)
    );
    // capture WB_forwarded value (rs1)
    n_bit_reg #(
        .n (32)
    ) captured_frw1_wb_reg ( .*,
        .wen(~capture_next1),
        .data_i(reg_wdata_wb),
        .data_o(cap_data_1_wb)
    );
    
    
    // capture MEM_forwarded value (rs2)
    n_bit_reg #(
        .n (32)
    ) captured_frw2_mem_reg ( .*,
        .wen(~capture_next2), 
        .data_i(result_mem),
        .data_o(cap_result_2_mem)
    );
    // capture WB_forwarded value (rs2)
    n_bit_reg #(
        .n (32)
    ) captured_frw2_wb_reg ( .*,
        .wen(~capture_next2), 
        .data_i(reg_wdata_wb),
        .data_o(cap_data_2_wb)
    );
    
    
    // capture MEM_forwarded value (rs3)
    n_bit_reg #(
        .n (32)
    ) captured_frw3_mem_reg ( .*,
        .wen(~capture_next3), 
        .data_i(result_mem),
        .data_o(cap_result_3_mem)
    );
    // capture WB_forwarded value (rs3)
    n_bit_reg #(
        .n (32)
    ) captured_frw3_wb_reg ( .*,
        .wen(~capture_next3), 
        .data_i(reg_wdata_wb),
        .data_o(cap_data_3_wb)
    );

    
    // ========= capture selectors of Mux a and b =========
    // rs1 --> capture the selector of "forwarding_mux_a" (WB stage)
        n_bit_reg #(
        .n (2)
    ) mux_a_sel ( .*,
        .wen(~capture_next1), 
        .data_i(forward_rd1_exe),
        .data_o(cap_mux_a_sel)
    );
    
    // rs2 --> capture the selector of "forwarding_mux_b" (WB stage)
    n_bit_reg #(
        .n (2)
    ) mux_b_sel ( .*,
        .wen(~capture_next2), 
        .data_i(forward_rd2_exe),
        .data_o(cap_mux_b_sel)
    );
    
    // rs3 --> capture the selector of "forwarding_mux_b" (WB stage)
    n_bit_reg #(
        .n (2)
    ) mux_c_sel ( .*,
        .wen(~capture_next3),
        .data_i(forward_rd3_exe),
        .data_o(cap_mux_c_sel)
    );

    // ========= Outputs logic =========
    // MUXes decide if we should use the last captured value (before being busy), or use the normal forwarded value

    // rs1
    assign captured_1_result_mem = capture_next1 ? cap_result_1_mem : result_mem;
    assign captured_1_reg_wdata_wb = capture_next1 ? cap_data_1_wb : reg_wdata_wb;
    assign captured_1_forward_rd1_exe = capture_next1 ? cap_mux_a_sel : forward_rd1_exe;

    // rs2
    assign captured_2_result_mem = capture_next2 ? cap_result_2_mem : result_mem;
    assign captured_2_reg_wdata_wb = capture_next2 ? cap_data_2_wb : reg_wdata_wb;
    assign captured_2_forward_rd2_exe = capture_next2 ? cap_mux_b_sel : forward_rd2_exe;
    
    // rs3
    assign captured_3_result_mem = capture_next3 ? cap_result_3_mem : result_mem;
    assign captured_3_reg_wdata_wb = capture_next3 ? cap_data_3_wb : reg_wdata_wb;
    assign captured_3_forward_rd3_exe = capture_next3 ? cap_mux_c_sel : forward_rd3_exe;
        
endmodule