import riscv_types::*;


module rv32i #(
    parameter DMEM_DEPTH = 1024, 
    parameter IMEM_DEPTH = 1024
)(
    input logic clk, 
    input logic reset_n,
    //tracer
//   `ifdef TRACER_ENABLE
    // Add output ports for tracer signals
    output logic [31:0] rvfi_insn,
    output logic [4:0]  rvfi_rs1_addr,
    output logic [4:0]  rvfi_rs2_addr,
    output logic [31:0] rvfi_rs1_rdata,
    output logic [31:0] rvfi_rs2_rdata,
    output logic [4:0]  rvfi_rd_addr,
    output logic [31:0] rvfi_rd_wdata,
    output logic [31:0] rvfi_pc_rdata,
    output logic [31:0] rvfi_pc_wdata,
    output logic [31:0] rvfi_mem_addr,
    output logic [31:0] rvfi_mem_wdata,
    output logic [31:0] rvfi_mem_rdata,
    output logic        rvfi_valid,
//    `endif
    // memory bus   -   these signals between mem-stage, in datapath, and DMEM module
    output logic [31:0] mem_addr_mem,      // mem-stage address to DMEM address
    output logic [31:0] mem_wdata_mem,
    output logic mem_write_mem,
    output logic [2:0] mem_op_mem,            // used for data-alignment logic (lw, lh, lb instructions)
    input logic [31:0] mem_rdata_mem,       // DMEM data to mem-stage --> (output of DMEM)
    output logic mem_read_mem,

    // inst mem access
    output logic [31:0] current_pc,
    input logic [31:0] inst,

    // stall signal from wishbone 
    input logic stall_pipl,
    output logic if_id_reg_en
);
    
    // controller to the data path 
    logic reg_write_id; 
    logic mem_write_id;
    logic mem_to_reg_id; 
    logic branch_id; 
    logic alu_src_id;
    logic jump_id; 
    logic lui_id;
    logic auipc_id;
    logic jal_id;
    logic [2:0] alu_op_id;      
    alu_t alu_ctrl_id; 
    logic pc_sel_mem;
    logic multicycle_hazard;
    logic pre_exe_stall;
    logic [8:0] p_signal_start_id;
    logic [6:0] p_stall;
    logic [8:0] p_signal_last;
    priority_t  p_sel_exe;    // used with priority-Mux
    
    // Floating point signals
    logic rdata1_int_FP_sel_id;          // 0: integer  ----  1: float
    logic rdata2_int_FP_sel_id;
    logic rdata1_int_FP_sel_exe;      // to avoid dependecy between int and FP
    logic rdata2_int_FP_sel_exe;      // to avoid dependecy between int and FP
    logic FP_reg_write_id;                  // write_enable signal for FP registers-file
    logic FP_reg_write_exe;              // copies will be passed through stages in Datapath
    logic FP_reg_write_mem;
    logic FP_reg_write_wb;

    // data path to the controller
    logic [6:0] opcode_id;
    logic [6:0] fun7_5_id;         // (new) MOVED TO ID STAGE
    logic [2:0] fun3_id, fun3_mem; // (new) MOVED TO ID STAGE
    logic zero_mem;
    logic jump_mem;
    logic branch_mem;
    logic [8:0] p_signal_start_exe;
    logic div_unit_busy;
    logic fsqrt_unit_busy;
    logic fdiv_unit_busy;
    logic rd_busy;
    /* NOTE: if you changed the name of "fun7_5_exe" signal here,
                  make sure to change it also inside "data_path_inst" and "controller_inst"
                  modules as well
    */

    // data path to the controller (forwarding unit)
    wire [4:0] rs1_id;
    wire [4:0] rs2_id;
    wire [4:0] rs1_exe;
    wire [4:0] rs2_exe;
    wire [4:0] rs2_mem;
    wire [4:0] rd_mem;
    wire [4:0] rd_wb;
    wire reg_write_mem;
    wire reg_write_wb;

    // controller(forwarding unit) to the data path 
    wire forward_rd1_id;
    wire forward_rd2_id;
    wire [1:0] forward_rd1_exe;
    wire [1:0] forward_rd2_exe;
    wire forward_rd2_mem;
    
    // TODO: (new) forwarding operand 3 for R4 unit
    wire [4:0] rs3_id;
    wire [4:0] rs3_exe;
    wire forward_rd3_id;
    wire [1:0] forward_rd3_exe;


    // data path to the controller (hazard handler)
    wire mem_to_reg_exe;
    wire [4:0] rd_exe;

    // signals to control the flow of the pipeline (handling hazards, stalls ... )
    logic if_id_reg_clr;
    logic id_exe_reg_clr;
    logic exe_mem_reg_clr;
    logic mem_wb_reg_clr;

    logic id_exe_reg_en;
    logic exe_mem_reg_en;
    logic mem_wb_reg_en;
    logic pc_reg_en;
    logic branch_hazard;

    // inst mem access
    logic [31:0] current_pc_if;
    logic [31:0] inst_if;

    logic mem_to_reg_mem;

    assign current_pc = current_pc_if;
    assign inst_if = inst;
    
//    data_path #(
//        .DMEM_DEPTH(DMEM_DEPTH),
//        .IMEM_DEPTH(IMEM_DEPTH)
//    ) data_path_inst (
//        .*
//    );
//    control_unit controller_inst(
//        .*
//    );

    // Explicit instantiation for  tracer IP
    data_path #(
        .DMEM_DEPTH(DMEM_DEPTH),
        .IMEM_DEPTH(IMEM_DEPTH)
    ) data_path_inst (
        .clk(clk),
        .reset_n(reset_n),
        //TRACER
//          `ifdef TRACER_ENABLE
.rvfi_insn(rvfi_insn),      
.rvfi_rs1_addr(rvfi_rs1_addr),  
.rvfi_rs2_addr(rvfi_rs2_addr),  
.rvfi_rs1_rdata(rvfi_rs1_rdata), 
.rvfi_rs2_rdata(rvfi_rs2_rdata), 
.rvfi_rd_addr(rvfi_rd_addr),   
.rvfi_rd_wdata(rvfi_rd_wdata),  
.rvfi_pc_rdata(rvfi_pc_rdata),  
.rvfi_pc_wdata(rvfi_pc_wdata),  
.rvfi_mem_addr(rvfi_mem_addr),  
.rvfi_mem_wdata(rvfi_mem_wdata), 
.rvfi_mem_rdata(rvfi_mem_rdata), 
.rvfi_valid(rvfi_valid),      
//        `endif
        .opcode_id(opcode_id),
        .fun7_5_id(fun7_5_id),
        .fun3_id(fun3_id),
        .fun3_mem(fun3_mem),
        .zero_mem(zero_mem),
        .jump_mem(jump_mem),
        .branch_mem(branch_mem),

        .reg_write_id(reg_write_id),
        .mem_write_id(mem_write_id),
        .mem_to_reg_id(mem_to_reg_id),
        .branch_id(branch_id),
        .alu_src_id(alu_src_id),
        .jump_id(jump_id),
        .lui_id(lui_id),
        .auipc_id(auipc_id),
        .jal_id(jal_id),
        .alu_op_id(alu_op_id),

        .alu_ctrl_id(alu_ctrl_id),
        .pc_sel_mem(pc_sel_mem),
        .pre_exe_stall(pre_exe_stall),
        .multicycle_hazard(multicycle_hazard),

        .rdata1_int_FP_sel_id(rdata1_int_FP_sel_id),
        .rdata2_int_FP_sel_id(rdata2_int_FP_sel_id),
        .rdata1_int_FP_sel_exe(rdata1_int_FP_sel_exe),
        .rdata2_int_FP_sel_exe(rdata2_int_FP_sel_exe),
        .FP_reg_write_id(FP_reg_write_id),
        .FP_reg_write_exe(FP_reg_write_exe),
        .FP_reg_write_mem(FP_reg_write_mem),
        .FP_reg_write_wb(FP_reg_write_wb),

        .p_sel_exe(p_sel_exe),
        .p_signal_start_id(p_signal_start_id),
        .p_signal_start_exe(p_signal_start_exe),
        .p_signal_last(p_signal_last),
        .p_stall(p_stall),

        .div_unit_busy(div_unit_busy),
        .fsqrt_unit_busy(fsqrt_unit_busy),
        .fdiv_unit_busy(fdiv_unit_busy),
        .rd_busy(rd_busy),

        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rs1_exe(rs1_exe),
        .rs2_exe(rs2_exe),
        .rs2_mem(rs2_mem),
        .rd_mem(rd_mem),
        .rd_wb(rd_wb),
        .reg_write_mem(reg_write_mem),
        .reg_write_wb(reg_write_wb),

        .forward_rd1_id(forward_rd1_id),
        .forward_rd2_id(forward_rd2_id),
        .forward_rd1_exe(forward_rd1_exe),
        .forward_rd2_exe(forward_rd2_exe),
        .forward_rd2_mem(forward_rd2_mem),

        .rs3_id(rs3_id),
        .rs3_exe(rs3_exe),
        .forward_rd3_id(forward_rd3_id),
        .forward_rd3_exe(forward_rd3_exe),

        .mem_to_reg_exe(mem_to_reg_exe),
        .rd_exe(rd_exe),

        .if_id_reg_clr(if_id_reg_clr),
        .id_exe_reg_clr(id_exe_reg_clr),
        .exe_mem_reg_clr(exe_mem_reg_clr),
        .mem_wb_reg_clr(mem_wb_reg_clr),

        .if_id_reg_en(if_id_reg_en),
        .id_exe_reg_en(id_exe_reg_en),
        .exe_mem_reg_en(exe_mem_reg_en),
        .mem_wb_reg_en(mem_wb_reg_en),
        .pc_reg_en(pc_reg_en),
        .branch_hazard(branch_hazard),

        .mem_addr_mem(mem_addr_mem),
        .mem_wdata_mem(mem_wdata_mem),
        .mem_op_mem(mem_op_mem),
        .mem_rdata_mem(mem_rdata_mem),
        .mem_write_mem(mem_write_mem),
        .mem_to_reg_mem(mem_to_reg_mem),

        .current_pc_if(current_pc_if),
        .inst_if(inst_if)
    );

    
    control_unit controller_inst(
        .opcode_id(opcode_id),
        .fun7_5_id(fun7_5_id),
        .fun3_id(fun3_id),
        .fun3_mem(fun3_mem),
        .zero_mem(zero_mem),
        .jump_mem(jump_mem),
        .branch_mem(branch_mem),

        .reg_write_id(reg_write_id),
        .mem_write_id(mem_write_id),
        .mem_to_reg_id(mem_to_reg_id),
        .branch_id(branch_id),
        .alu_src_id(alu_src_id),
        .jump_id(jump_id),
        .lui_id(lui_id),
        .auipc_id(auipc_id),
        .jal_id(jal_id),
        .alu_op_id(alu_op_id),

        .rdata1_int_FP_sel_id(rdata1_int_FP_sel_id),
        .rdata2_int_FP_sel_id(rdata2_int_FP_sel_id),
        .rdata1_int_FP_sel_exe(rdata1_int_FP_sel_exe),
        .rdata2_int_FP_sel_exe(rdata2_int_FP_sel_exe),
        .FP_reg_write_id(FP_reg_write_id),
        .FP_reg_write_exe(FP_reg_write_exe),
        .FP_reg_write_mem(FP_reg_write_mem),
        .FP_reg_write_wb(FP_reg_write_wb),

        .p_sel_exe(p_sel_exe),
        .p_signal_start_id(p_signal_start_id),
        .p_signal_start_exe(p_signal_start_exe),
        .p_signal_last(p_signal_last),
        .p_stall(p_stall),

        .div_unit_busy(div_unit_busy),
        .fsqrt_unit_busy(fsqrt_unit_busy),
        .fdiv_unit_busy(fdiv_unit_busy),
        .rd_busy(rd_busy),

        .alu_ctrl_id(alu_ctrl_id),

        .pc_sel_mem(pc_sel_mem),

        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rs1_exe(rs1_exe),
        .rs2_exe(rs2_exe),
        .rs2_mem(rs2_mem),
        .rd_mem(rd_mem),
        .rd_wb(rd_wb),
        .reg_write_mem(reg_write_mem),
        .reg_write_wb(reg_write_wb),

        .forward_rd1_id(forward_rd1_id),
        .forward_rd2_id(forward_rd2_id),
        .forward_rd1_exe(forward_rd1_exe),
        .forward_rd2_exe(forward_rd2_exe),
        .forward_rd2_mem(forward_rd2_mem),

        .rs3_id(rs3_id),
        .rs3_exe(rs3_exe),
        .forward_rd3_id(forward_rd3_id),
        .forward_rd3_exe(forward_rd3_exe),

        .mem_to_reg_exe(mem_to_reg_exe),
        .rd_exe(rd_exe),

        .if_id_reg_clr(if_id_reg_clr),
        .id_exe_reg_clr(id_exe_reg_clr),
        .exe_mem_reg_clr(exe_mem_reg_clr),
        .mem_wb_reg_clr(mem_wb_reg_clr),

        .if_id_reg_en(if_id_reg_en),
        .id_exe_reg_en(id_exe_reg_en),
        .exe_mem_reg_en(exe_mem_reg_en),
        .mem_wb_reg_en(mem_wb_reg_en),
        .pc_reg_en(pc_reg_en),
        .pre_exe_stall(pre_exe_stall),
        .multicycle_hazard(multicycle_hazard),
        .branch_hazard(branch_hazard),

        .stall_pipl(stall_pipl)
    );


    assign mem_read_mem = mem_to_reg_mem;

endmodule 