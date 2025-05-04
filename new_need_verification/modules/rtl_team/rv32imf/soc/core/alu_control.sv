module alu_control (
    input logic [2:0] fun3,
    input logic [6:0] fun7,
    input logic [4:0] rs2,
    input logic [2:0] alu_op,
    input logic [6:0] opcode,
    output alu_t alu_ctrl
);

// alu-opcode types
parameter LOAD_STORE = 3'b000,
                    I_TYPE = 3'b001,
                    B_TYPE = 3'b010,
                    R_TYPE = 3'b011,
                    R_float=3'b100,
                    R4_float=3'b101,
                    I_float=3'b110,
                    S_float=3'b111;
        
always_comb begin 
    case(alu_op)

        R_TYPE: begin 
                  case({fun7,fun3})
                      10'b0000000000:
                            alu_ctrl = ADD; 
                       
                      10'b0100000000: 
                            alu_ctrl = SUB;
                            
                      10'b0000000001:
                            alu_ctrl = SLL;  
                            
                      10'b0000000010:
                            alu_ctrl = SLT;
                      
                      10'b0000000011:
                            alu_ctrl = SLTU;           
                       
                      10'b0000000100:
                            alu_ctrl = XOR;          
                    
                      10'b0000000101:
                            alu_ctrl = SRL;

                            
                      10'b0100000101:
                            alu_ctrl = SRA;     

                      10'b0000000110:
                            alu_ctrl = OR;
                            
                      10'b0000000111:
                            alu_ctrl = AND; 
                                
                      10'b0000001000:
                            alu_ctrl = MUL;  
                            
                      10'b0000001001:
                            alu_ctrl = MULH;
  
                      10'b0000001010:
                            alu_ctrl = MULHSU;                          

                      10'b0000001011:
                            alu_ctrl = MULHU;   
                            
                      10'b0000001100:
                            alu_ctrl = DIV;  
                            
                      10'b0000001101:
                            alu_ctrl = DIVU;  
                           
                      10'b0000001110:
                            alu_ctrl = REM; 
                            
                      10'b0000001111:
                            alu_ctrl = REMU;       

                      default:
                            alu_ctrl = ADD;
            endcase
         end   

        I_TYPE: begin 
                case(fun3)
                        3'b000:
                        alu_ctrl = ADD;                     // ADDI
                        3'b010: alu_ctrl = SLT;        // SLTI
                        3'b011: alu_ctrl = SLTU;     // SLTIU
                        3'b100: alu_ctrl = XOR;      // XORI
                        3'b110: alu_ctrl = OR;        // ORI
                        3'b111: alu_ctrl = AND;     // ANDI
                        3'b001: alu_ctrl = SLL;       // SLLI
                        
                        3'b101: begin  // alu_ctrl = (fun7==0)? SRL : SRA;

                            if(fun7==0)
                                alu_ctrl = SRL; //SRLI
                            else
                                alu_ctrl=SRA; // SRAI
                        end
                        
                        default:  alu_ctrl = ADD;
               endcase
        end

        LOAD_STORE: begin
            alu_ctrl = ADD; 
        end

        B_TYPE: begin 
            case(fun3[2:1])
                2'b00: alu_ctrl = SUB;
                2'b01: alu_ctrl = SUB;
                2'b10: alu_ctrl = SLT;
                2'b11: alu_ctrl = SLTU;
            endcase
        end
        
         R_float: begin 
         
         
                  case (fun7)
                7'b0000000: begin         
                        alu_ctrl = FADD;
              
                 end 
                7'b0000100:begin 
                        alu_ctrl = FSUB;
                 end 
                 
                7'b0001000:begin 
                
                        alu_ctrl = FMUL;
                 end 
                    
                7'b0001100:begin 
                        alu_ctrl = FDIV;
                 end 
                 
                7'b0101100:begin
                        alu_ctrl = FSQRT;
                  end 
                  
                7'b0010000:begin 
                 
                            if(fun3 == 3'b000)

                                alu_ctrl = FSGNJ;
                            
                            else if (fun3 == 3'b001)
                                alu_ctrl = FSGNJN;
                            
                            else if (fun3 == 3'b010)
                                alu_ctrl = FSGNJX;                                            
                            else
                                alu_ctrl = FSGNJ;
                  end         
                  
                7'b0010100:begin
                
                              if(fun3 == 3'b000)
                                alu_ctrl = FMIN;
                            
                            else if (fun3 == 3'b001)
                                alu_ctrl = FMAX;
                                                                    
                            else
                                alu_ctrl = FMIN;                       
                  end     
                    
                // FCVTSW & FCVTSWU are similar, so use bits of "rs2" also
                7'b1100000:begin
                
                              if (rs2 == 5'b00000) 
                                alu_ctrl = FCVTW;
               
                              else if (rs2 == 5'b00001)                        
                                alu_ctrl = FCVTWU;
                                
                              else 
                                alu_ctrl = FCVTW;  
                  end       
                  
                  7'b1110000:begin
                
                              if(fun3 == 3'b000)
                                alu_ctrl = FMVXW;
                            
                            else if (fun3 == 3'b001)
                                alu_ctrl = FCLASS;
                                                                    
                            else
                                alu_ctrl = FMVXW;                       
                  end  
                  
                  
              7'b1010000:begin
                

                            if(fun3 == 3'b000)
                                alu_ctrl = FLE;
                            
                            else if (fun3 == 3'b001)
                                alu_ctrl = FLT;
                            
                            else if (fun3 == 3'b010)
                                alu_ctrl = FEQ;                                            
                            else
                                alu_ctrl = FLE;                     
                  end  

                // FCVTSW & FCVTSWU are similar, so use bits of "rs2" also
                7'b1101000:begin
                
                              if (rs2 == 5'b00000) 
                                alu_ctrl = FCVTSW;
               
                              else if (rs2 == 5'b00001)                        
                                alu_ctrl = FCVTSWU;
                                
                              else 
                                alu_ctrl = FCVTSW;  
                  end    
                        
                7'b1111000:
                        alu_ctrl = FMVWX;

                default: alu_ctrl = FADD;
           endcase
        end
        
         R4_float: begin
            case (opcode)
                7'b1000011: alu_ctrl = FMADD;  
                7'b1000111: alu_ctrl = FMSUB;  
                7'b1001011: alu_ctrl = FNMSUB;  

                7'b1001111: alu_ctrl = FNMADD;  
                default: alu_ctrl = FMADD;  
             endcase
          end
        
        I_float: begin 
            alu_ctrl = ADD; 
        end
        
         S_float: begin 
            alu_ctrl = ADD;
        end
        // 3-bits cases  -->  all cases have covered, no needs for "default" case        
    endcase
end

endmodule : alu_control
