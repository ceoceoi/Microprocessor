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


module extract_align_FP(
        input add_sub,
        input [31:0] num1,
        input [31:0] num2,
        output logic NaN,
        output logic inf1,
        output logic inf2,
        output logic sign1,
        output logic sign2,
        output logic [7:0] exp_res,
        output logic [47:0] mantissa1_aligned,
        output logic [47:0] mantissa2_aligned
         

    );
    
//    logic sign1; 
//    logic sign2; 
    logic [7:0] exp1 ; 
    logic [7:0] exp2 ; 
    logic [22:0] man1 ; 
    logic [22:0] man2 ; 
    logic [47:0] mantissa1, mantissa2; // 24-bit with implicit leading 1
    logic [7:0] exp1_sub, exp2_sub;
    logic [7:0] exp_diff;

    assign sign1 = num1[31];
    assign sign2 = num2[31] ^ add_sub;
    assign exp1  = num1[30:23];
    assign exp2  = num2[30:23];
    assign man1  = num1[22:0];
    assign man2  = num2[22:0];
      
    always_comb begin
        NaN = (man1 > 23'h000000 && exp1 == 8'b11111111) || (man2 > 23'h000000 && exp2 == 8'b11111111);
        inf1 = (man1 == 23'd0 && exp1 == 8'b11111111);
        inf2 = (man2 ==23'd0 && exp2 == 8'b11111111); 
         
         
         // mantissa extraction and subnormal consideration 
       if (exp1==0) begin
                mantissa1 = {1'b0,1'b0, man1,24'b0};
                exp1_sub=exp1+1;
            end
            else begin
                mantissa1 = {1'b0,1'b1, man1,24'b0};
                exp1_sub=exp1;
            end
            if(exp2==0) begin
                mantissa2 = {1'b0,1'b0, man2,24'b0};
                exp2_sub=exp2+1;
            end
            else begin
                mantissa2 = {1'b0,1'b1, man2,24'b0};
                exp2_sub=exp2;
            end
        
            
            // Align exponent by shifting mantissa
            if (exp1_sub > exp2_sub) begin
                exp_diff = exp1_sub - exp2_sub;
                mantissa2_aligned = mantissa2 >> exp_diff;
                mantissa1_aligned = mantissa1;
                exp_res = exp1_sub;
            end 
            else if(exp2_sub > exp1_sub)begin
                exp_diff = exp2_sub - exp1_sub;
                mantissa1_aligned = mantissa1 >> exp_diff;
                mantissa2_aligned = mantissa2;
                exp_res = exp2_sub;
            end 
            else begin
                mantissa1_aligned = mantissa1;
                mantissa2_aligned = mantissa2;
                exp_res = exp1_sub ;
            end
            
    
    end
    
    
    
endmodule
