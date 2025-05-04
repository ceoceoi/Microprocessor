module hazard_handler (
    input wire pc_sel_mem,
    input wire exe_use_rs1_id,
    input wire exe_use_rs2_id,
    input wire [4:0] rs1_id,
    input wire [4:0] rs2_id,
    input wire mem_read_exe,
    input wire [4:0] rd_exe,

    output wire load_hazard,
    output wire branch_hazard,
    
    // signals to resolve back-to-back
    input logic [8:0] p_signal_start_id,
    input logic [8:0] p_signal_start_exe,
    input logic [8:0] p_signal_last,
    input wire div_unit_busy,
    input wire fsqrt_unit_busy,
    input wire fdiv_unit_busy,
    output wire multicycle_hazard
);

    assign branch_hazard = pc_sel_mem;
    assign load_hazard   =   (mem_read_exe  &  (rd_exe !=0)) 
                         &   (((rd_exe === rs1_id) & exe_use_rs1_id) | ((rd_exe === rs2_id) & exe_use_rs2_id));
                         
    // DETECT MULTICYCLE RESOURCE CONFLICT
    assign multicycle_hazard = ((p_signal_start_id[1] && p_signal_start_exe[1]) || (p_signal_start_id[1] && div_unit_busy)) 
    || ((p_signal_start_id[0] && p_signal_start_exe[0]) || (p_signal_start_id[0] && fsqrt_unit_busy))
    || ((p_signal_start_id[2] && p_signal_start_exe[2]) || (p_signal_start_id[2] && fdiv_unit_busy));


endmodule : hazard_handler