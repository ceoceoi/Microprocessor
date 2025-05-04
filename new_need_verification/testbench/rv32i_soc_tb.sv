// =================================================================== //
//                     Shahoodi Final Testbench                        //
// =================================================================== //

module rv32i_soc_tb;

      logic clk;
    logic reset_n;
    logic o_flash_sclk;
    logic o_flash_cs_n;
    logic o_flash_mosi;
    logic i_flash_miso;
    logic o_uart_tx;
    logic i_uart_rx;
    // more signals can be here 
//`define  TRACER_ENABLE=1;
    logic [31:0] rvfi_insn;
    logic [4:0]  rvfi_rs1_addr;
    logic [4:0]  rvfi_rs2_addr;
    logic [31:0] rvfi_rs1_rdata;
    logic [31:0] rvfi_rs2_rdata;
    logic [4:0]  rvfi_rd_addr  ;
    logic [31:0] rvfi_rd_wdata ;
    logic [31:0] rvfi_pc_rdata ;
    logic [31:0] rvfi_pc_wdata ;
    logic [31:0] rvfi_mem_addr ;
    logic [31:0] rvfi_mem_wdata;
    logic [31:0] rvfi_mem_rdata;
    logic        rvfi_valid;
    logic srx_pad_i;
    logic stx_pad_o;
    logic rts_pad_o;
    logic cts_pad_i;
    logic current_pc_out;
    logic inst_out;
    
    // Clock generator 
    initial clk = 0;
    always #10 clk = ~clk;

    // signal geneartion here
    initial begin 
        reset_n = 0;
        repeat(2) @(negedge clk);
        reset_n = 1; // dropping reset after two clk cycles
    end

    parameter DMEM_DEPTH = 65536;
    parameter IMEM_DEPTH = 65536;
    // =================================================== //
    //             Instantiation of the SoC
    // =================================================== //
    // Dut instantiation
    rv32i_soc #(
        .IMEM_DEPTH(DMEM_DEPTH), // NOTE TO DV: CHANGE THE SIZE OF IMEM AND DMEM TO ACCOMMODATE THE SIZE OF YOUR TESTS
        .DMEM_DEPTH(DMEM_DEPTH)
       // .NO_OF_GPIO_PINS(NO_OF_GPIO_PINS)
    )DUT(
        //.*
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
                
        .srx_pad_i(srx_pad_i), 
        .stx_pad_o(stx_pad_o), 
        .rts_pad_o(rts_pad_o),
        .cts_pad_i(cts_pad_i), 
        
        .current_pc_out(current_pc_out),  
        .inst_out(inst_out)        
                
         );


    // ============================================================================ //
    //     Example connection of tracer with WB stage signals in the data path
    // ============================================================================ //
//    `ifdef tracer 
        tracer tracer_inst (
        .clk_i(clk),
        .rst_ni(reset_n),
        .hart_id_i(1),
        .rvfi_insn_t(DUT.rv32i_core_inst.data_path_inst.rvfi_insn),
        .rvfi_rs1_addr_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rs1_addr),
        .rvfi_rs2_addr_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rs2_addr),
        .rvfi_rs3_addr_t(),
        .rvfi_rs3_rdata_t(),
        .rvfi_mem_rmask(),
        .rvfi_mem_wmask(),
        .rvfi_rs1_rdata_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rs1_rdata),
        .rvfi_rs2_rdata_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rs2_rdata),
        .rvfi_rd_addr_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rd_addr),
        .rvfi_rd_wdata_t(DUT.rv32i_core_inst.data_path_inst.rvfi_rd_wdata),
        .rvfi_pc_rdata_t(DUT.rv32i_core_inst.data_path_inst.rvfi_pc_rdata),
        .rvfi_pc_wdata_t(DUT.rv32i_core_inst.data_path_inst.rvfi_pc_wdata),
        .rvfi_mem_addr(DUT.rv32i_core_inst.data_path_inst.rvfi_mem_addr),
        .rvfi_mem_wdata(DUT.rv32i_core_inst.data_path_inst.rvfi_mem_wdata),
        .rvfi_mem_rdata(DUT.rv32i_core_inst.data_path_inst.rvfi_mem_rdata),
        .rvfi_valid(DUT.rv32i_core_inst.data_path_inst.rvfi_valid)
        );
//    `endif
    
//   initializing the instruction memory after every reset
   bit [31:0] initial_imem [0:DMEM_DEPTH-1];
   bit [31:0] initial_dmem [0:DMEM_DEPTH-1];

    // Initialize instruction and data memories
    initial begin
        $readmemh("/home/Shahd_Abdulmohsan/core/riscv-dv/soc-rtl/src/tb/inst_formatted.hex", initial_imem);
        $readmemh("/home/Shahd_Abdulmohsan/core/riscv-dv/soc-rtl/src/tb/data_formatted.hex", initial_dmem);

        // force DUT.inst_mem_inst.dmem = initial_imem;
        // force DUT.data_mem_inst.dmem = initial_dmem;
        // #1;
        // release DUT.inst_mem_inst.dmem;
        // release DUT.data_mem_inst.dmem;
        
//             $readmemh("data_formatted.hex", DUT.data_mem_inst.dmem);
//             $readmemh("inst_formatted.hex", DUT.inst_mem_inst.dmem);
// //  force DUT.inst_mem_inst.dmem = initial_imem;
// //  force DUT.data_mem_inst.dmem = initial_dmem;
// //         #1;
// //         release DUT.inst_mem_inst.dmem;
// //      release DUT.data_mem_inst.dmem;
        

        
    end

    // Simulation run time
    initial begin
        repeat(200000) @(posedge clk);
        $finish;
    end

    // Waveform dumping
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, DUT);
    end

endmodule