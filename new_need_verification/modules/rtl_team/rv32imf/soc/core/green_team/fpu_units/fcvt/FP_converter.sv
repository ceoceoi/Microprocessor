import riscv_types::*;
    
module FP_converter(
    input alu_t alu_ctrl,
    input logic [31:0] rs1,
    input logic [31:0] rs2,
    input logic [2:0] rm,
    output logic [31:0] result
);

    // Wires for module outputs
    logic [31:0] float2int_signed_result;
    logic [31:0] float2int_unsigned_result;
    logic [31:0] int2float_signed_result;
    logic [31:0] int2float_unsigned_result;

    // Instantiate external conversion modules outside always_comb
    float2ints float2int_signed (
        .floatIn(rs1),
        .rm(rm),        // use it with Venus -> // (new) use this if you're using Venus simulator. Or use the negate one (below one "~rm") if yoo're using toolchain assembler
//        .rm(~rm),     // use it with toolchain assembler -> // --> (new) Abdulshakoor: because our assembler use rm=7 not 0, so negate it and it will works as we designed
        .result(float2int_signed_result)
    );

    float2int float2int_unsigned (
        .floatIn(rs1),
        .rm(rm),        // use it with Venus -> // (new) use this if you're using Venus simulator. Or use the negate one (below one "~rm") if yoo're using toolchain assembler
//        .rm(~rm),     // use it with toolchain assembler -> // --> (new) Abdulshakoor: because our assembler use rm=7 not 0, so negate it and it will works as we designed
        .result(float2int_unsigned_result)
    );

    int2floats int2float_signed (
        .integerIN(rs1),
        .rm(rm),        // use it with Venus -> // (new) use this if you're using Venus simulator. Or use the negate one (below one "~rm") if yoo're using toolchain assembler
//        .rm(~rm),     // use it with toolchain assembler -> // --> (new) Abdulshakoor: because our assembler use rm=7 not 0, so negate it and it will works as we designed
        .result(int2float_signed_result)
    );

    int2float int2float_unsigned (
        .integerIN(rs1),
        .rm(rm),        // use it with Venus -> // (new) use this if you're using Venus simulator. Or use the negate one (below one "~rm") if yoo're using toolchain assembler
//        .rm(~rm),     // use it with toolchain assembler -> // --> (new) Abdulshakoor: because our assembler use rm=7 not 0, so negate it and it will works as we designed
        .result(int2float_unsigned_result)
    );

    always_comb begin
        case (alu_ctrl)
            FMIN: result = (rs1 > rs2) ? rs2 : rs1;
            FMAX: result = (rs1 > rs2) ? rs1 : rs2;
            FEQ: result = (rs1 == rs2) ? 32'd1 : 32'd0;
            FLT: result = (rs1 < rs2) ? 32'd1 : 32'd0;
            FLE: result = (rs1 <= rs2) ? 32'd1 : 32'd0;
            FSGNJ: result = {rs2[31], rs1[30:0]};
            FSGNJN: result = {~rs1[31], rs1[30:0]};
            FSGNJX: result = {rs1[31] ^ rs2[31], rs1[30:0]};
            FMVXW: result = rs1;
            FMVWX: result = rs1;
            
            // Floating-Point Classification
            FCLASS: begin
                if (rs1[22] == 1'b0 && rs1[21:0] > 22'b0 && rs1[30:23] == 8'b11111111) 
                    result = {22'd0, 10'b0100000000};  // sNaN
                else if (rs1[22] == 1'b1 && rs1[21:0] >= 22'd0 && rs1[30:23] == 8'b11111111) 
                    result = {22'd0, 10'b1000000000};  // qNaN
                else if (rs1[31] == 1'b0 && rs1[22:0] == 23'd0 && rs1[30:23] == 8'b11111111) 
                    result = {22'd0, 10'b0010000000};  // +Inf
                else if (rs1[31] == 1'b1 && rs1[22:0] == 23'd0 && rs1[30:23] == 8'b11111111) 
                    result = {22'd0, 10'b0000000001};  // -Inf
                else if (rs1[31] == 1'b1 && rs1[30:0] == 31'd0) 
                    result = {22'd0, 10'b0000001000};  // -Zero
                else if (rs1[31] == 1'b0 && rs1[30:0] == 31'd0) 
                    result = {22'd0, 10'b0000010000};  // +Zero
                else if (rs1[31] == 1'b1 && rs1[30:23] == 8'd0 && rs1[22:0] > 23'd0) 
                    result = {22'd0, 10'b0000000100};  // -Subnormal
                else if (rs1[31] == 1'b0 && rs1[30:23] == 8'd0 && rs1[22:0] > 23'd0) 
                    result = {22'd0, 10'b0000100000};  // +Subnormal
                else if (rs1[31] == 1'b1) 
                    result = {22'd0, 10'b0000000010};  // -Normal
                else 
                    result = {22'd0, 10'b0001000000};  // +Normal
            end
            
            // Use precomputed conversion results
            FCVTW: result = float2int_signed_result;
            FCVTWU: result = float2int_unsigned_result;
            FCVTSW: result = int2float_signed_result;
            FCVTSWU: result = int2float_unsigned_result;
            
            default: result = 32'd0; // Default case
        endcase
    end
endmodule

