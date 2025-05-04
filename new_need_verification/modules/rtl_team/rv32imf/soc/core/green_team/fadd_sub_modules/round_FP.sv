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


module round_FP(
        input NaN,
        input inf1,
        input inf2,
        input sign1,
        input sign2,
        input underflow,
        input [23:0] grs,
        input [2:0] rm,
        input logic  sign_res,
        input logic [7:0] exp_norm,
        output logic [31:0] result,
        
        input logic [22:0] mantissa_norm
        
    );

    logic G,R,S;
    logic overflow,inc_overflow;
//    logic [23:0] mantissa_norm_res;  // wrong
    logic [22:0] mantissa_norm_res; // correct
    logic [7:0] exp_round;
always_comb begin

        G = grs[23];
        R = grs[22];
        S = |grs[21:0];

        // Overflow & Underflow detection
        overflow = exp_norm > 8'd254;
        // underflow = (exp_norm == 0 && mantissa_norm == 0);

        // else if (underflow) begin
            
        //     result = {sign_res, 8'd0, 23'b0}; // Zero
        // end 

            // **Rounding Modes Implementation**
         if (NaN) begin // NaN case 
        result = {1'b0, 8'd255, 23'hffffff}; // Nan
        end 
        
        else if (inf1 || inf2) begin // infinity case 
            if(inf1 && inf2) begin
                case ({sign1,sign2})
                    2'b00: begin
                        result = {1'b0, 8'd255, 23'b0}; // Infinity
                    end
                    2'b01: begin
                        result = {1'b0, 8'd255, 23'hffffff}; // Nan
                    end
                    2'b10: begin
                        result = {1'b0, 8'd255, 23'hffffff}; // Nan
                    end
                    2'b11: begin
                        result = {1'b1, 8'b11111111, 23'b0}; // Infinity
                    end
                endcase
            end
            else begin
                case ({inf1,inf2})
                    2'b01: begin
                        result = {sign2, 8'b11111111, 23'b0}; // Infinity
                    end
                    2'b10: begin
                        result = {sign1, 8'b11111111, 23'b0}; // Infinity
                    end
                    default : 
                     result = {sign1, 8'b11111111, 23'b0}; // Infinity
                endcase
            end
        end
        else begin     
            if(overflow) begin
                result = {1'b0, 8'd255, 23'b0}; // Infinity
            end
            
         else if (underflow) begin
            
             result = {sign_res, 8'd0, 23'b0}; // Zero
         end 

            else begin
                case (rm)
                3'b000: begin // **RNE: Round to Nearest, Ties to Even**
                    if(G) begin
                        case ({R,S})
                        2'b00: begin
                            if(mantissa_norm[0]) begin
                                {inc_overflow,mantissa_norm_res} = mantissa_norm + 1;
                                if(inc_overflow) begin
                                    exp_round = exp_norm + 1;
                                end
                                else begin
                                    exp_round = exp_norm;
                                end
                                result = {sign_res, exp_round, mantissa_norm_res};
                            end
                            else begin
                                result = {sign_res, exp_norm, mantissa_norm};
                            end
                        end
                        default: begin
                            {inc_overflow,mantissa_norm_res} = mantissa_norm + 1;
                                if(inc_overflow) begin
                                exp_round = exp_norm + 1;
                                end
                                else begin
                                exp_round = exp_norm;
                                end
                                result = {sign_res, exp_norm, mantissa_norm_res};
                        end
                        endcase
                    end
                    else 
                        result = {sign_res, exp_norm, mantissa_norm};
                end

                3'b001: begin // **RTZ: Round Toward Zero (Truncate)**
                    result = {sign_res, exp_norm, mantissa_norm};
                end

                3'b010: begin // **RDN: Round Down (-∞)**
                    if (sign_res && (R || S || G)) begin
                        {inc_overflow,mantissa_norm_res} = mantissa_norm + 1;
                        if(inc_overflow) begin
                            exp_round = exp_norm + 1;
                        end
                        else begin
                            exp_round = exp_norm;
                        end
                        result = {sign_res, exp_round, mantissa_norm_res};
                    end
                    else
                        result = {sign_res, exp_norm, mantissa_norm};
                end

                3'b011: begin // **RUP: Round Up (+∞)**
                    if (~sign_res && (R || S || G)) begin
                        {inc_overflow,mantissa_norm_res} = mantissa_norm + 1;
                        if(inc_overflow) begin
                            exp_round = exp_norm + 1;
                        end
                        else begin
                            exp_round = exp_norm;
                        end
                            result = {sign_res, exp_round, mantissa_norm_res};
                    end
                    else
                        result = {sign_res, exp_norm, mantissa_norm};
                end

                3'b100: begin // round to maximum magnitude 
                    if (G) begin
                        {inc_overflow,mantissa_norm_res} = mantissa_norm + 1;
                        if(inc_overflow) begin
                            exp_round = exp_norm + 1;
                        end
                        else begin
                            exp_round = exp_norm;
                        end
                        
                        result = {sign_res, exp_round, mantissa_norm_res};
                    end
                    else
                        result = {sign_res, exp_norm, mantissa_norm}; 
                end
                default : 
                begin 
                result = {sign_res, exp_norm, mantissa_norm};       
                end
                endcase
            end



end
end          
    
endmodule
