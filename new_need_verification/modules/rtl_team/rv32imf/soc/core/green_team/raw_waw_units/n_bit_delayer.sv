`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/10/2025 07:52:17 AM
// Design Name: 
// Module Name: n_bit_delayer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
import riscv_types::*;


module n_bit_delayer #(parameter n=2, parameter delay=3)(
    input clk,
    input wen,
    input [delay-1:0]clr,
    input reset_n,
    input [n-1:0] data_i,
    output logic [n-1:0] data_o
    

    );
    
   logic [n-1:0] d_delay[delay-2:0]; 
 
 
 
 genvar i ;
    generate 
    
    for(i=0;i<delay;i=i+1) begin 
        
        if(i==0)begin
        
              n_bit_reg_wclr #(
                .n            (n),
                .RESET_VALUE  (0),
                .CLR_VALUE    (0)
            ) reg_first(
                .clk        (clk),
                .reset_n    (reset_n),
                .wen        (wen),
                .data_i     (data_i),
                .data_o     (d_delay[0]),
                .clear      (clr[0])
            );   
           
        end
        
        else if(i==delay-1) begin
              n_bit_reg_wclr #(
                .n            (n),
                .RESET_VALUE  (0),
                .CLR_VALUE    (0)
            ) reg_last(
                .clk        (clk),
                .reset_n    (reset_n),
                .wen        (wen),
                .data_i     (d_delay[i-1]),
                .data_o     (data_o),
                .clear      (clr[i])
            );          
        end
        
        else begin
             n_bit_reg_wclr #(
                .n            (n),
                .RESET_VALUE  (0),
                .CLR_VALUE    (0)
            ) regs(
                .clk        (clk),
                .reset_n    (reset_n),
                .wen        (wen),
                .data_i     (d_delay[i-1]),
                .data_o     (d_delay[i]),
                .clear      (clr[i])
            );  
        end
        
    end
    
    endgenerate 
    
endmodule



// n_bit_delayer with rds
module n_bit_delayer_pipeline_signals #(
    parameter n=2,
    parameter delay=3,
    parameter rd_addr_size=5
    ) (
    input clk,
    input wen,
    input [delay-1:0]clr,
    input reset_n,
    input exe_p_mux_bus_type   pipeline_i,
    output exe_p_mux_bus_type   pipeline_o,
    // for clear logic in pipelined units
    output logic [rd_addr_size-1 : 0] uu_rds [0 : delay-1],
    output logic [delay-1 : 0] uu_reg_write,
    output logic [delay-1 : 0] uu_FP_reg_write
    );
    
    exe_p_mux_bus_type pipe_delay [0:delay-2];  //-2 with input 
                
    genvar i;
    generate
        for(i=0;i<delay;i=i+1) begin 
            if(i==0)begin
                n_bit_reg_wclr #(
                    .n            ($bits(pipeline_i)),
                    .RESET_VALUE  (0),
                    .CLR_VALUE    (0)
                    ) reg_first(
                    .clk        (clk),
                    .reset_n    (reset_n),
                    .wen        (wen),
                    .data_i     (pipeline_i),
                    .data_o     (pipe_delay[0]),
                    .clear      (clr[0])
                );
                assign uu_rds[0] = pipeline_i.rd;
                assign uu_reg_write[0] = pipeline_i.reg_write;
                assign uu_FP_reg_write[0] = pipeline_i.FP_reg_write;
            end
            
            else if(i==delay-1) begin
                n_bit_reg_wclr #(
                    .n            ($bits(pipeline_i)),
                    .RESET_VALUE  (0),
                    .CLR_VALUE    (0)
                    ) reg_last(
                    .clk        (clk),
                    .reset_n    (reset_n),
                    .wen        (wen),
                    .data_i     (pipe_delay[i-1]),
                    .data_o     (pipeline_o),
                    .clear      (clr[i])
                );
                assign uu_rds[i] = pipe_delay[i-1].rd;
                assign uu_reg_write[i] = pipe_delay[i-1].reg_write;
                assign uu_FP_reg_write[i] = pipe_delay[i-1].FP_reg_write;
            end
            
            else begin
                n_bit_reg_wclr #(
                    .n            ($bits(pipeline_i)),
                    .RESET_VALUE  (0),
                    .CLR_VALUE    (0)
                    ) regs(
                    .clk        (clk),
                    .reset_n    (reset_n),
                    .wen        (wen),
                    .data_i     (pipe_delay[i-1]),
                    .data_o     (pipe_delay[i]),
                    .clear      (clr[i])
                );
                assign uu_rds[i] = pipe_delay[i-1].rd;
                assign uu_reg_write[i] = pipe_delay[i-1].reg_write;
                assign uu_FP_reg_write[i] = pipe_delay[i-1].FP_reg_write;
            end
        end
    endgenerate 
    
endmodule
