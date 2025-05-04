module forwarding_unit (
    input wire [4:0] rs1_id,
    input wire [4:0] rs2_id,
    input wire [4:0] rs1_exe,
    input wire [4:0] rs2_exe,
    input wire [4:0] rs2_mem,
    input wire [4:0] rd_mem,
    input wire [4:0] rd_wb,
    input wire reg_write_mem,
    input wire reg_write_wb,

    output wire forward_rd1_id,
    output wire forward_rd2_id,
    output wire [1:0] forward_rd1_exe,
    output wire [1:0] forward_rd2_exe,
    output wire forward_rd2_mem,
    
    // signals to avoid dependecy between integer and FP values
    input logic rdata1_int_FP_sel_id,
    input logic rdata2_int_FP_sel_id,
    input logic rdata1_int_FP_sel_exe,
    input logic rdata2_int_FP_sel_exe,

    // forwarding operand 3 for R4 unit
    input wire [4:0] rs3_id,
    input wire [4:0] rs3_exe,
    output wire forward_rd3_id,
    output wire [1:0] forward_rd3_exe,
        
    // FP signals
    input wire FP_reg_write_id,     // not used
    input wire FP_reg_write_exe,     // not used
    input wire FP_reg_write_mem,
    input wire FP_reg_write_wb
);

//  Forwarding to id stage
    assign forward_rd1_id     = ((reg_write_wb & (rd_wb!=0)) | (FP_reg_write_wb & rdata1_int_FP_sel_id)) & (rs1_id === rd_wb);
    assign forward_rd2_id     = ((reg_write_wb & (rd_wb!=0)) | (FP_reg_write_wb & rdata2_int_FP_sel_id)) & (rs2_id === rd_wb);
//  Forwarding to exe stage
    assign forward_rd1_exe[0] = ((reg_write_mem & rd_mem!=0) | (FP_reg_write_mem & rdata1_int_FP_sel_exe)) & (rs1_exe === rd_mem);
    assign forward_rd1_exe[1] = ((reg_write_wb & rd_wb!=0) |(FP_reg_write_wb & rdata1_int_FP_sel_exe)) & (rs1_exe === rd_wb ) & ~forward_rd1_exe[0];
    assign forward_rd2_exe[0] = ((reg_write_mem & rd_mem!=0) | (FP_reg_write_mem & rdata2_int_FP_sel_exe)) & (rs2_exe === rd_mem);
    assign forward_rd2_exe[1] = ((reg_write_wb & rd_wb!=0) |(FP_reg_write_wb & rdata2_int_FP_sel_exe)) & (rs2_exe === rd_wb ) & ~forward_rd2_exe[0];
//  Forwarding to mem stage
    assign forward_rd2_mem    = (reg_write_wb | FP_reg_write_wb) & (rs2_mem === rd_wb ) & (rd_wb!=0 );


    // forwarding operand 3 in exe stage  for R4_unit...
    assign forward_rd3_id     = FP_reg_write_wb & (rs3_id === rd_wb );
    assign forward_rd3_exe[0] = FP_reg_write_mem & (rs3_exe === rd_mem);
    assign forward_rd3_exe[1] = FP_reg_write_wb & (rs3_exe === rd_wb ) & ~forward_rd3_exe[0];


endmodule