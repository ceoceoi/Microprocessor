import riscv_types::*;

module control_unit(
    input logic [6:0] opcode_id,
    input logic [6:0] fun7_5_id, 
    input logic [2:0] fun3_id, fun3_mem,  
    input logic zero_mem,
    input logic jump_mem, 
    input logic branch_mem,
    
    // outputs from the decode controller
    output logic reg_write_id, 
    output logic mem_write_id, 
    output logic mem_to_reg_id, 
    output logic branch_id, 
    output logic alu_src_id,
    output logic jump_id, 
    output logic lui_id,
    output logic auipc_id, 
    output logic jal_id,
    output logic [2:0] alu_op_id,
    
    // floating-point extension signals
    output logic rdata1_int_FP_sel_id,
    output logic rdata2_int_FP_sel_id,
    input logic rdata1_int_FP_sel_exe,  // to avoid dependecy between int and FP
    input logic rdata2_int_FP_sel_exe,  // to avoid dependecy between int and FP
    output logic FP_reg_write_id,
    input logic FP_reg_write_exe,       // from datapath
    input logic FP_reg_write_mem,
    input logic FP_reg_write_wb,
    
    // "priority" signals to control ALU modules (MulU, DivU, FPU, FAdd_Sub ... etc.)
    output priority_t p_sel_exe,          // used with priority-Mux to choose single result from EXE to MEM stage
    output logic [8:0] p_signal_start_id, // to resolve back-to-back multicycle instructions hazard
    input logic [8:0] p_signal_start_exe,   // send it to functional units
    input logic [8:0] p_signal_last,      // comes from ALU modules
     output logic [6:0] p_stall,                // to stall IF and ID stages, and other functional units that cause collision
    input logic div_unit_busy,  
    input logic fsqrt_unit_busy,
    input logic fdiv_unit_busy, 
    input logic  rd_busy,

    // alu_controller output
    output alu_t alu_ctrl_id, // in ID stage to resolve back-to-back multicycle instructions hazard
    
    // branch controller output 
    output wire pc_sel_mem,

    // forwarding unit stuff
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
    
    // Forwarding operand 3 for R4 unit
    input wire [4:0] rs3_id,
    input wire [4:0] rs3_exe,
    output wire forward_rd3_id,
    output wire [1:0] forward_rd3_exe,

    // hazard handler data required from the data path
    input wire mem_to_reg_exe,
    input wire [4:0] rd_exe,

    // signals to control the flow of the pipeline
    output logic if_id_reg_clr, 
    output logic id_exe_reg_clr,
    output logic exe_mem_reg_clr,
    output logic mem_wb_reg_clr,

    output logic if_id_reg_en, 
    output logic id_exe_reg_en,
    output logic exe_mem_reg_en,
    output logic mem_wb_reg_en,
    output logic pc_reg_en,
    output logic pre_exe_stall, 
    output logic multicycle_hazard,
    output logic branch_hazard,

    input logic stall_pipl
);

    logic r_type_id;
    
    // Decode Controller --> a decoder  generates control-signals that required in ID-stage within datapath
    decode_control dec_ctrl_inst (
        .opcode(opcode_id),
        .reg_write(reg_write_id),
        .mem_write(mem_write_id),
        .mem_to_reg(mem_to_reg_id),
        .branch(branch_id),
        .alu_src(alu_src_id),
        .jump(jump_id),
        .alu_op(alu_op_id),
        .lui(lui_id),
        .auipc(auipc_id),
        .jal(jal_id),
        .r_type(r_type_id),
        // floating point signals
        .rdata1_int_FP_sel(rdata1_int_FP_sel_id),
        .rdata2_int_FP_sel(rdata2_int_FP_sel_id),
        .FP_reg_write(FP_reg_write_id),
        // special case in R_FLOAT instructions
        .fun7_5_id(fun7_5_id)
    );

    wire exe_use_rs1_id;
    wire exe_use_rs2_id;

    assign exe_use_rs1_id = ~(auipc_id | lui_id);
    assign exe_use_rs2_id = r_type_id | branch_id;

    // ALU Controller  --> specify which operation should be used (ADDI, SUB, SLL ... etc.)
    alu_control alu_controller_inst (
        .fun3(fun3_id),     
        .fun7(fun7_5_id),    
        .alu_op(alu_op_id),   
        .alu_ctrl(alu_ctrl_id)
        , .rs2(rs2_id),
        .opcode(opcode_id) 
    );

    branch_controller branch_controller_inst (
        .fun3(branch_t'(fun3_mem)),
        .branch(branch_mem),
        .jump(jump_mem),
        .zero(zero_mem),
        .pc_sel(pc_sel_mem)
    );

    forwarding_unit forwarding_unit_inst(
        .*
    );

    // detect if there is load hazard
    wire load_hazard;
    logic mem_read_exe;
    assign mem_read_exe = mem_to_reg_exe;
    
    hazard_handler hazard_handler_inst (
        .*
    );

    pipeline_controller pipeline_controller_inst(
        .load_hazard(load_hazard),
        .branch_hazard(branch_hazard),
        .stall_pipl(stall_pipl),
        .*,
        .p_system_stall(p_stall[5])
        // .p_system_stall(p_stall[6])  // TODO: to include R4 too
        
    );

    /* these modules added to manage and control functional units (Mul, Div, FPU, FAdd_Sub ... etc.) in EXE stage ...    
    NOTE: "p_signal_start" goes to functional units to indicate that data is valid to be received by the desired unit
    */
    logic priority_hazard;
    
    // priority decoder - ID
    P_Decoder priority_dec_inst (
        .alu_ctrl(alu_ctrl_id),
        .rd_busy(rd_busy),
        .P_signal_start(p_signal_start_id)      // in ID stage to resolve back-to-back multicycle instructions hazard
    );

    
    // priority controller
    priority_controller priority_ctrl_inst(
        .p_signal(p_signal_last),                         // From all functional units (ALU-modules)
        .p_signal_start(p_signal_start_exe[6:0]),    // From priority decoder (in EXE stage)
        .rd_busy(rd_busy),
        .stall(p_stall), // send to "pipeline_controller" module, to stall the system
        .id_exe_reg_clr_priority(priority_hazard),     // to "pipeline_controller" module
        .p_sel(p_sel_exe)                                                  // to EXE stage in datapath
    );

endmodule
