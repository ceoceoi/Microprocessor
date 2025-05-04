module int2floats(
    input  logic [31:0] integerIN,
    input  logic [2:0] rm,
    output logic [31:0] result
);
    //signed number
    logic [7:0] exp;
    logic valid;
    logic [22:0] man;
    logic [4:0] msb_idx;  // Store MSB index
    logic [53:0] IU;
    logic lead ,sign;
    logic [11:0] grs;
    logic [31:0] temp_result ;
    logic signed [31:0] temp_integer;
    logic G,R,S;
    assign G = grs[11];
    assign R = grs[10];
    assign S = |grs[9:0];

    always_comb begin 
        grs = 12'd0;
        if(integerIN[31])begin
            temp_integer = -integerIN;
            sign = 1'b1;
        end else begin
            temp_integer = integerIN;
            sign = 1'b0;
        end
        
        IU = {23'b0,temp_integer};
        // Check from MSB down using if-else conditions
        if(temp_integer[31]) begin msb_idx = 5'd31; valid = 1'b1; end
        else if (temp_integer[30]) begin msb_idx = 5'd30; valid = 1'b1; end
        else if (temp_integer[29]) begin msb_idx = 5'd29; valid = 1'b1; end
        else if (temp_integer[28]) begin msb_idx = 5'd28; valid = 1'b1; end
        else if (temp_integer[27]) begin msb_idx = 5'd27; valid = 1'b1; end
        else if (temp_integer[26]) begin msb_idx = 5'd26; valid = 1'b1; end
        else if (temp_integer[25]) begin msb_idx = 5'd25; valid = 1'b1; end
        else if (temp_integer[24]) begin msb_idx = 5'd24; valid = 1'b1; end
        else if (temp_integer[23]) begin msb_idx = 5'd23; valid = 1'b1; end
        else if (temp_integer[22]) begin msb_idx = 5'd22; valid = 1'b1; end
        else if (temp_integer[21]) begin msb_idx = 5'd21; valid = 1'b1; end
        else if (temp_integer[20]) begin msb_idx = 5'd20; valid = 1'b1; end
        else if (temp_integer[19]) begin msb_idx = 5'd19; valid = 1'b1; end
        else if (temp_integer[18]) begin msb_idx = 5'd18; valid = 1'b1; end
        else if (temp_integer[17]) begin msb_idx = 5'd17; valid = 1'b1; end
        else if (temp_integer[16]) begin msb_idx = 5'd16; valid = 1'b1; end
        else if (temp_integer[15]) begin msb_idx = 5'd15; valid = 1'b1; end
        else if (temp_integer[14]) begin msb_idx = 5'd14; valid = 1'b1; end
        else if (temp_integer[13]) begin msb_idx = 5'd13; valid = 1'b1; end
        else if (temp_integer[12]) begin msb_idx = 5'd12; valid = 1'b1; end
        else if (temp_integer[11]) begin msb_idx = 5'd11; valid = 1'b1; end
        else if (temp_integer[10]) begin msb_idx = 5'd10; valid = 1'b1; end
        else if (temp_integer[9])  begin msb_idx = 5'd9; valid = 1'b1; end
        else if (temp_integer[8])  begin msb_idx = 5'd8; valid = 1'b1; end
        else if (temp_integer[7])  begin msb_idx = 5'd7; valid = 1'b1; end
        else if (temp_integer[6])  begin msb_idx = 5'd6; valid = 1'b1; end
        else if (temp_integer[5])  begin msb_idx = 5'd5; valid = 1'b1; end
        else if (temp_integer[4])  begin msb_idx = 5'd4; valid = 1'b1; end
        else if (temp_integer[3])  begin msb_idx = 5'd3; valid = 1'b1; end
        else if (temp_integer[2])  begin msb_idx = 5'd2; valid = 1'b1; end
        else if (temp_integer[1])  begin msb_idx = 5'd1; valid = 1'b1; end
        else if (temp_integer[0])  begin msb_idx = 5'd0; valid = 1'b1; end
        else begin msb_idx = 5'd0; valid = 1'b0; end

    // Compute IEEE 754 floating point representation if valid
        if (valid) begin
            exp = {4'd0, msb_idx} + 8'd127; // Compute exponent
            {lead,man,grs} = IU << (35 - msb_idx);   // Normalize fraction
            temp_result = {sign, exp, man};
            case (rm)
                3'b000: begin // **RNE: Round to Nearest, Ties to Even**
                    if(G) begin
                        case ({R,S})
                        2'b00: begin
                            if(man[0]) begin
                                result = temp_result +1;
                            end
                            else begin
                                result = temp_result;
                            end
                        end
                        default: begin
                                    result = temp_result;
                                end
                        endcase
                    end
                    else 
                        result = temp_result;
                end

                3'b001: begin // **RTZ: Round Toward Zero (Truncate)**
                    result = temp_result;
                end

                3'b010: begin // **RDN: Round Down (-∞)**
                    if ((R || S || G)) begin
                        result = temp_result +1;
                    end
                    else
                        result = temp_result;
                end

                3'b011: begin // **RUP: Round Up (+∞)**
                    if ((R || S || G)) begin
                        result = temp_result +1;
                    end
                    else
                        result = temp_result;
                end

                3'b100: begin
                    if (G) begin
                        result = temp_result +1;
                    end
                    else
                        result = temp_result;
                end
                default : 
                begin 
                    result = temp_result;
                end
                endcase
        end
        else begin
            result = 32'd0; // Return 0 if input is 0
        end
    end

endmodule
