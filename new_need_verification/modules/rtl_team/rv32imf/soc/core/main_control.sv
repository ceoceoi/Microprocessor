typedef enum logic [6:0] {
    R_TYPE = 7'b0110011, 
    I_TYPE = 7'b0010011, 
    B_TYPE = 7'b1100011, 
    JAL    = 7'b1101111, 
    JALR   = 7'b1100111, 
    LOAD   = 7'b0000011, 
    S_TYPE  = 7'b0100011, // S_TYPE
    LUI    = 7'b0110111, 
    AUIPC = 7'b0010111,
    
    R_FLOAT = 7'b1010011, // more types for single precision  float-extension 
    R4_FMADD = 7'b1000011,  // NOTE: each instruction in R4 type has its own uniqe opcode
    R4_FMSUB = 7'b1000111,
    R4_FNMADD= 7'b1001011,
    R4_FNMSUB= 7'b1001111,
    I_FLOAT = 7'b0000111,
    S_FLOAT = 7'b0100111
} inst_type;

module decode_control (
    input logic [6:0] opcode,
    output logic reg_write,         // "reg_write" signal for integer registers-file
    output logic mem_write, 
    output logic mem_to_reg,    // used in load instruction (write-back Stage)
    output logic branch, 
    output logic alu_src, 
    output logic jump, 
    output logic [2:0] alu_op,
    output logic lui, 
    output logic auipc,
    output logic jal,
    output logic r_type,    // i think Qamar didn't used
    
    // special case in R_FLOAT instructions
    input logic [6:0] fun7_5_id,
    
    // signals for floating-point (FP) extention
    output logic rdata1_int_FP_sel,   // 0: integer data ---- 1: floating-point data
    output logic rdata2_int_FP_sel,
    output logic FP_reg_write       // "reg_write" signal for floating registers-file
);

    logic jump_or_upper_immediate;
    assign jump_or_upper_immediate = opcode[2];
    logic u_type, br_or_jump;
    assign u_type = jump_or_upper_immediate & opcode[4];
    assign br_or_jump = opcode[6];
    
    logic invalid_inst;
    assign  invalid_inst = ~|opcode[1:0];
    
    inst_type decoded_inst;
    assign decoded_inst = inst_type'(opcode);  // type casting
    // NOTE: we can use inst_type insdie this module as cases for better modularity ...
    
    // special cases in R_FLOAT instructions
    logic rd_is_integer;
    assign rd_is_integer = (fun7_5_id==7'b1100000)  // FCVT.W or FCVT.WU
                                            | (fun7_5_id==7'b1110000)   // FMV.X.W or FCALSS
                                            | (fun7_5_id==7'b1010000);  // compare instructions (FEQ, FLT, or FLE)
    logic rs1_is_integer;
    assign rs1_is_integer = (fun7_5_id==7'b1101000)  // FCVT.S.W or FCVT.S.WU
                                            | (fun7_5_id==7'b1111000);  // FMV.W.X
    
    /*    
    // alu-opcode types
    typedef enum logic [2:0] {
        ALU_OP_S_TYPE      = 3'b000,
        ALU_OP_I_TYPE       = 3'b001,
        ALU_OP_B_TYPE      = 3'b010,
        ALU_OP_R_TYPE      = 3'b011,
        ALU_OP_R_FLOAT   = 3'b100,
        ALU_OP_R4_FLOAT = 3'b101,
        ALU_OP_I_FLOAT    = 3'b110,
        ALU_OP_S_FLOAT   = 3'b111
    } alu_op_types;
    */
    
    //  outputs ...
    always_comb begin
        case (opcode)
            S_TYPE: begin
                mem_write = 1;      // it's HIGH only if opcode[5:4] == 10 and B-type doesn't suppose to be affected by this
                reg_write = 0;         // = ~ (b_type | store);

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;
                FP_reg_write = 0;
                
                // check them
                alu_op  = 3'b000;   // ALU_OP_S_TYPE 
                alu_src = 1;             // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 0;
                mem_to_reg = 0;  
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
            end
            
            I_TYPE: begin
                mem_write = 0;
                reg_write = 1;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;
                FP_reg_write = 0;
                
                // check them
                alu_op = 3'b001;    // ALU_OP_I_TYPE;
                alu_src =1;              // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
                
            end
            
            B_TYPE: begin
                mem_write = 0; // it's HIGH only if opcode[5:4] == 10 but i think B-type doesn't suppose to be affected if it was zero
                reg_write = 0;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;
                FP_reg_write = 0;
                
                // check them
                alu_op = 3'b010;     // ALU_OP_B_TYPE;
                alu_src = 0;              // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 1;               // br_or_jump & ~jump;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
                
            end
            
            R_TYPE: begin
                mem_write = 0;
                reg_write = 1;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;
                FP_reg_write = 0;
                
                // check them
                alu_op = 3'b011;     // ALU_OP_R_TYPE;
                alu_src = 0;              // 0: register-file  --- 1: imm
                r_type = 1;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
                
            end
            
            LOAD: begin
                mem_write = 0;
                reg_write = 1;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;
                FP_reg_write = 0;
                
                // check them
                alu_op = 3'b000;     // ALU_OP_S_TYPE; also
                alu_src = 1;              // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 0;
                mem_to_reg = ~invalid_inst;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
                                

            end
            
            R_FLOAT: begin
                mem_write = 0;
                reg_write = rd_is_integer? 1'b1 : 'b0;

                // flooting point (FP) signals
                rdata1_int_FP_sel = rs1_is_integer? 1'b0 : 1'b1;  // 0: integer  --- 1: Float
                rdata2_int_FP_sel = 1;
                FP_reg_write = rd_is_integer? 1'b0 : 1'b1;
                                
                // check them
                alu_op = 3'b100;     // ALU_OP_R_FLOAT;
                alu_src = 0;              // 0: register-file  --- 1: imm
                r_type = 1;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
                                

            end
            
            R4_FMADD: begin     // it was "R4_FLOAT: begin"
                mem_write = 0;
                reg_write = 0;
                
                // flooting point (FP) signals
                rdata1_int_FP_sel = 1;
                rdata2_int_FP_sel = 1;
//                rdata3_int_FP_sel = 1;  // it's always FP. And we hardcoded it as FP (assigned it to a fixed value to be always FP)
                FP_reg_write = 1;
                
                // check them
                alu_op = 3'b101;     // ALU_OP_R4_FLOAT;
                alu_src = 0;              // 0: register-file  --- 1: imm
                r_type = 1;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
            end
            
            R4_FMSUB: begin     // it was "R4_FLOAT: begin"
                mem_write = 0;
                reg_write = 0;
                
                // flooting point (FP) signals
                rdata1_int_FP_sel = 1;
                rdata2_int_FP_sel = 1;
                FP_reg_write = 1;
                
                // check them
                alu_op = 3'b101;     // ALU_OP_R4_FLOAT;
                alu_src = 0;              // 0: register-file  --- 1: imm
                r_type = 1;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
            end
            
            R4_FNMADD: begin     // it was "R4_FLOAT: begin"
                mem_write = 0;
                reg_write = 0;
                
                // flooting point (FP) signals
                rdata1_int_FP_sel = 1;
                rdata2_int_FP_sel = 1;
                FP_reg_write = 1;
                
                // check them
                alu_op = 3'b101;     // ALU_OP_R4_FLOAT;
                alu_src = 0;              // 0: register-file  --- 1: imm
                r_type = 1;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
            end
            
            R4_FNMSUB: begin     // it was "R4_FLOAT: begin"
                mem_write = 0;
                reg_write = 0;
                
                // flooting point (FP) signals
                rdata1_int_FP_sel = 1;
                rdata2_int_FP_sel = 1;
                FP_reg_write = 1;
                
                // check them
                alu_op = 3'b101;     // ALU_OP_R4_FLOAT;
                alu_src = 0;              // 0: register-file  --- 1: imm
                r_type = 1;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
            end
            
            I_FLOAT: begin 
                // NOTE: I_FLOAT type only has "FLW" instruciton and nothing else 
                mem_write = 0;
                reg_write = 0;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;     // actually don't care
                FP_reg_write = 1;
                                
                // check them
                alu_op = 3'b110;     // ALU_OP_I_FLOAT;
                alu_src = 1;              // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 0;
                mem_to_reg = ~invalid_inst;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
                                

            end
            
            S_FLOAT: begin
                mem_write = 1;
                reg_write = 0;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 1;
                FP_reg_write = 0;
                
                // check them
                alu_op = 3'b111;     // ALU_OP_S_FLOAT;
                alu_src = 1;              // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;
                                

            end

            
            JAL: begin
                mem_write = 0;
                reg_write = 1;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;
                FP_reg_write = 0;
                
                // check them
                alu_op = 3'b000;     // ALU_OP_S_FLOAT;
                alu_src = 1;              // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 1;
                jal = 1;
                lui = 0;
                auipc = 0;
                
                
            end
            
            
            JALR: begin
                mem_write = 0;
                reg_write = 1;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;
                FP_reg_write = 0;
                
                // check them
                alu_op = 3'b000;       // ALU_OP_S_FLOAT;
                alu_src = 1;                // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 1;
                jal = 0;
                lui = 0;
                auipc = 0;

            end
            
            LUI: begin
                mem_write = 0;
                reg_write = 1;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;
                FP_reg_write = 0;
                
                // check them
                alu_op = 3'b000;     // ALU_OP_S_FLOAT;
                alu_src = 1;              // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 1;
                auipc = 0;
                                

            end
            
            AUIPC: begin
                mem_write = 0;
                reg_write = 1;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;
                FP_reg_write = 0;
                
                // check them
                alu_op = 3'b000;     // ALU_OP_S_FLOAT;
                alu_src = 1;              // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 1;
                

            end
                                 
            default: begin  // i think it could cause some logical errors in other instruction types (J-type, U-type) --> solved
                mem_write = 0;
                reg_write = 1;

                // flooting point (FP) signals
                rdata1_int_FP_sel = 0;
                rdata2_int_FP_sel = 0;
                FP_reg_write = 0;
                
                // check them
                alu_op = 3'b000;     // ALU_OP_R_TYPE;
                alu_src = 1;              // 0: register-file  --- 1: imm
                r_type = 0;
                branch = 0;
                mem_to_reg = 0;
                
                jump = 0;
                jal = 0;
                lui = 0;
                auipc = 0;


            end
        endcase
    end

endmodule