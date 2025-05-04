import riscv_types::*;

module data_path #(
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
    // outputs to controller
    output logic [6:0] opcode_id,
    output logic [6:0] fun7_5_id,
    output logic [2:0] fun3_id, fun3_mem,
    output logic zero_mem,
    output logic jump_mem, 
    output logic branch_mem,

    // control signals from the controller 
    input logic reg_write_id,       // NOTE: it has copies for each pipeline-stage
    input logic mem_write_id,       // wanna write on DMEM?   -->  (selector)
    input logic mem_to_reg_id,      // which data should be written on reg. file (selector) ---> reg_wdata_wb = selector? DMEM data : alu_result
    input logic branch_id, 
    input logic alu_src_id,         // selector --> ALU_operand2 = selector? imm : rs2
    input logic jump_id, 
    input logic lui_id,
    input logic auipc_id, 
    input logic jal_id,
    input logic [2:0] alu_op_id,

    input alu_t alu_ctrl_id,  
    input logic pc_sel_mem,             // 0: next address ---- 1: address of that label (jump)
    input logic pre_exe_stall,
    input logic multicycle_hazard,
    
    // Floating-point extension (control signals)
    input logic rdata1_int_FP_sel_id,       // 0: integer ---- 1: float
    input logic rdata2_int_FP_sel_id,
    output logic rdata1_int_FP_sel_exe,  // to avoid dependecy int and FP
    output logic rdata2_int_FP_sel_exe, // to avoid dependecy int and FP
    input logic FP_reg_write_id,               // reg_write enable signal but for FP registers-file
    output logic FP_reg_write_exe,         // copies of  "FP_reg_write_id" to be passed through pipeline-staegs
    output logic FP_reg_write_mem,
    output logic FP_reg_write_wb,
    
    // "priority" signals to control ALU modules (MulU, DivU, FPU, FAdd_Sub ... etc.)
    input priority_t p_sel_exe,            // used with priority-Mux
    input logic [8:0] p_signal_start_id,
    output logic [8:0] p_signal_start_exe,
    output logic [8:0] p_signal_last,   // from ALU modules (functional units)
    input logic [6:0] p_stall, 
    /* Notes about "p_stall" ...
        - p_stall [0] : stall FDIV_unit
        - p_stall [1] : stall FMUL_unit
        - p_stall [2] : stall FADD_SUB_unit
        - p_stall [3] : stall DIV_unit
        - p_stall [4] : stall FSQRT_unit
        - p_stall [5] : whenever a collision happens, it stall the system (IF and ID stages)  --> used in "controller_inst" (not here)
        - p_stall [6] : stall R4_unit
    */
    /* prioirty from highest to lowest...
        p_signal [0]  fsqrt     (multi-cycle)
        p_signal [1] div     (multi-cycle)
        p_signal [2] f_div     (pipelined/multi-cycle) --> but currently (multi-cycle)
        p_signal [3] R4     (multi-cycle) --> but currently (single-cycle) -> because of fmul
        p_signal [4] f_mul     (pipelined)
        p_signal [5] f_add_sub     (pipelined)
         p_signal [6] mul     (single-cycle)
         p_signal [7] fpu     (single-cycle)
         p_signal [8] alu     (single-cycle)
    */
    
    // TODO (done): we need to use busy_unit signals as ports if we have single p_decoder in ID stage only.
    output logic div_unit_busy,     // stall signals used with multi-cycles units in EXE stage
//    output logic mul_unit_busy,   // actually, these 3 unit_busy signals aren't used at all (:
    output logic fdiv_unit_busy,
    output logic fsqrt_unit_busy,
    // NOTE: these 2 signals used stall the whole system until div_unit & mul_unit finish, and don't receive other div or mul instructions more
    output logic rd_busy,
//    output logic raw_resolution, // NEWLY ADDED 
    // TODO: take the updated version form Nehal since she resolved the multi-cycle hazard
//    output logic stop_single_cycle, // to avoid passing the same result multiple times through the priority mux
     
    
    // forwarding unit stuff
    output wire [4:0] rs1_id,
    output wire [4:0] rs2_id,
    output wire [4:0] rs1_exe,
    output wire [4:0] rs2_exe,
    output wire [4:0] rs2_mem,
    output wire [4:0] rd_mem,
    output wire [4:0] rd_wb,
    output wire reg_write_mem,
    output wire reg_write_wb,

    input  wire forward_rd1_id,     // selectors for forwarding-Mux units
    input  wire forward_rd2_id,
    input  wire [1:0] forward_rd1_exe,
    input  wire [1:0] forward_rd2_exe,
    input  wire forward_rd2_mem,
    
    // Forwarding operand 3 for R4 unit
    output wire [4:0] rs3_id,
    output wire [4:0] rs3_exe,
    input wire forward_rd3_id,
    input wire [1:0] forward_rd3_exe,


    // hazard handler data required from the data path
    output  wire mem_to_reg_exe,
    output  wire [4:0] rd_exe,

    // signals to control the flow of the pipeline
    input logic if_id_reg_clr,              // they're used for clearing/flush pipeline registers in case the branch or jump instructions have applied
    input logic id_exe_reg_clr,
    input logic exe_mem_reg_clr,
    input logic mem_wb_reg_clr,

    input logic if_id_reg_en, 
    input logic id_exe_reg_en,
    input logic exe_mem_reg_en,
    input logic mem_wb_reg_en,
    input logic pc_reg_en,
    input logic branch_hazard,


    // memory bus   -->     these signals between mem-stage here and DMEM module (NOTE: passed through wishbone)
    output logic [31:0] mem_addr_mem,      // mem-stage address to DMEM address
    output logic [31:0] mem_wdata_mem, 
    output logic [2:0] mem_op_mem,            // used for data-alignment logic (lw, lh, lb instructions)
    input logic [31:0] mem_rdata_mem,       // DMEM data to mem-stage --> (output of DMEM)
    output logic mem_write_mem,
    output logic mem_to_reg_mem,

    // inst mem access
    output logic [31:0] current_pc_if,
    input logic [31:0] inst_if          // comes from wishbone
);
    
//    localparam num_rds = 36;     // each multi-cycle unit needs one, except pipelined units
    localparam num_rds = 12;     // each multi-cycle unit needs one, except pipelined units
    localparam int_uu_rds = 1;
    localparam rd_addr_width = 5;
    
    // signals come from functional units to solve WAW issue
    logic [rd_addr_width-1 : 0] div_uu_rd;      // it's abbreviation for "div unit uses that_rd"
    logic [num_rds-1 : 0] clear_uu_rd;     // clear signal for each rd used in EXE stage
    logic [rd_addr_width-1 : 0] fadd_sub_uu_rd [0 : 1];
    logic [rd_addr_width-1 : 0] fmul_uu_rd;
    logic [rd_addr_width-1 : 0] fsqrt_uu_rd;
    logic [rd_addr_width-1 : 0] R4_uu_rd [0 : 4];
//    logic [rd_addr_width-1 : 0] fdiv_uu_rd [0: num_rds-1-11];
    logic [rd_addr_width-1 : 0] fdiv_uu_rd;
    
    // reg_write & FP_reg_write signals
    logic [1:0] fadd_uu_reg_write, fadd_uu_FP_reg_write;
    logic fmul_uu_reg_write, fmul_uu_FP_reg_write;
    logic fsqrt_uu_reg_write, fsqrt_uu_FP_reg_write;
    logic [4:0] R4_uu_reg_write, R4_uu_FP_reg_write;
//    logic [num_rds-1-11 : 0] fdiv_uu_reg_write, fdiv_uu_FP_reg_write;
    logic fdiv_uu_reg_write, fdiv_uu_FP_reg_write;
    // ==================================================================================
    // WAW solution ...
    // clear duplicated rd when Write-After-Write (WAW) occured ...
    
    // TODO: increase number of rd when you get the updated versions of units
    // "all_uu_rd" is abbreviation for "all rd that units use"
    logic [rd_addr_width-1 : 0] all_uu_rd [0 : num_rds-1];
    logic [num_rds-1 : 0] all_uu_rd_busy;   // (new) busy flag for each  rd in all_uu_rd
    logic [num_rds-1 : 0] uu_reg_write;   // reg_write inside that unit;
    logic [num_rds-1 : 0] uu_FP_reg_write;  // FP_reg_write inside that unit;


    // define internal signals to be passed through pipeline stages (IF, ID, EXE, MEM, WB)
    logic [31:0] inst_id;
    logic [31:0] current_pc_id, current_pc_exe, current_pc_mem;
    logic [31:0] reg_rdata1_id, reg_rdata1_exe;       // rdata1_id --> bus_id --> ID/EXE reg --> bus_exe --> rdata1_exe --> ... --> alu_operand_1
    logic [31:0] reg_rdata2_id, reg_rdata2_exe;       // it could be FP or integer
    logic [31:0] reg_rdata3_id, reg_rdata3_exe;       // used with R4_unit and they always FP values
    logic [31:0] reg_wdata_wb;                                    // write-back signal that passed through stages and used for "int_reg_file_inst"
    logic [31:0] imm_id,imm_exe, imm_mem;
    logic [31:0] pc_plus_4_if1, pc_plus_4_id, pc_plus_4_exe, pc_plus_4_mem;
    logic [31:0] pc_jump_exe, pc_jump_mem;
    logic [31:0] next_pc_if1;
    logic [31:0] non_mem_result_wb;     // simply, it's alu_result that passed directly to wdata_wb in write-back stage

    logic [2:0] fun3_exe;
    alu_t alu_ctrl_exe; 
    logic alu_src_exe;
    logic reg_write_exe;
    logic mem_write_exe;
    logic branch_exe;
    logic jump_exe;
    logic lui_exe, lui_mem;
    logic auipc_exe;
    logic jal_exe;
    logic zero_exe;                     // zero flag if the alu_result is zero
    logic mem_to_reg_wb;
    logic [31:0] alu_result_exe, alu_result_mem;
    logic [31:0] result_mem;            // alu_result but moved to MEM stage  --->   assign non_mem_result_wb = result_mem;
    logic [31:0] rdata2_frw_mem;
    logic [31:0] current_pc_if1;
    logic [31:0] current_pc_if2, pc_plus_4_if2, inst_if2;
    
    
    program_counter PC_inst (
        .*,
        .en(pc_reg_en | branch_hazard)
    );

    // pc adder 
    assign pc_plus_4_if1 = current_pc_if1 + 4;

    mux2x1 #(
        .n(32)
    ) next_pc_mux (
        .sel(pc_sel_mem),
        .in0(pc_plus_4_if1),        // next address
        .in1(pc_jump_mem),     // jump address  --> it has its own adder in EXE stage (doesn't use ALU)
        .out(next_pc_if1)
    );

    assign current_pc_if = current_pc_if1;

    // ============================================
    //              IF1-IF2 Pipeline Register
    // ============================================
    
    logic if_id_reg_en_ff;
    logic if_id_reg_clr_ff;
    n_bit_reg #(
        .n(1)
    ) if_id_reg_en_ff_inst (
        .*,
        .data_i(if_id_reg_en),
        .data_o(if_id_reg_en_ff),
        .wen(1'b1)
    );
    n_bit_reg #(
        .n(1)
    ) if_id_reg_clr_ff_inst (
        .*,
        .data_i(if_id_reg_clr),
        .data_o(if_id_reg_clr_ff),
        .wen(1'b1)
    );

    // (Pipeline) - IF1_end Bus ,  IF2_start Bus
    if1_if2_reg_t if1_if2_bus_i, if1_if2_bus_o;
    
    // (Pipeline) IF1_end Bus
    assign if1_if2_bus_i = {
        current_pc_if1,
        pc_plus_4_if1
    };

    // (Pipeline) IF1/IF2 register
    n_bit_reg_wclr #(
        .n($bits(if1_if2_reg_t)) // Automatically sets width
    ) if1_if2_reg (
        .clk(clk),
        .reset_n(reset_n),
        .clear(if_id_reg_clr),
        .wen(if_id_reg_en),
        .data_i(if1_if2_bus_i),           // (Pipeline) IF1_end Bus
        .data_o(if1_if2_bus_o)         // (Pipeline) IF2_start Bus
    );

    assign current_pc_if2  = if1_if2_bus_o.current_pc;
    assign pc_plus_4_if2   = if1_if2_bus_o.pc_plus_4;

    logic [31:0] inst_if_ff;

    // a normal register that store current instruction or skip it if any jump has applied
    n_bit_reg_wclr #(
        .n(32),
        .CLR_VALUE(32'h00000013)
    ) if2_reg (
        .*,
        .data_i(inst_if),           // next_new instruction --> note: it comes from wishbone (from outside)
        .data_o(inst_if_ff),    // current instruction
        .wen(if_id_reg_en_ff),
        .clear(if_id_reg_clr)
    );
    assign inst_if2 = if_id_reg_en_ff ? inst_if : inst_if_ff;


    // ============================================
    //              IF-ID Pipeline Register
    // ============================================
    
    // (Pipeline) - IF2_end Bus ,  ID_start Bus
    if_id_reg_t if_id_bus_i, if_id_bus_o;

    // (Pipeline) IF2_end Bus
    assign if_id_bus_i = {
        current_pc_if2,
        pc_plus_4_if2,
        inst_if2
    };
    
    // (Pipeline) IF2/ID register
    n_bit_reg_wclr #(
        .n($bits(if_id_reg_t)) // Automatically sets width
    ) if_id_reg (
        .clk(clk),
        .reset_n(reset_n),
        .clear(if_id_reg_clr | if_id_reg_clr_ff),
        .wen(if_id_reg_en),
        .data_i(if_id_bus_i),           // (Pipeline) IF2_end Bus
        .data_o(if_id_bus_o)         // (Pipeline) ID_start Bus
    );

    // extract signals from ID_start Bus to be used later in ID-stage
    assign current_pc_id  = if_id_bus_o.current_pc;
    assign pc_plus_4_id   = if_id_bus_o.pc_plus_4;
    assign inst_id        = if_id_bus_o.inst;


    // ============================================
    //                Decode Stage 
    // ============================================

    // Giving descriptive names to field of instructions 
    logic [4:0] rd_id;
    assign rs1_id    = inst_id[19:15];
    assign rs2_id    = inst_id[24:20];
    assign rd_id     = inst_id[11:7] ;
    assign fun3_id   = inst_id[14:12];
    assign fun7_5_id = inst_id[31:25];
    assign opcode_id = inst_id[6:0];
    
    logic [31:0] reg_rdata1, reg_rdata2;
    logic [31:0] int_reg_rdata1, int_reg_rdata2;
    logic [31:0] FP_reg_rdata1, FP_reg_rdata2;

    // 3rd operand of R4 instructions type
    assign rs3_id    = inst_id[31:27];
    logic [31:0] FP_reg_rdata3;
    logic is_R4_instruction_id, is_R4_instruction_exe; // flag tells us if the current instruction is R4 type which uses 3 registers
    assign is_R4_instruction_id = (alu_ctrl_id == FMADD)
                                                        ||(alu_ctrl_id == FMSUB)
                                                        ||(alu_ctrl_id == FNMSUB)
                                                        ||(alu_ctrl_id == FNMADD);

    
    
    // register file (decode stage)
    reg_file reg_file_inst (
        .clk         (clk        ),
        .reset_n     (reset_n    ),
        .reg_write   (reg_write_wb),  // controllered by dec_ctrl_inst module (within control_unit)
        .raddr1      (rs1_id),
        .raddr2      (rs2_id),
        .waddr       (rd_wb),
        .wdata       (reg_wdata_wb),
        .rdata1      (int_reg_rdata1),      // it was "(reg_rdata1),"
        .rdata2      (int_reg_rdata2)      // it was "(reg_rdata2),"
        
        // 3rd op for R4_unit
        , .raddr3      ('b0),
        .rdata3      ()   // it's empty because R4 unit never use 3rd operand as integer value, it's always FP vallue. So it's not used
    );
    
    // register file (decode stage) instance for floating-point extension
    reg_file FP_reg_file_inst (
        .clk         (clk        ),
        .reset_n     (reset_n    ),
        .reg_write   (FP_reg_write_wb),  // controllered by dec_ctrl_inst module (within control_unit)
        .raddr1      (rs1_id),
        .raddr2      (rs2_id),
        .waddr       (rd_wb),
        .wdata       (reg_wdata_wb),
        .rdata1      (FP_reg_rdata1),
        .rdata2      (FP_reg_rdata2)
        
        // 3rd operand of R4_unit
        , .raddr3      (rs3_id),
        .rdata3      (FP_reg_rdata3)
    );

    // 2 MUXes to decide if the data used are integers or floats
    assign reg_rdata1 = rdata1_int_FP_sel_id? FP_reg_rdata1 : int_reg_rdata1;      // 1: float --- 0: integer
    assign reg_rdata2 = rdata2_int_FP_sel_id? FP_reg_rdata2 : int_reg_rdata2;
    // NOTE: the 3rd one is always FP data
    
    // Immediate unit (decode stage_)
    imm_gen imm_gen_inst (
        .inst(inst_id),
        .j_type(jal_id),
        .b_type(branch_id),
        .s_type(mem_write_id),
        .lui(lui_id),
        .auipc(auipc_id),
        .imm(imm_id)
    );

   // forwarding mux for rd1 (decode stage)
    mux2x1 #(32) reg_file_rd1_mux (
        .sel(forward_rd1_id),
        .in0(reg_rdata1),            // normal value (rdata1)
        .in1(reg_wdata_wb),     // forwarded value from wb stage
        .out(reg_rdata1_id)
    );

    // forwarding mux for rd2 (decode stage)
    mux2x1 #(32) reg_file_rd2_mux (
        .sel(forward_rd2_id),
        .in0(reg_rdata2),            // normal value (rdata2)
        .in1(reg_wdata_wb),     // forwarded value from wb stage
        .out(reg_rdata2_id)
    );
    
    // (3rd op) forwarding mux for rd3 to be used with R4_unit (decode stage)
    mux2x1 #(32) reg_file_rd3_mux (
        .sel(forward_rd3_id),
        .in0(FP_reg_rdata3),      // normal value (rdata3) --> it always FP value
        .in1(reg_wdata_wb),     // forwarded value from wb stage
        .out(reg_rdata3_id)
    );    
    
    // ============================================
    //             ID-EXE Pipeline Register
    // ============================================
    
    // (Pipeline) -   ID_end Bus  ,   EXE_start Bus
    id_exe_reg_t id_exe_bus_i, id_exe_bus_o;

    // (Pipeline) ID_end Bus
    assign id_exe_bus_i = {
        // data signals 
        current_pc_id, // 32
        pc_plus_4_id,  // 32
        rs1_id,           // 5 bits
        rs2_id,
        rd_id,
        fun3_id,        // 3 bits
        reg_rdata1_id,   // 32 bits
        reg_rdata2_id,
        imm_id,
        // control signals
        reg_write_id,
        mem_write_id,
        mem_to_reg_id,
        branch_id,
        alu_src_id,
        jump_id,
        lui_id,
        auipc_id,
        jal_id,
        p_signal_start_id,  
        alu_ctrl_id,
        
        // Floating point (FP) signals ...
        FP_reg_write_id
        , rdata1_int_FP_sel_id,
        rdata2_int_FP_sel_id
        
        // for 3rd operand of R4_unit 
        , rs3_id,     
        reg_rdata3_id     
        , is_R4_instruction_id     
        // NOTE: rdata3 is always FP, so no needs for create signal "rdata3_int_FP_sel_id" to distinguish it
    };

    // (Pipeline) ID/EXE register
    n_bit_reg_wclr #(
        .n($bits(id_exe_reg_t))
    ) id_exe_reg (
        .clk(clk),
        .reset_n(reset_n),
        .clear(id_exe_reg_clr),
        .wen(id_exe_reg_en),
        .data_i(id_exe_bus_i),           // (Pipeline) ID_end Bus
        .data_o(id_exe_bus_o)         // (Pipeline) EXE_start Bus
    );
    
    logic pipe_or_multi_p_last;  // indicates that "p_signal_last", came to the p_mux, belongs to a pipeline/multicycle unit
    assign pipe_or_multi_p_last = (|p_signal_last[5:0]);

    // extract signals from EXE_start Bus to be used later in EXE-stage ...
    // data signals 
    assign current_pc_exe  = id_exe_bus_o.current_pc; // 32
    assign pc_plus_4_exe   = id_exe_bus_o.pc_plus_4;  // 32
    assign rs1_exe         = id_exe_bus_o.rs1;     // 5
    assign rs2_exe         = id_exe_bus_o.rs2;
    assign rd_exe          = id_exe_bus_o.rd; 
    assign fun3_exe        = id_exe_bus_o.fun3;
    assign reg_rdata1_exe  = id_exe_bus_o.reg_rdata1;
    assign reg_rdata2_exe  = id_exe_bus_o.reg_rdata2;
    assign imm_exe         = id_exe_bus_o.imm;

    // control signals
    assign reg_write_exe   = id_exe_bus_o.reg_write;
    assign mem_write_exe   = id_exe_bus_o.mem_write;
    assign mem_to_reg_exe  = id_exe_bus_o.mem_to_reg;
    assign branch_exe      = id_exe_bus_o.branch;
    assign alu_src_exe     = id_exe_bus_o.alu_src;
    assign jump_exe        = id_exe_bus_o.jump;
    assign lui_exe         = id_exe_bus_o.lui;
    assign auipc_exe       = id_exe_bus_o.auipc;
    assign jal_exe         = id_exe_bus_o.jal;

//    assign p_signal_start_exe[8:3] = id_exe_bus_o.p_signal_start[8:3];
//    assign p_signal_start_exe[0] = (!fsqrt_unit_busy && !p_signal_last[0]) ? id_exe_bus_o.p_signal_start[0] : 1'b0;  // Fsqrt
//    assign p_signal_start_exe[1] = (!div_unit_busy && !p_signal_last[1]) ? id_exe_bus_o.p_signal_start[1] : 1'b0; // Div
//    assign p_signal_start_exe[2] = (!fdiv_unit_busy && !p_signal_last[2]) ? id_exe_bus_o.p_signal_start[2] : 1'b0; // Fdiv
    assign p_signal_start_exe[8:3] = id_exe_bus_o.p_signal_start[8:3];
    assign p_signal_start_exe[0] = (!fsqrt_unit_busy && !p_signal_last[0] && !branch_hazard) ? id_exe_bus_o.p_signal_start[0] : 1'b0;  // Fsqrt
    assign p_signal_start_exe[1] = (!div_unit_busy && !p_signal_last[1] && !branch_hazard) ? id_exe_bus_o.p_signal_start[1] : 1'b0; // Div
    assign p_signal_start_exe[2] = (!fdiv_unit_busy && !p_signal_last[2] && !branch_hazard) ? id_exe_bus_o.p_signal_start[2] : 1'b0; // fDiv
    assign alu_ctrl_exe = id_exe_bus_o.alu_ctrl; 
    
    
    // control signals for FP extension
    assign FP_reg_write_exe = id_exe_bus_o.FP_reg_write;
    assign rdata1_int_FP_sel_exe = id_exe_bus_o.rdata1_int_FP_sel;   // to avoid dependecy int and FP
    assign rdata2_int_FP_sel_exe = id_exe_bus_o.rdata2_int_FP_sel;   // to avoid dependecy int and FP
    
    // 3rd operand of R4 unit ...
    assign rs3_exe         = id_exe_bus_o.rs3;
    assign reg_rdata3_exe  = id_exe_bus_o.reg_rdata3;
    assign is_R4_instruction_exe = id_exe_bus_o.is_R4_instruction;
    
    
    // ============================================
    //                Execute Stage 
    // ============================================
    
    // A register that decides which forwading value should use, "the current-forwarding value or something captured previously?"
    // it tries to solve RAW problem ..
    logic [31:0]          captured_1_result_mem;
    logic [31:0]          captured_1_reg_wdata_wb;
    logic [1:0]            captured_1_forward_rd1_exe;
    logic [31:0]          captured_2_result_mem;
    logic [31:0]          captured_2_reg_wdata_wb;
    logic [1:0]             captured_2_forward_rd2_exe;
    logic [31:0]          captured_3_result_mem;
    logic [31:0]          captured_3_reg_wdata_wb;
    logic [1:0]             captured_3_forward_rd3_exe;
    
    // for clear logic and Read-After_Write (RAW) cases
    logic no_exe_unit_dependency; // there isn't any dependency between iinstruction in ID_EXE-pipeline-register and the one inside the unit required
    
    value_capture #(
        .n(32)
    ) capture_frw_reg (
        .rd_not_busy(~rd_busy),    // from "busy_reg" which indicates if system stalled cause of data-dependency or not
        .result_mem(result_mem),          // forwarded data (MEM stage)
        .reg_wdata_wb(reg_wdata_wb),     // forwarded data data (WB stage)
        .forward_rd1_exe(forward_rd1_exe),            // forwarding_mux_a selector
        .forward_rd2_exe(forward_rd2_exe),            // forwarding_mux_b selector
        .forward_rd3_exe(forward_rd3_exe),            // forwarding_mux_c selector  
        .no_dependency(no_exe_unit_dependency), 
        .no_collision(~p_stall[5]), 
        .*
    );
    
    // forwarding multiplexers ...
    wire [31:0] rdata1_frw_exe, rdata2_frw_exe, rdata3_frw_exe;
    
    // Forwarding mux for rd1
    mux3x1 #(32) forwarding_mux_a (
//        .sel(forward_rd1_exe),
        .sel(captured_1_forward_rd1_exe),
        .in0(reg_rdata1_exe),       // normal value from reg file
        .in1(captured_1_result_mem),             // forwarded value from MEM stage
        .in2(captured_1_reg_wdata_wb),        // forwarded value from WB stage
        .out(rdata1_frw_exe)
    );
    
    // Forwarding mux for rd2
    mux3x1 #(32) forwarding_mux_b (
//        .sel(forward_rd2_exe),
        .sel(captured_2_forward_rd2_exe),
        .in0(reg_rdata2_exe),      // normal value from reg file
        .in1(captured_2_result_mem),            // forwarded value from MEM stage
        .in2(captured_2_reg_wdata_wb),       // forwarded value from WB stage
        .out(rdata2_frw_exe)
    );
    
    // Forwarding mux for rd3
    mux3x1 #(32) forwarding_mux_c (
        .sel(captured_3_forward_rd3_exe),
        .in0(reg_rdata3_exe),      // normal value from reg file
        .in1(captured_3_result_mem),            // forwarded value from MEM stage
        .in2(captured_3_reg_wdata_wb),       // forwarded value from WB stage
        .out(rdata3_frw_exe)
    );
    
    // jalr multiplexer
    logic jalr_exe;
    assign jalr_exe = ~jal_exe & jump_exe;
    logic [31:0] jump_base_pc_exe;

    mux2x1 #(
        .n(32)
    ) jalr_pc_mux (
        .sel(jalr_exe), // jalr means jump to ([rs1] + imm)
        .in0(current_pc_exe), // all other (pc + imm)
        .in1(rdata1_frw_exe),           // normal rdata1 (also it could be forwarded value, based on "forwarding_mux_a") 
        .out(jump_base_pc_exe)
    );
    assign pc_jump_exe = jump_base_pc_exe + imm_exe & ~(32'd1);//
    // NOTE: PC+4 exist in IF1 stage (before pc modulel)
    // NOTE: PC+imm exist in EXE stage
    // pc adder for jumping logic (NOTE: this adder isn't a part of alu)
    // assign pc_jump_exe = jump_base_pc_exe + imm_exe;

    // NOTE: PC+4 exist in IF1 stage (before pc modulel)
    // NOTE: PC+imm exist in EXE stage

    // multiplxers at alu inputs (exe stage)
    logic [31:0] alu_op1_exe;
    logic [31:0] alu_op2_exe;
    mux2x1 #(
        .n(32)
    ) alu_op1_mux (
        .sel(auipc_exe),
        .in0(rdata1_frw_exe),   // normal rdata1 (also it could be forwarded value, based on "forwarding_mux_a")
        .in1(current_pc_exe),   // pc+imm is excuted in a seperated adder (not in alu) but this one use ALU for auipc instruction specifically
        .out(alu_op1_exe)       
    );

    // (exe stage)
    mux2x1 #(
        .n(32)
    ) alu_op2_mux (
        .sel(alu_src_exe),
        .in0(rdata2_frw_exe),   // normal rdata1 (also it could be forwarded value, based on "forwarding_mux_b")
        .in1(imm_exe),
        .out(alu_op2_exe)       
    );
    
    
    // ==================== signals-bus for each Functional Unit ====================
    // pipelined modules within EXE stage ....
    // p_Mux buses (in & out)
    exe_p_mux_bus_type   exe_main_bus,
                                               exe_div_bus,
                                               exe_fadd_sub_bus,
                                               exe_fmul_bus,
                                               exe_fdiv_bus,
                                               exe_fsqrt_bus,
                                               exe_R4_bus,
                                               p_mux_signals;       // it's bus contains all pipeline signals for each ALU-module

    // NOTE: single-cycle units (ALU, FPU, and integer multiplication) do not require buses
    // NOTE: 6 functional units need clear signal (Div, FAdd_sub, FMul, FDiv, Fsqrt, R4_Float)


    

    // ==================== Functional Units (hardwares in EXE stage) ====================
    // instantiating the ALU here (exe_stage)
    alu alu_inst (
        .alu_ctrl(alu_ctrl_exe),
        .op1(alu_op1_exe),
        .op2(alu_op2_exe),
        .lui(lui_exe),
        .alu_result(alu_result_exe), 
        .zero(zero_exe)
    );
    
    
    // control-signals bus of Div_unit
    assign exe_main_bus = {         
        // data signals
        pc_plus_4_exe,
        pc_jump_exe,
        rs2_exe,
        rd_exe,
        fun3_exe,
        rdata2_frw_exe,
        imm_exe,
        // control signals
        reg_write_exe,
        mem_write_exe,
        mem_to_reg_exe, 
        branch_exe,
        jump_exe,
        lui_exe,
        p_sel_exe==ALU_unit? zero_exe : 1'b0,       // take zero flag from ALU or put it 0 if ALU not used
        // floating point (FP) signals ...
        FP_reg_write_exe
        ,rdata1_int_FP_sel_exe,
        rdata2_int_FP_sel_exe  
    };
    
    // signals of floating-point unit (FPU)
    logic [31:0] fpu_result_exe;
    // FPU: it's a unit for executing other Floating-Point instructions (e.g.fmax, fmin, fcvt, ..etc.)
    fpu FP_unit(
        .alu_ctrl(alu_ctrl_exe),
        .rs1(alu_op1_exe),
        .rs2(alu_op2_exe),
        .fun3(fun3_exe),
        .result(fpu_result_exe)
    );        
    
    // signals of Div_unit
    logic p_signal_div;
    logic [31:0] div_result_exe;
    logic dbz, ovf;     // flags (we won't use it since we don't have status register)
    
    // Div_unit
    int_div_rem #(
        .WIDTH(32)
    ) int_div_rem_inst (     // Division & Remaining for integer data
        .clk(clk),
        .rst(~reset_n),    // inside the module, it activates when it's HIGH (if rst==1  -->  clear values)
        .i_p_signal(p_signal_start_exe[1]),     // (new) it was ".i_p_signal(p_signal_start[1]),"
        .alu_ctrl(alu_ctrl_exe),
        .i_pipeline_control(exe_main_bus),
        .a(alu_op1_exe),   // dividend (numerator)
        .b(alu_op2_exe),   // divisor (denominator)
        
        // output flags     (won't be used because we don't have status register)
        .dbz(dbz),    // divide by zero
        .ovf(ovf),    // overflow
        // outputs ...
        .stall(div_unit_busy),   // means "calculation in progress"
        .o_p_signal(p_signal_div),   // you can call it "p_signal_last"
        .result(div_result_exe),  // result value (quotient or remainder based on func3)
        .o_pipeline_control(exe_div_bus),
        
        //  to solve Write-After-Write (WAW) issue
        .rd_div_unit_use(div_uu_rd),
        .en(~p_stall[3]),
        .clear(clear_uu_rd[0])
    );  
    
    // signals of Mul_unit
    logic [31:0] mul_result_exe;    // output logic [63:0] result --> it suppose to be 32 bits either upper-half or lower one
    
     int_mul int_mul_unit(
         .rs1(alu_op1_exe), // Multiplicand
         .rs2(alu_op2_exe), // Multiplier
         .alu_op(alu_ctrl_exe), // Operation selector (MUL, MULH, MULHU, MULHSU)
          .result(mul_result_exe) // Product of multiplication
     ); 

    // signals of FAdd_Sub_unit
    logic [31:0] fadd_sub_result_exe;
    logic p_signal_fadd_sub;
    
    // FAdd_Sub_unit
    FP_add_sub  fadd_sub_unit(
        .fadd_sub_pipeline_signals_i(exe_main_bus),
        .fadd_sub_pipeline_signals_o(exe_fadd_sub_bus),
        .p_start(p_signal_start_exe[5]),   // (new) it was ".p_start(p_signal_start[5]),"
        .clk(clk),
        .en(~p_stall[2]),
//        .clear(clear_uu_rd[3:1]),          // register that store data and pipeline signals (if you need to use it)
        .clear(clear_uu_rd[3:1] | {2'b00, branch_hazard}),          // register that store data and pipeline signals (if you need to use it)
        .rst(reset_n),     // inside the module, it activates in negative edge
        .add_sub(alu_ctrl_exe==FSUB),    // 0: fadd --- 1: fsub
        .num1(alu_op1_exe),
        .num2(alu_op2_exe),
        .rm(fun3_exe),  // Rounding Mode
        .p_result(p_signal_fadd_sub),
        .sum(fadd_sub_result_exe)       // result (either add or sub)
        
        // for clear logic
        , .uu_rd(fadd_sub_uu_rd),
        .uu_reg_write(fadd_uu_reg_write),
        .uu_FP_reg_write(fadd_uu_FP_reg_write)
    );

    
    // signals of FP sqrt unit
        logic p_signal_fsqrt;
        logic [31:0] fp_sqrt_result_exe;

    // FP square root unit (fsqrt_unit)
    fp_sqrt_Multicycle fsqrt_unit(
        .clk(clk),
        .rst_n(reset_n),
        .en(~p_stall[4]), 
        .clear(clear_uu_rd[5]),
        .A_top2(alu_op1_exe),
        .p(p_signal_start_exe[0]), 
        .bus_i(exe_main_bus),
        .busy(fsqrt_unit_busy),
        .p_out(p_signal_fsqrt),
        .result_out(fp_sqrt_result_exe),
        .bus_o(exe_fsqrt_bus),
        // for clear logic
        .uu_rd(fsqrt_uu_rd),
        .uu_reg_write(fsqrt_uu_reg_write),
        .uu_FP_reg_write(fsqrt_uu_FP_reg_write)
    );
    
    
    // signals of R4_unit
    logic p_signal_R4;
    logic [31:0] R4_result_exe;
    
    R4_Unit #(
        .addr_width(rd_addr_width),
        .num_rds(5)
    ) FP_R4_unit (
        .fadd_sub_pipeline_signals_i(exe_main_bus),
        .fadd_sub_pipeline_signals_o(exe_R4_bus),
        .clk(clk),
        .rst(reset_n),
//        .clear(clear_uu_rd[6+4 : 6]),    // [10:6]
        .clear(clear_uu_rd[6+4 : 6] | {4'd0, branch_hazard}),    // [10:6]
        .en(~p_stall[6]),
        .a(alu_op1_exe),
        .b(alu_op2_exe),
        .c(rdata3_frw_exe),
        .alu_ctrl(alu_ctrl_exe),
        .p_signal(p_signal_start_exe[3]),
        .rm(fun3_exe),
        .result(R4_result_exe), 
        .p_out_signal(p_signal_R4)
        // for clear logic
        , .uu_rd(R4_uu_rd),
        .uu_reg_write(R4_uu_reg_write),
        .uu_FP_reg_write(R4_uu_FP_reg_write)
    );
    
    // signals of FP_mul unit
    logic p_signal_fmul;
    logic [31:0] fmul_result_exe;

    FP_final_Multiplier FP_mul(
        .clk(clk),
        .rst(reset_n),
        .clear(clear_uu_rd[4]),
        .en(~p_stall[1]),
        .a(alu_op1_exe),
        .b(alu_op2_exe),
        .rm(fun3_exe),
        .P_signal(p_signal_start_exe[4]),
        .fadd_sub_pipeline_signals_i(exe_main_bus),
        .fadd_sub_pipeline_signals_o(exe_fmul_bus),
        .P_O_signal(p_signal_fmul),
        .result(fmul_result_exe)
    );
    
    // signals of FP_div_unit
    logic p_signal_fdiv;
    logic [31:0] fdiv_result_exe;
    
    fdiv FP_div_unit(
        .clk(clk),
        .rst_n(reset_n),
//        .clear(clear_uu_rd[num_rds-1 : 11]),
//        .clear(clear_uu_rd[11]),
        .clear(clear_uu_rd[4] |  branch_hazard),
        .a_in(alu_op1_exe),        // Multiplicand
        .b_in(alu_op2_exe),        // Divisor (we calculate 1/b)
        .p_start(p_signal_start_exe[2]),            // Start pulse
        .bus_i(exe_main_bus), // Pipeline signals input
        .rm(fun3_exe),           // Rounding mode
        .en(~p_stall[0]),                 // Enable signal
        
        .result_out(fdiv_result_exe), // Final result: a * (1/b)
        .p_result(p_signal_fdiv),          // Result valid pulse
        .busy(fdiv_unit_busy),              // Unit is busy
        .bus_o(exe_fdiv_bus), // Pipeline signals output
        
        // For clear logic
        .uu_rd(fdiv_uu_rd),        // Unit uses this rd
        .uu_reg_write(fdiv_uu_reg_write),       // Register write flag
        .uu_FP_reg_write(fdiv_uu_FP_reg_write)     // FP register write flag
    );  
    
    
//    fdiv #( // (pipelined version) 
//        .num_delay(25),
//        .rd_addr_size(rd_addr_width)
//    ) FP_div_unit (  
//        .fadd_sub_pipeline_signals_i(exe_main_bus),
//        .fadd_sub_pipeline_signals_o(exe_fdiv_bus),
//        .p_start(p_signal_start_exe[2]),
//        .p_result(p_signal_fdiv),
//        .clk(clk),
//        .en(~p_stall[0]),
//        .clear(clear_uu_rd[num_rds-1 : 11] ),
//        .rst(reset_n),
//        .a(alu_op1_exe),
//        .b(alu_op2_exe),
//        .rm(fun3_exe),  // Rounding Mode 
//        .result(fdiv_result_exe)
//        // for clear logic ...
//        , .uu_rds(fdiv_uu_rd),
//        .uu_reg_write(fdiv_uu_reg_write),
//        .uu_FP_reg_write(fdiv_uu_FP_reg_write)
//    );
    
        
    // ==================== P-signals of Functional Units ====================
    // p_signals start and last
    assign p_signal_last = {
        p_signal_start_exe[8],       // [8] : ALU     --> it goes directly since ALU takes one cycle to finish
        p_signal_start_exe[7],      // [7] : FP_unit
        p_signal_start_exe[6],      // [6] : MUL_unit 
        p_signal_fadd_sub,   // [5] : FADD_SUB_unit (pipelined)
        p_signal_fmul,  // [4] : FMUL_unit (pipelined)
        p_signal_R4,     // [3] : R4_unit  (pipelined)
        p_signal_fdiv,     // [2] : FDIV_unit (multi-cycle)
        p_signal_div,             // [1] : DIV_unit (multi-cycle)
        p_signal_fsqrt     // [0] : fsqrt_unit   --> the highest priority (multi-cycle)
    };

    
    // ==================== Priority Mux (P_Mux) ====================
    // in priority-mux module ...
    // ALU is a combinational logic unit (single-cycle unit), thus it will go directly to the next stage and MUST causes single collesion at least)
    
    // pipeline ALU-modules signals
    logic [31:0] p_result_exe;
    
    // this priority-Mux chooses a single result from ALU-modules to pass it from EXE to MEM stage
    priority_mux #(
        .PIPELINE_WIDTH($bits(exe_main_bus))
    ) p_mux_exe (
        .p_sel(p_sel_exe),       // its type is "priority_t"
    
        // ARITHMITIC UNITS SIGNALS
        .alu_result(alu_result_exe),                     // ALU
        .alu_pipeline_signals(exe_main_bus),
        .fpu_result(fpu_result_exe),                    // FPU
        .fpu_pipeline_signals(exe_main_bus),
        .mul_result(mul_result_exe),                  // MUL
        .mul_pipeline_signals(exe_main_bus),
        .div_result(div_result_exe),                     // DIV
        .div_pipeline_signals(exe_div_bus),
        .fmul_result(fmul_result_exe),               // FMul,
        .fmul_pipeline_signals(exe_fmul_bus),
        .fdiv_result(fdiv_result_exe),                  // FDiv
        .fdiv_pipeline_signals(exe_fdiv_bus),
        .fadd_sub_result(fadd_sub_result_exe),  // FADD_SUB
        .fadd_sub_pipeline_signals(exe_fadd_sub_bus),
        .fsqrt_result(fp_sqrt_result_exe),      // Fsqrt
        .fsqrt_pipeline_signals(exe_fsqrt_bus),
        .R4_result(R4_result_exe),                  // FP_R4
        .R4_pipeline_signals(exe_R4_bus),
        // outputs
        .p_result(p_result_exe),
        .p_pipeline_signals(p_mux_signals)
    );
    

      // NOTE: PC+4 exist in IF1 stage (before pc modulel)
      // NOTE: PC+imm exist in EXE stage
    
    // ==================================================================================
    // RAW solution ...
    // signals to solve "Read After Write" (RAW) problem
    logic forward_flag;     // there's a forwarding applied (either from MEM or WB stages)
    assign forward_flag = forward_rd1_id| forward_rd2_id
                                            | (|forward_rd1_exe ) | (|forward_rd2_exe)
                                            | forward_rd2_mem ;
                                            
    // busy-registers that indecate which rd used in EXE stage currently (solve RAW problem) ...
    logic int_rd_busy;
    logic div_uu_rd_busy;
    logic no_int_dependency;
    
    logic FP_rd_busy;
    logic no_FP_dependency;
    
    
    // integer busy-registers
    busy_registers #(
        .total_regs(32)
    ) busy_rd_int (
        .clk(clk),
        .reset_n(reset_n),
        .forward_flag(forward_flag),        // TODO: not used currently, so delete it
        .forward_rd1_exe(forward_rd1_exe),
        .forward_rd2_exe(forward_rd2_exe),
        .reg_write_id(id_exe_bus_o.reg_write),      // write on integer register file
        .FP_reg_write_id(id_exe_bus_o.FP_reg_write),      // write on FP register file
        .reg_write_p_mux(p_mux_signals.reg_write),
        .waddr_wb(p_mux_signals.rd),   // addres of rd that come from write-back stage
        .waddr_id(rd_exe),   // addres of rd that come from decode stage
        .rs1(rs1_exe),
        .rs2(rs2_exe),
        .int_rd_busy(int_rd_busy)       // means "there is a data dependency (RAW)
        // for clear logic
        , .div_uu_rd(div_uu_rd),
        .div_uu_rd_busy(all_uu_rd_busy[0]),  // do the same logic on FP_register
        .no_int_dependency(no_int_dependency)
    );
    
    // FP busy-registers
    FP_busy_registers #(
        .num_rds(num_rds - int_uu_rds),  // num_rds - 1
        .total_regs(32)
    ) busy_rd_FP (
        .clk(clk),
        .reset_n(reset_n),
        .forward_flag(forward_flag),        // not used currently
        .forward_rd1_exe(forward_rd1_exe),
        .forward_rd2_exe(forward_rd2_exe),
        .forward_rd3_exe(forward_rd3_exe), 
        .reg_write_id(id_exe_bus_o.reg_write),      // write on integer register file
        .FP_reg_write_id(id_exe_bus_o.FP_reg_write),      // write on FP register file
        .FP_reg_write_p_mux(p_mux_signals.FP_reg_write),
        .waddr_wb(p_mux_signals.rd),   // addres of rd that come from write-back stage
        .waddr_id(rd_exe),   // addres of rd that come from decode stage
        .rs1(rs1_exe),
        .rs2(rs2_exe),
        .rs3(rs3_exe), 
        .FP_rd_busy(FP_rd_busy)       // means "there is a data dependency (RAW)
//         for clear logic
        , .all_uu_FP_rd(all_uu_rd[1 : num_rds-1]),
        .all_uu_FP_rd_busy(all_uu_rd_busy[num_rds-1 :1]),
        .no_FP_dependency(no_FP_dependency)
    );
    
    // combine the 2 rd_busy signals to generate busy flag that stall the system when data-dependency exist (RAW)
    assign rd_busy = int_rd_busy | FP_rd_busy;
    assign no_exe_unit_dependency = no_int_dependency & no_FP_dependency; // (new)

    
    // rd adresses that units use ...
    assign all_uu_rd[0] = div_uu_rd;
    assign all_uu_rd[1] = exe_main_bus.rd;
    assign all_uu_rd[2] = fadd_sub_uu_rd[0];
    assign all_uu_rd[3] = fadd_sub_uu_rd[1];
    assign all_uu_rd[4] = exe_main_bus.rd;  // because fmul has 2 stages (single pipeline reg)
    assign all_uu_rd[5] = fsqrt_uu_rd;
    assign all_uu_rd[6] = R4_uu_rd[0];
    assign all_uu_rd[7] = R4_uu_rd[1];
    assign all_uu_rd[8] = R4_uu_rd[2];
    assign all_uu_rd[9] = R4_uu_rd[3];
    assign all_uu_rd[10] = R4_uu_rd[4];
//    assign all_uu_rd[11 : num_rds-1] = fdiv_uu_rd [0 : num_rds-1-11];   // i+offset (pipelined)
    assign all_uu_rd[11] = fdiv_uu_rd;   // i+offset (multicycle)
    
//    assign uu_reg_write[num_rds-1 : 11] = fdiv_uu_reg_write;  // [34 : 10] fdiv
    assign uu_reg_write[11] = fdiv_uu_reg_write;  // [34 : 10] fdiv
    assign uu_reg_write[10:0] = {
        R4_uu_reg_write[4],           // [10] R4 -- inner FAdd[1] (pipelined)
        R4_uu_reg_write[3],           // [9] R4 -- inner FAdd[1] (pipelined)
        R4_uu_reg_write[2],           // [8] R4 -- inner FAdd[0] (pipelined)
        R4_uu_reg_write[1],           // [7] R4 -- between Fmul and FAdd (pipelined)
        R4_uu_reg_write[0],           // [6] R4 -- inner Fmul (pipelined)
        fsqrt_uu_reg_write,      // [5] fsqrt (multi-cycle)
        exe_main_bus.reg_write,      // [4] fmul (pipelined)
        fadd_uu_reg_write[1],       // [3]     fadd_sub2 (pipelined)
        fadd_uu_reg_write[0],       // [2]     fadd_sub1 (pipelined)
        exe_main_bus.reg_write,       // [1]     from ID/EXE pipeline register to fadd_sub[0] register  (pipelined)
        exe_div_bus.reg_write       // [0] int_div (multi-cycle)
    };
//    assign uu_FP_reg_write[num_rds-1 : 11] = fdiv_uu_FP_reg_write;  // [34 : 10] fdiv
    assign uu_FP_reg_write[11] = fdiv_uu_FP_reg_write;  // multicycle fdiv
    assign uu_FP_reg_write[10:0] = {
        R4_uu_FP_reg_write[4],           // [10] R4 -- inner FAdd[1] (pipelined)
        R4_uu_FP_reg_write[3],           // [9] R4 -- inner FAdd[1] (pipelined)
        R4_uu_FP_reg_write[2],           // [8] R4 -- inner FAdd[0] (pipelined)
        R4_uu_FP_reg_write[1],           // [7] R4 -- between Fmul and FAdd (pipelined)
        R4_uu_FP_reg_write[0],           // [6] R4 -- inner Fmul (pipelined)
        fsqrt_uu_FP_reg_write,      // [5] fsqrt (multi-cycle)
        exe_main_bus.FP_reg_write,      // [4] fmul (pipelined)
        fadd_uu_FP_reg_write[1],       // [3]     fadd_sub2(pipelined)
        fadd_uu_FP_reg_write[0],       // [2]     fadd_sub1(pipelined)
        exe_main_bus.FP_reg_write,       // [1]     fadd_sub0 (pipelined)
        exe_div_bus.FP_reg_write       // [0] int_div (multi-cycle)
    };
    
    // Decoder to generate "clear" signals for each functional unit (only for multi-cycles and pipelined)
    clear_units_decoder #(
        .num_rds(num_rds),
        .rd_addr_width(rd_addr_width)   // bits of rd-address
    ) clr_rd_generator (
    // signals from Functoinal-Units (multi-cycles and pipeline)
    .rd_used(all_uu_rd),
    .reg_write_unit(uu_reg_write),            // indicates that rd is integer
    .FP_reg_write_unit(uu_FP_reg_write),     // indicates that rd is FP
    .all_uu_rd_busy(all_uu_rd_busy),     // indicate that rd still inisde the unit and didn't reach MEM stage yet
    .no_exe_unit_dependency(no_exe_unit_dependency),
    // signals from ID/EXE pipeline register (the new instruction)
    .waw_rd(rd_id), // CHECK IN ID STAGE
    .waw_rs1(rs1_id),
    .waw_rs2(rs2_id),
    .waw_rs3(rs3_id),    // TODO: as ID stage
    .reg_write_new(reg_write_id),              // indicates that rd is integer  // TODO: take from ID
    .FP_reg_write_new(FP_reg_write_id), // indicates that rd is FP
    .is_R4_instruction(is_R4_instruction_exe), 
    // output
    .clear_rd(clear_uu_rd)            // Array of clear signals for each unit
    );

// ============================================
//                Tracer instance (test) 
// ============================================
    
    // tracer instance
    rvfi_tracker_delay DUT_tarcer(
        // tracer inputs ...
        .inst_id(inst_id),
        .rs1_address_id(rs1_id),
        .rs2_address_id(rs2_id),
        .rs3_address_id(rs3_id),
        .reg_rdata1_id(reg_rdata1_id),
        .reg_rdata2_id(reg_rdata2_id),
        .reg_rdata3_id(reg_rdata3_id),
        .rd_address_id(rd_id),
        // .p_mux_result(alu_result_mem),  // "rvfi_rd_wdata"  -> result from p_mux
        .p_mux_result(result_mem),  // "rvfi_rd_wdata"  -> result from p_mux
        .current_pc_id(current_pc_id),
        .p_mux_pc_plus_4(exe_mem_bus_o.pc_plus_4),  // PC+4 from p_mux signals

        .pc_sel_mem(pc_sel_mem),  // not used
        .pc_jump_mem(pc_jump_mem),  // not used
        .mem_write_mem(mem_write_mem),  // control signal used with store instructions
        .mem_wdata_mem(mem_wdata_mem), // value of writing on DMEM (writing data)
        .mem_to_reg_mem(mem_to_reg_mem),  // control signal used with load instructions (mem stage)
        .mem_to_reg_wb(mem_to_reg_wb), // control signal used with load instructions (wb stage)
        .reg_wdata_wb(reg_wdata_wb), // value of loaded-data from DMEM to reg_file (loading data -- wb stage)

        //logic [31:0] rvfi_mem_addr,   // TODO: change their names
        //logic rvfi_mem_rmask,  // we don't have 
        //logic rvfi_mem_wmask,  // we don't have
        //logic [31:0] rvfi_mem_wdata,
        //logic [31:0] rvfi_mem_rdata,
        .stalled(~(pc_reg_en | if_id_reg_en | id_exe_reg_en)), // | exe_mem_reg_en)), // | mem_wb_reg_en)),
        .branch_hazard_mem(branch_hazard),  // (new) comes from MEM stage from "hazard_handler"
        .pc_plus_4_mem(pc_plus_4_mem),
        .*  // outputs
    );
    
//    // tracer instance
//    rvfi_tracker_delay DUT_tarcer(
//        // tracer inputs ...
//        .inst_id(inst_id),
//        .rs1_address_id(rs1_id),
//        .rs2_address_id(rs2_id),
//        .rs3_address_id(rs3_id),
//        .reg_rdata1_id(reg_rdata1_id),
//        .reg_rdata2_id(reg_rdata2_id),
//        .reg_rdata3_id(reg_rdata3_id),
//        .rd_address_id(rd_id),
//        .p_mux_result(alu_result_mem),  // "rvfi_rd_wdata"  -> result from p_mux
//        .current_pc_id(current_pc_id),
//        .p_mux_pc_plus_4(exe_mem_bus_o.pc_plus_4),  // PC+4 from p_mux signals
//        //logic [31:0] rvfi_mem_addr,   // TODO: change their names
//        //logic rvfi_mem_rmask,  // we don't have 
//        //logic rvfi_mem_wmask,  // we don't have
//        //logic [31:0] rvfi_mem_wdata,
//        //logic [31:0] rvfi_mem_rdata,
//        .stalled(~(pc_reg_en | if_id_reg_en | id_exe_reg_en)), // | exe_mem_reg_en)), // | mem_wb_reg_en)),
//        .branch_hazard_mem(branch_hazard),  // (new) comes from MEM stage from "hazard_handler"
//        .pc_plus_4_mem(pc_plus_4_mem),
//        .*  // outputs
//    );

    // ============================================
    //           EXE-MEM Pipeline Register
    // ============================================
    
    // (Pipeline)  -            EXE_end Bus    ,     MEM_start Bus
    exe_mem_reg_t Qamar_exe_mem_bus_i, exe_mem_bus_o;
    exe_mem_reg_t exe_mem_bus_i;

    // (Pipeline) EXE_end Bus
    assign exe_mem_bus_i = {
        // data signals
        p_mux_signals.pc_plus_4,
        p_mux_signals.pc_jump,
        p_mux_signals.rs2,
        p_mux_signals.rd,
        p_mux_signals.fun3,
        p_mux_signals.rdata2_frw,
        p_mux_signals.imm,
        p_result_exe,
        // control signals
        p_mux_signals.reg_write,
        p_mux_signals.mem_write,
        p_mux_signals.mem_to_reg,
        p_mux_signals.branch,
        p_mux_signals.jump,
        p_mux_signals.lui,
        p_mux_signals.zero,
        // floating point (FP) signals
        p_mux_signals.FP_reg_write
    };
    
    // (Pipeline) EXE/MEM register
    n_bit_reg_wclr #(
        .n($bits(exe_mem_reg_t))
    ) exe_mem_reg (
        .clk(clk),
        .reset_n(reset_n),
//        .clear(exe_mem_reg_clr),
        .clear(exe_mem_reg_clr & !pipe_or_multi_p_last),  // --> claer it only if single-cycle instruction comes after the branch
        .wen(exe_mem_reg_en),
        .data_i(exe_mem_bus_i),           // (Pipeline) EXE_end Bus
        .data_o(exe_mem_bus_o)        // (Pipeline) MEM_start Bus
    );

    // extract signals from MEM_start Bus to be used later in MEM-stage ...
    // data signals
    assign pc_plus_4_mem   = exe_mem_bus_o.pc_plus_4;  // 32
    assign pc_jump_mem     = exe_mem_bus_o.pc_jump;
    assign rs2_mem         = exe_mem_bus_o.rs2;
    assign rd_mem          = exe_mem_bus_o.rd; 
    assign fun3_mem        = exe_mem_bus_o.fun3;
    assign rdata2_frw_mem  = exe_mem_bus_o.rdata2_frw;
    assign imm_mem         = exe_mem_bus_o.imm;
    assign alu_result_mem  = exe_mem_bus_o.alu_result;
    // control signals
    assign reg_write_mem   = exe_mem_bus_o.reg_write;
    assign mem_write_mem   = exe_mem_bus_o.mem_write;
    assign mem_to_reg_mem  = exe_mem_bus_o.mem_to_reg;
    assign branch_mem      = exe_mem_bus_o.branch;
    assign jump_mem        = exe_mem_bus_o.jump;
    assign lui_mem         = exe_mem_bus_o.lui; 
    assign zero_mem        = exe_mem_bus_o.zero;

    // control signals for FP extension
    assign FP_reg_write_mem = exe_mem_bus_o.FP_reg_write;



    // ============================================
    //                Memory Stage 
    // ============================================
    
    // forwarding for mem_write_data
    mux2x1 #(32) mem_data_in_mux (
        .sel(forward_rd2_mem),
        .in0(rdata2_frw_mem),             // actually it's the normal value in MEM stage but forwarded for previous stages
        .in1(reg_wdata_wb),                 // forwarded value from WB stage to MEM stage
        .out(mem_wdata_mem)
    );    
    assign mem_addr_mem = alu_result_mem;       // change its name into "exec_result" regadless what operation applied/used
    assign mem_op_mem = fun3_mem;
    
    // one hot mux to select which value should be used for writing back (wb stage) based on instruction used {LUI,   Jump,   alu_result}
    logic alu_to_reg_mem;
    assign alu_to_reg_mem = ~( jump_mem | lui_mem);
    one_hot_mux3x1 #(
        .n(32)
    ) mem_stage_result_sel_mux (
        .sel({lui_mem, jump_mem, alu_to_reg_mem}),
        .in0(alu_result_mem),
        .in1(pc_plus_4_mem),        // to be stored in "ra" register (a register that store reuturn-address when apply  jump)
        .in2(imm_mem),                  // use "lui_mem" as selector to take this value when apply LUI instruction
        .out(result_mem)
    );

    // ============================================
    //            MEM-WB Pipeline Register
    // ============================================
    
    // (Pipeline) - MEM_end Bus ,  WB_start Bus
    mem_wb_reg_t mem_wb_bus_i, mem_wb_bus_o;

    // (Pipeline) MEM_end Bus
    assign mem_wb_bus_i = {
    // data signals 
    rd_mem, 
    result_mem,
    // control signals
    reg_write_mem,
    mem_to_reg_mem,
    // Floating point (FP) signals ...
    FP_reg_write_mem
    };

    // (Pipeline) MEM/WB register
    n_bit_reg_wclr #(
        .n($bits(mem_wb_reg_t))
    ) mem_wb_reg (
        .clk(clk),
        .reset_n(reset_n),
        .clear(mem_wb_reg_clr),
        .wen(mem_wb_reg_en),
        .data_i(mem_wb_bus_i),           // (Pipeline) MEM_end Bus
        .data_o(mem_wb_bus_o)         // (Pipeline) WB_start Bus
    );

    // extract signals from WB_start Bus to be used later in WB-stage ...
    // data signals
    assign rd_wb             = mem_wb_bus_o.rd;
    assign non_mem_result_wb = mem_wb_bus_o.result;
    // control signals
    assign reg_write_wb      = mem_wb_bus_o.reg_write;
    assign mem_to_reg_wb     = mem_wb_bus_o.mem_to_reg;
    // control signals for FP extension
    assign FP_reg_write_wb = mem_wb_bus_o.FP_reg_write;     // "reg_write_wb" signal but for FP reg file


    // ============================================
    //                Write Back Stage 
    // ============================================

    logic [31:0] mem_rdata_wb;          // DMEM output data but in write-back stage
    assign mem_rdata_wb = mem_rdata_mem;

    mux2x1 #(
        .n(32)
    ) write_back_mux (
        .sel(mem_to_reg_wb),
        .in0(non_mem_result_wb),    // alu_result or imm (NOET: imm value used for LUI instruction)
        .in1(mem_rdata_wb),
        .out(reg_wdata_wb)
    );

endmodule 