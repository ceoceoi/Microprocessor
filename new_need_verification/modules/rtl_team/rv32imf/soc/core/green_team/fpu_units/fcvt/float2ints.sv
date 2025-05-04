module float2ints (
    input logic [31:0] floatIn,
    input logic [2:0] rm,
    output logic [31:0] result
);

    logic [7:0] exp;
    logic [7:0] shiftval;
    logic signed [7:0]  shiftExp;
    logic [22:0] man;
    logic [54:0] FP;
    logic [54:0] Fpres;
    logic [31:0] temp_result;
    logic [54:0] Fpres_norm;
    logic S ,G ,R, NaN, inf, overflow;

    assign exp = floatIn [30:23];
    assign man = floatIn[22:0];
    assign shiftExp = exp - 8'd127;    
    assign shiftval = (shiftExp<0) ? -shiftExp :shiftExp;    
    assign FP = {31'd0,1'b1,man};
    assign S = |Fpres[20:0];
    assign G = Fpres[22];
    assign R = Fpres[21];
    assign NaN = (man > 23'h000000 && exp == 8'b11111111);
    assign inf = (man == 23'd0 && exp == 8'b11111111);
    assign overflow = (exp >= 8'b10011110); //including Nan and inf
    // assign  overflow = exp > 8'd254;
    always_comb begin
             if(shiftExp > 0) begin
                Fpres = FP << shiftval;
            end
            else if(shiftExp < 0) begin
                Fpres = FP >> shiftval;
            end
            else begin  
                Fpres = FP;
            end    
            if (inf) begin
                result = 32'd1;
            end
            else if(NaN) begin
                result = 32'd0;
            end
            else if(overflow) begin
                if(floatIn[31])
                result = 32'h80000000;//-flow
                else
                result = 32'h7FFFFFFF;//+flow
            end
            else begin
            Fpres_norm = Fpres;
            case (rm)
                3'b000: begin // **RNE: Round to Nearest, Ties to Even**
                    if (G) begin
                        case ({R, S})   
                            2'b00: begin
                                if (Fpres_norm[23]) begin
                                    temp_result = Fpres_norm[54:23] + 1; // Round up only if LSB is 1
                                end else begin
                                    temp_result = Fpres_norm[54:23]; // Keep same value
                                end
                                result = floatIn[31] ? -temp_result : temp_result;
                            end
                            default: begin
                                temp_result = Fpres_norm[54:23] + 1; 
                                result = floatIn[31] ? -temp_result : temp_result;
                            end
                        endcase
                    end else begin
                        temp_result = Fpres_norm[54:23];
                        result = floatIn[31] ? -temp_result : temp_result;
                    end
                end

                3'b001: begin // **RTZ: Round Toward Zero (Truncate)**
                    temp_result = Fpres_norm[54:23];
                    result = floatIn[31] ? -temp_result : temp_result;
                end // Simply drop the fraction

                3'b010: begin // **RDN: Round Down (-∞)**
                    if (floatIn[31] && (R || S || G)) begin
                        temp_result = Fpres_norm[54:23] + 1; // Round toward negative infinity
                    end else begin
                        temp_result = Fpres_norm[54:23]; // No rounding
                    end
                    result = floatIn[31] ? -temp_result : temp_result;
                end

                3'b011: begin // **RUP: Round Up (+∞)**
                    if (~floatIn[31] && (R || S || G)) begin
                        temp_result = Fpres_norm[54:23] + 1;  // Round up for positive numbers
                    end else begin
                        temp_result = Fpres_norm[54:23];  // No rounding needed
                    end
                    result = floatIn[31] ? -temp_result : temp_result;
                end

                3'b100: begin // **RAZ: Round Away from Zero**
                    if (G) begin
                        temp_result = Fpres_norm[54:23] + 1; // Always round away from zero
                    end else begin
                        temp_result = Fpres_norm[54:23]; // No rounding needed
                    end
                    result = floatIn[31] ? -temp_result : temp_result;
                end

                default: begin // **Default: No Rounding**
                    result = Fpres_norm[54:23];
                    // NOTE: Abdulshakoor - NOTE: since our toolchain assembler uses rm=7, it won't change the sign-bit --> suggested solution: use "~rm"
                end
            endcase
            end
    end
endmodule

