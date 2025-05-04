// designers: Bijali & Omar --> not pipelined -> delete this module (NOTE: it doesn't suppose to be used in fsqrt module)
module fp_add (
    input logic add_sub,
    input logic [31:0] A,
    input logic [31:0] B,
    input logic [2:0] rm,  // Rounding Mode
    output logic [31:0] result

);

    // IEEE 754 Breakdown
    logic sign1, sign2, sign_res;
    logic [7:0] exp1, exp2, exp_res;
    logic [7:0] exp1_sub, exp2_sub;
    logic [22:0] man1, man2;
    logic [47:0] mantissa1, mantissa2; // 24-bit with implicit leading 1
    logic [47:0] mantissa1_S, mantissa2_S; // 24-bit with implicit leading 1
    logic [47:0] mantissa1_aligned,mantissa2_aligned;
    logic [23:0] mantissa_sum;
    logic [22:0] mantissa_norm;
    logic [22:0] mantissa_norm_res;
    logic [7:0] exp_norm;
    logic [7:0] exp_norm_res;
    logic [7:0] exp_round;
    logic [23:0] grs_side;
    logic [7:0] exp_diff;
    logic carry;

    // GRS Bits
    logic G, R, S;

    // Extract fields from IEEE 754 representation
    assign sign1 = A[31];
    assign sign2 = B[31] ^ add_sub;
    assign exp1 = A[30:23];
    assign exp2 = B[30:23];
    assign man1 = A[22:0];
    assign man2 = B[22:0];

    // flag signals 
    logic overflow;
    logic underflow;
    logic NaN;
    logic inf1;
    logic inf2;
    logic inc_overflow;

    always_comb begin
        // Handle special cases (NaN, Infinity)
        NaN = (man1 > 23'h000000 && exp1 == 8'b11111111) || (man2 > 23'h000000 && exp2 == 8'b11111111);
        inf1 = (man1 == 23'd0 && exp1 == 8'b11111111);
        inf2 = (man2 ==23'd0 && exp2 == 8'b11111111);
        // Add implicit leading '1' to mantissas
        
        if (NaN) begin
        result = {1'b0, 8'd255, 23'hffffff}; // Nan
        end 
        else if (inf1 || inf2) begin
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
        
        // Addition or Subtraction based on sign
        if (sign1 == sign2) begin
            {carry, mantissa_sum,grs_side} = mantissa2_aligned + mantissa1_aligned;
            sign_res = sign1;
        end 
        else if (mantissa1_aligned > mantissa2_aligned) begin
            {carry,mantissa_sum,grs_side} = mantissa1_aligned - mantissa2_aligned;
            sign_res = sign1;
        end 
        else begin
            {carry,mantissa_sum,grs_side} = mantissa2_aligned - mantissa1_aligned;
            sign_res = sign2;
        end
        

        // Normalize mantissa if overflow occurs
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
                

            
            
            
            
        // Extract Guard, Round, and Sticky bits
        G = grs_side[23];
        R = grs_side[22];
        S = |grs_side[21:0];

        // Overflow & Underflow detection
        overflow = exp_norm > 8'd254;
        // underflow = (exp_norm == 0 && mantissa_norm == 0);

        // else if (underflow) begin
            
        //     result = {sign_res, 8'd0, 23'b0}; // Zero
        // end 

            // *Rounding Modes Implementation*
            if(overflow) begin
                result = {1'b0, 8'd255, 23'b0}; // Infinity
            end
            
         else if (underflow) begin
            
             result = {sign_res, 8'd0, 23'b0}; // Zero
         end 

            else begin
                case (rm)
                3'b000: begin // *RNE: Round to Nearest, Ties to Even*
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

                3'b001: begin // *RTZ: Round Toward Zero (Truncate)*
                    result = {sign_res, exp_norm, mantissa_norm};
                end

                3'b010: begin // *RDN: Round Down (-∞)*
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

                3'b011: begin // *RUP: Round Up (+∞)*
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

                3'b100: begin
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