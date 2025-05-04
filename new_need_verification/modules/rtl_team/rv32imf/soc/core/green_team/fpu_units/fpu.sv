import riscv_types::*;

// a unit for executing other Floating-Point instructions (e.g.fmax, fmin, ..etc.)
module fpu (
    input alu_t alu_ctrl ,
    input logic [2:0] fun3,
    input logic [31:0] rs1,
    input logic [31:0] rs2,
    output logic [31:0] result 
);

// FCVT.s logic ...
logic [31:0] fcvt_result;
FP_converter fcvt (
    .rm(fun3),
    .result(fcvt_result),
    .*
);


always_comb begin
    case(alu_ctrl)
        FMIN: begin
            if(rs1 > rs2)
            result = rs2;
            else
            result = rs1;
        end
        FMAX: begin
            if(rs1 > rs2)
            result = rs1;
            else
            result = rs2;
        end
        FEQ: begin
            if(rs1 == rs2)
            result = 1;
            else
            result = 0;
        end
        FLT: begin
            if(rs1 < rs2)
            result = 1;
            else
            result = 0;
        end
        FLE: begin
            if(rs1 <= rs2)
            result = 1;
            else
            result = 0;

        end
        FSGNJ: begin
            result = {rs2[31],rs1[30:0]};
        end
        FSGNJN: begin
            result = {~rs2[31],rs1[30:0]}; 
        end
        FSGNJX: begin
            result = {rs1[31]^rs2[31],rs1[30:0]};
        end
        FCLASS: begin
            if(rs1[22] == 1'b0 && rs1[21:0] > 22'b0 && rs1[30:23] == 8'b11111111) //sNan
            result = {22'd0,10'b0100000000};
            else if(rs1[22] == 1'b1 && rs1[21:0] >= 22'd0 && rs1[30:23] == 8'b11111111)//qNan
            result = {22'd0,10'b1000000000};
            else if(rs1[31] == 1'b0 && rs1[22:0] == 23'd0 && rs1[30:23] == 8'b11111111)//+Inf
            result = {22'd0,10'b0010000000};
            else if(rs1[31] == 1'b1 && rs1[22:0] == 23'd0 && rs1[30:23] == 8'b11111111)//-Inf
            result = {22'd0,10'b0000000001};
            else if(rs1[31] == 1'b1 && rs1[30:0] == 31'd0)//-zero
            result = {22'd0,10'b0000001000};
            else if(rs1[31] == 1'b0 && rs1[30:0] == 31'd0)//+zero
            result = {22'd0,10'b0000010000};
            else if(rs1[31] == 1'b1 && rs1[30:23] == 8'd0 && rs1[22:0] > 23'd0)//-Subnum
            result = {22'd0,10'b0000000100};
            else if(rs1[31] == 1'b0 && rs1[30:23] == 8'd0 && rs1[22:0] > 23'd0)//+Subnum
            result = {22'd0,10'b0000100000};
            else if(rs1[31] == 1'b1)//- normal num
            result = {22'd0,10'b0000000010};
            else//+ normal num
            result = {22'd0,10'b0001000000};
        end
        FMVXW: begin
            result = rs1;
        end
        
        // all results in fcvt here are the same because FP_converter module already handled the result
        FCVTW: begin    // FP to integer (signed)
            result = fcvt_result;
        end
        FCVTWU: begin    // FP to integer (unsigned)
            result = fcvt_result;
        end
        FCVTSW: begin    // integer to FP (signed)
            result = fcvt_result;
        end
        FCVTSWU: begin    // integer to FP (unsigned)
            result = fcvt_result;
        end
        
        FMVWX: begin
            result = rs1;
        end
        
        default: result = 'b0;
    endcase
end


endmodule
