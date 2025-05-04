`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2025 02:24:40 AM
// Design Name: 
// Module Name: extract_align_FP
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


module add_sub_FP(
        input sign1,
        input sign2,
        input [47:0] mantissa1_aligned,
        input [47:0] mantissa2_aligned,
        output logic [23:0] grs,
        output logic [23:0] mantissa_sum,
        output logic  carry,
        output logic  sign_res
        
        
    );


always_comb begin

     if (sign1 == sign2) begin
         {carry, mantissa_sum,grs} = mantissa2_aligned + mantissa1_aligned;
         sign_res = sign1;
     end 
     else if (mantissa1_aligned > mantissa2_aligned) begin
         {carry,mantissa_sum,grs} = mantissa1_aligned - mantissa2_aligned;
         sign_res = sign1;
     end 
     else begin
         {carry,mantissa_sum,grs} = mantissa2_aligned - mantissa1_aligned;
         sign_res = sign2;
     end
end          
    
endmodule
