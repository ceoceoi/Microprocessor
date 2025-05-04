module pipeline_controller (
    input logic load_hazard,
    input logic branch_hazard,
    input logic stall_pipl,
    
    output logic if_id_reg_clr,
    output logic id_exe_reg_clr,
    output logic exe_mem_reg_clr,
    output logic mem_wb_reg_clr,

    output logic if_id_reg_en, 
    output logic id_exe_reg_en,
    output logic exe_mem_reg_en,
    output logic mem_wb_reg_en,
    output logic pc_reg_en,
    
    // "priority" signals
    input logic p_system_stall,         // p_system_stall = p_stall[5]
    input logic priority_hazard,        // to clear duplicated data in EXE stage (it unintentionally happend, so clear it)
    
    // back-to-back signals ..
    input logic multicycle_hazard,
    output logic pre_exe_stall, // Probably is not used outside anymore 
    
    // signals for WAW ..
    input logic  rd_busy
);

    assign if_id_reg_clr = branch_hazard;
    assign id_exe_reg_clr = branch_hazard | load_hazard | (multicycle_hazard & !rd_busy); // TO AVOID RESULT REPETITION 
    assign exe_mem_reg_clr = branch_hazard;
    assign mem_wb_reg_clr = 1'b0; // never clear

    // stall stages before EXE if "back-to-back" multicycle instructions happend ...
    assign pre_exe_stall = stall_pipl | load_hazard | p_system_stall | multicycle_hazard | rd_busy;

    assign pc_reg_en = ~(pre_exe_stall);
    assign if_id_reg_en = ~(pre_exe_stall);
    assign id_exe_reg_en = ~(stall_pipl | p_system_stall | multicycle_hazard | rd_busy);
    assign exe_mem_reg_en = ~(stall_pipl);
    assign mem_wb_reg_en = ~(stall_pipl);

endmodule