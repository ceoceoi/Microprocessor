import riscv_types::*;
module R4_Unit #(
    parameter addr_width = 5,
    parameter num_rds = 5
    ) (
    input exe_p_mux_bus_type fadd_sub_pipeline_signals_i,
    output exe_p_mux_bus_type fadd_sub_pipeline_signals_o,

    input logic clk,rst,en,
    input logic [num_rds-1 :0] clear, // "id_exe_main_bus" included as register
    input logic [31:0] a, b, c,
    input alu_t alu_ctrl,
    input logic p_signal,
    input logic [2:0]rm,
    output logic [31:0] result, 
    output logic p_out_signal
    // for clear logic
    , output logic [addr_width-1 : 0] uu_rd [0 : num_rds-1],
    output logic [num_rds-1 : 0]  uu_reg_write,
    output logic [num_rds-1 : 0]  uu_FP_reg_write
);

    // pipelined signals
    exe_p_mux_bus_type stages[1:0];
    logic [31:0]  result_temp, result_temp2;
    logic add_sub;
    
    logic [31:0] a_temp_pi, b_temp_pi, c_temp_pi, result_temp_pi;
    logic [2:0] rm_pi;
    logic add_sub_pi, p_pi_signal;
    alu_t alu_ctrl_pi;  // "alu_ctrl" as delayed signal
    
    localparam R4_top_stages = 2;   // stage[0] "fmul" unit used --- stage[1] "fadd_sub" unit used
    localparam fmul_stages = 2;  // input-stage and output-stage
    
    // for clear logic ...
    logic [addr_width-1 : 0] R4_fadd_uu_rd [0 : 1];  // fadd has 3 stages (2 pipeline registers)
    logic [1:0] R4_fadd_uu_reg_write;
    logic [1:0] R4_fadd_uu_FP_reg_write;
    
    assign uu_rd = {
        fadd_sub_pipeline_signals_i.rd,
        stages[0].rd,   // FMul
        stages[1].rd,   // between FMul and FAdd
        R4_fadd_uu_rd
    };
    assign uu_reg_write = {
        fadd_sub_pipeline_signals_i.reg_write,
        R4_fadd_uu_reg_write,
        stages[1].reg_write,   // between FMul and FAdd
        stages[0].reg_write    // FMul
    };
    assign uu_FP_reg_write = {
        R4_fadd_uu_FP_reg_write,
        stages[1].reg_write,   // between FMul and FAdd
        stages[0].reg_write,    // FMul
        fadd_sub_pipeline_signals_i.FP_reg_write
    };

    // calculation logic ...
    always@(*)begin 
        case(alu_ctrl)
            FMADD:begin 
                add_sub = 1'b0;
            end
            
            FMSUB:begin 
                add_sub = 1'b1;
            end 
            
            FNMADD:begin 
                add_sub = 1'b0;
            end   
            
            FNMSUB:begin 
                add_sub = 1'b1;
            end
            
            default: begin
                add_sub = 1'b0;  // FADD
            end   
        endcase
    end 
 
    logic P_O_signal;

    FP_final_Multiplier M1 (.a(a),  // its name was "FP_Multiplier"
        .b(b),
        .clk(clk),      // added
        .rst(rst),      // added
        .result(result_temp),
        .rm(rm),
        .fadd_sub_pipeline_signals_i(fadd_sub_pipeline_signals_i),
        .fadd_sub_pipeline_signals_o(stages[0]),
        .clear(clear[0]),
        .P_signal(p_signal),
        .P_O_signal(P_O_signal),
        .en(en)
    ); // takes 2 cycles
    

    always@(*)begin 
//        if(alu_ctrl == FNMADD || alu_ctrl == FNMSUB) begin 
        if(alu_ctrl_pi == FNMADD || alu_ctrl_pi == FNMSUB) begin 
            result_temp2 = {!result_temp[31], result_temp[30:0]};
        end else 
            result_temp2 = result_temp;
    end
    
    
    // delay input signals that "fadd_sub" uses but fmul doesn't ...
    // 3rd operand (input c) delayer
    n_bit_delayer #(
        .n($bits(c)),
        .delay(fmul_stages-1 + R4_top_stages-1) // exclude last stage (output stage)
    ) c_temp_pi_delayer (
        .clk(clk),
        .reset_n(rst),
        .wen(en),
        .clr(clear[1:0]),    // TODO: supposes to be last clear of fmul_unit
        .data_i(c),
        .data_o(c_temp_pi)
    );
    
    // "add_sub" control signal for fadd module
    n_bit_delayer #(
//        .n($bits(c)),
        .n(1),
        .delay(fmul_stages-1 + R4_top_stages-1) // exclude last R4_top_stage (output stage)
    ) add_sub_pi_delayer (
        .clk(clk),
        .reset_n(rst),
        .wen(en),
        .clr(clear[1:0]),    // TODO: supposes to be last clear of fmul_unit
        .data_i(add_sub),
        .data_o(add_sub_pi)
    );
    
    // "add_sub" control signal for fadd module
    n_bit_delayer #(
//        .n($bits(c)),
        .n(3),
        .delay(fmul_stages-1 + R4_top_stages-1) // exclude last R4_top_stage (output stage)
    ) rm_pi_delayer (
        .clk(clk),
        .reset_n(rst),
        .wen(en),
        .clr(clear[1:0]),    // TODO: supposes to be last clear of fmul_unit
        .data_i(rm),
        .data_o(rm_pi)
    );
    
    
    // single pipeline register between "fmul" and "fadd_sub" units
    always@(posedge clk ,negedge rst) begin
        if(!rst) begin
            result_temp_pi <= 0;
            p_pi_signal <= 0;
            stages[1] <= 0;
            alu_ctrl_pi <= ADD; // defualt value
        
        end else if (clear[1]) begin 
            result_temp_pi <= 0;
            p_pi_signal <= 0;
            stages[1] <= 'b0;
            alu_ctrl_pi <= ADD; // defualt value
        
        end else if (en) begin 
            result_temp_pi <= result_temp2;
            p_pi_signal <= P_O_signal;
            stages[1] <= stages[0];  // no needs
            alu_ctrl_pi <= alu_ctrl; // defualt value
        end 
    end


    
    logic p_add;

    FP_add_sub A1 (
        .clk(clk), 
        .rst(rst), 
        .en(en),
        .clear(clear[4:2]), // clear[1] duplicated
        .add_sub(add_sub_pi),
        .num1(result_temp_pi),
        .num2(c_temp_pi),
        .rm(rm_pi),
        .sum(result),  // sum
        
        .p_start(p_pi_signal),
        .p_result(p_add),
        .fadd_sub_pipeline_signals_i(stages[1]),
        .fadd_sub_pipeline_signals_o(fadd_sub_pipeline_signals_o)
        
        // for clear logic
        , .uu_rd(R4_fadd_uu_rd),
        .uu_reg_write(R4_fadd_uu_reg_write),
        .uu_FP_reg_write(R4_fadd_uu_FP_reg_write)
    );

    assign p_out_signal = p_add;

endmodule