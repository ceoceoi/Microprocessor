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


module normalize_FP(
        input sign1,
        input sign2,
        input [23:0] mantissa_sum,
        input [7:0] exp_res,
        input  carry,
        output logic [22:0] mantissa_norm,
        output logic [7:0] exp_norm,
        output logic underflow
        
    );


always_comb begin


         if (sign1 == sign2) begin
         underflow=1'b0;
            case({carry,mantissa_sum[23]})
                2'b00: begin
                    mantissa_norm = mantissa_sum [22:0];
                    exp_norm = 8'b0;
                end
                2'b01: begin
                    mantissa_norm = mantissa_sum [22:0];
                    exp_norm = exp_res;
                end
                2'b10: begin
                    mantissa_norm = {1'b0,mantissa_sum[22:1]};
                    exp_norm = exp_res + 1;  

                end 
                2'b11: begin
                    mantissa_norm = {1'b1,mantissa_sum[22:1]};
                    exp_norm = exp_res + 1;  
                end
            default: begin
                mantissa_norm = mantissa_sum [22:0];
                exp_norm = exp_res;
            end
            endcase
            end
            
            else begin


if (mantissa_sum[23]) begin
    mantissa_norm = mantissa_sum[22:0];
    exp_norm = exp_res;
end

else if (mantissa_sum[22]) begin
    mantissa_norm = mantissa_sum[22:0] << 1;
    exp_norm = exp_res - 23'd1;
end

else if (mantissa_sum[21]) begin
    mantissa_norm = mantissa_sum[22:0] << 2;
    exp_norm = exp_res - 23'd2;
end

else if (mantissa_sum[20]) begin
    mantissa_norm = mantissa_sum[22:0] << 3;
    exp_norm = exp_res - 23'd3;
end

else if (mantissa_sum[19]) begin
    mantissa_norm = mantissa_sum[22:0] << 4;
    exp_norm = exp_res - 23'd4;
end

else if (mantissa_sum[18]) begin
    mantissa_norm = mantissa_sum[22:0] << 5;
    exp_norm = exp_res - 23'd5;
end

else if (mantissa_sum[17]) begin
    mantissa_norm = mantissa_sum[22:0] << 6;
    exp_norm = exp_res - 23'd6;
end

else if (mantissa_sum[16]) begin
    mantissa_norm = mantissa_sum[22:0] << 7;
    exp_norm = exp_res - 23'd7;
end

else if (mantissa_sum[15]) begin
    mantissa_norm = mantissa_sum[22:0] << 8;
    exp_norm = exp_res - 23'd8;
end

else if (mantissa_sum[14]) begin
    mantissa_norm = mantissa_sum[22:0] << 9;
    exp_norm = exp_res - 23'd9;
end

else if (mantissa_sum[13]) begin
    mantissa_norm = mantissa_sum[22:0] << 10;
    exp_norm = exp_res - 23'd10;
end

else if (mantissa_sum[12]) begin
    mantissa_norm = mantissa_sum[22:0] << 11;
    exp_norm = exp_res - 23'd11;
end

else if (mantissa_sum[11]) begin
    mantissa_norm = mantissa_sum[22:0] << 12;
    exp_norm = exp_res - 23'd12;
end

else if (mantissa_sum[10]) begin
    mantissa_norm = mantissa_sum[22:0] << 13;
    exp_norm = exp_res - 23'd13;
end

else if (mantissa_sum[9]) begin
    mantissa_norm = mantissa_sum[22:0] << 14;
    exp_norm = exp_res - 23'd14;
end

else if (mantissa_sum[8]) begin
    mantissa_norm = mantissa_sum[22:0] << 15;
    exp_norm = exp_res - 23'd15;
end

else if (mantissa_sum[7]) begin
    mantissa_norm = mantissa_sum[22:0] << 16;
    exp_norm = exp_res - 23'd16;
end

else if (mantissa_sum[6]) begin
    mantissa_norm = mantissa_sum[22:0] << 17;
    exp_norm = exp_res - 23'd17;
end

else if (mantissa_sum[5]) begin
    mantissa_norm = mantissa_sum[22:0] << 18;
    exp_norm = exp_res - 23'd18;
end

else if (mantissa_sum[4]) begin
    mantissa_norm = mantissa_sum[22:0] << 19;
    exp_norm = exp_res - 23'd19;
end

else if (mantissa_sum[3]) begin
    mantissa_norm = mantissa_sum[22:0] << 20;
    exp_norm = exp_res - 23'd20;
end

else if (mantissa_sum[2]) begin
    mantissa_norm = mantissa_sum[22:0] << 21;
    exp_norm = exp_res - 23'd21;
end

else if (mantissa_sum[1]) begin
    mantissa_norm = mantissa_sum[22:0] << 22;
    exp_norm = exp_res - 23'd22;
end

else if (mantissa_sum[0]) begin
    mantissa_norm = mantissa_sum[22:0] << 23;
    exp_norm = exp_res - 23'd23;
end

else begin
    mantissa_norm = 0;
    exp_norm = exp_res - 23'd24;
end

if (exp_norm>exp_res)
underflow=1'b1;
else
underflow=1'b0;
end
                

            
            
end          
    
endmodule
