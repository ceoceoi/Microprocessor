`timescale 1ns / 1ps

module clear_units_decoder #(
        parameter num_rds = 9,         // number of rd
        parameter rd_addr_width = 5    // bits of rd-address
    ) (
    input  logic [rd_addr_width-1 : 0] rd_used [0 : num_rds-1],  // array of rd signals
    input logic [num_rds-1 : 0] reg_write_unit,            // indicates that rd is integer      // not used
    input logic [num_rds-1 : 0] FP_reg_write_unit,         // indicates that rd is FP       // not used
    input logic [num_rds-1 : 0] all_uu_rd_busy,         // indicate that rd still inisde the unit and didn't reach MEM stage yet
    input logic no_exe_unit_dependency, 
    input logic is_R4_instruction,
    
    input  logic [rd_addr_width-1 : 0] waw_rd,                    // a new rd that causes write-after-write (WAW) problem
    input  logic [rd_addr_width-1 : 0] waw_rs1,                  // rs1 from the new intstruction
    input  logic [rd_addr_width-1 : 0] waw_rs2,                  // rs2 from the new intstruction
    input  logic [rd_addr_width-1 : 0] waw_rs3,                  // rs3 from the new intstruction (special case used with R4 instructions)
    input logic reg_write_new,             // indicates that rd is integer
    input logic FP_reg_write_new,          // indicates that rd is FP
    
    output logic [num_rds-1 : 0] clear_rd  // Array of clear signals for each unit
);

    // Generate block using genvar to create the clear logic for each rd
    genvar i;
    generate
        for (i = 0; i < num_rds; i++) begin: clr_gen
            // Generate the clear signal for each rd only if the same rd address and type match
            if (i==0) begin  // clear inreger units
                assign clear_rd[i] = (rd_used[i] == waw_rd) && (waw_rd != 0) && (reg_write_new && ~FP_reg_write_new) // To avoid clearing (and stalling) if the unit was not writing (reg 0)
                                                    && (waw_rs1 != waw_rd || waw_rs2 != waw_rd || (waw_rs3 != waw_rd && is_R4_instruction))
                                                    && all_uu_rd_busy[i]  // it's busy flag if "div_uu_rd" actually used or not
                                                    && no_exe_unit_dependency
                                                    ? 1'b1 : 1'b0;
                
            end else begin  // clear FP units          
                assign clear_rd[i] = (rd_used[i] == waw_rd) && (~reg_write_new && FP_reg_write_new)
                                                    && (waw_rs1 != waw_rd || waw_rs2 != waw_rd || (waw_rs3 != waw_rd && is_R4_instruction))
//                                                    && all_uu_rd_busy[i]  // it's busy flag if uu_rd actually used or not
                                                    && no_exe_unit_dependency
                                                    ? 1'b1 : 1'b0;
            end

          /* NOTE: use "&& (waw_rd != waw_rs1 || waw_rd != waw_rs2)" to solve this special case ...
                            -- mul x3, x1, x2
                            -- mul x3, x1, x3
          */
          
        end
    endgenerate

endmodule
