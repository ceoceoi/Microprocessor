module rv32i_soc #(
    parameter DMEM_DEPTH = 128,
    parameter IMEM_DEPTH = 128
) (
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


    // spi signals to the spi-flash

    // uart signals
input logic							 srx_pad_i,
output logic						 stx_pad_o,
output logic 						 rts_pad_o,
input logic 						 cts_pad_i,
output logic [31:0] current_pc_out,
output logic [31:0] inst_out,
    // gpio signals
    inout wire [31:0] io_data
);

  logic sel_boot_rom;
  logic sel_boot_rom_ff;
  // Memory bus signals
  logic [31:0] mem_addr_mem;
  logic [31:0] mem_wdata_mem;
  logic        mem_write_mem;
  logic [ 2:0] mem_op_mem;
  logic [31:0] mem_rdata_mem;
  logic        mem_read_mem;



  // ============================================
  //          Processor Core Instantiation
  // ============================================

  // TODO: Instantiate the processor core here

  // processor core signals 
  logic [31:0] current_pc;
  logic        stall_pipl;
  logic        if_id_reg_en;
  logic [31:0] rom_inst;  //, rom_inst_ff;  --> it's defined in BOOT_ROM below
  logic [31:0] inst;  //, rom_inst_ff;  --> it's defined in BOOT_ROM below



  // processor core 
  rv32i #(
      .DMEM_DEPTH(1024),
      .IMEM_DEPTH(1024)
  ) rv32i_core_inst (
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
      // memory bus
      .mem_addr_mem(mem_addr_mem),
      .mem_wdata_mem(mem_wdata_mem),
      .mem_write_mem(mem_write_mem),
      .mem_op_mem(mem_op_mem),
      .mem_rdata_mem(mem_rdata_mem),
      .mem_read_mem(mem_read_mem),

      // inst mem access 
      .current_pc(current_pc),
      .inst(inst),

      // stall signal from wishbone 
      .stall_pipl  (stall_pipl),
      .if_id_reg_en(if_id_reg_en)
  );


  // ============================================
  //                 Wishbone Master 
  // ============================================

  // MY_TODO: IO ( wb master signals )
  logic [31:0] wb_io_adr_i;  // from --> .wb_adr_o
  logic [31:0] wb_io_dat_i;  // from --> .wb_dat_o
  logic [ 3:0] wb_io_sel_i;  // from --> .wb_sel_o
  logic        wb_io_we_i;  // from --> .wb_we_o
  logic        wb_io_cyc_i;  // from --> .wb_cyc_o
  logic        wb_io_stb_i;  // from --> .wb_stb_o
  logic [ 2:0] wb_io_cti_i;  // from -->  wb_m2s_io_cti
  logic [ 1:0] wb_io_bte_i;  // from -->  wb_m2s_io_bte
  logic [31:0] wb_io_dat_o;  // to --> .wb_dat_i  // For simplicity, no data input
  logic        wb_io_ack_o;  // to --> .wb_ack_i  // For simplicity, no acknowledgment signal
  logic        wb_io_err_o;
  logic        wb_io_rty_o;

  wishbone_controller wishbone_master (
      .clk(clk),
      .rst(~reset_n),
      .proc_addr(mem_addr_mem),
      .proc_wdata(mem_wdata_mem),
      .proc_write(mem_write_mem),
      .proc_read(mem_read_mem),
      .proc_op(mem_op_mem),
      .proc_rdata(mem_rdata_mem),
      .proc_stall_pipl(stall_pipl),  // Stall pipeline if needed
      // TODO: connect these signals below
      .wb_adr_o(wb_io_adr_i),  /*TODO*/  // Connect to the external Wishbone bus as required
      .wb_dat_o(wb_io_dat_i),  /*TODO*/
      .wb_sel_o(wb_io_sel_i),  /*TODO*/
      .wb_we_o(wb_io_we_i),  /*TODO*/
      .wb_cyc_o(wb_io_cyc_i),  /*TODO*/
      .wb_stb_o(wb_io_stb_i),  /*TODO*/
      .wb_dat_i(wb_io_dat_o),  /*TODO*/  // wb_io_dat_o --> but For simplicity, no data input
      .wb_ack_i(wb_io_ack_o)  /*TODO*/  // wb_io_ack_o --> but For simplicity, no acknowledgment signal
  );

  logic [2:0] wb_m2s_io_cti;  // MY_TODO: define missed signal
  logic [1:0] wb_m2s_io_bte;  // MY_TODO: define missed signal

  assign wb_m2s_io_cti = 0;
  assign wb_m2s_io_bte = 0;


  // ============================================
  //             Wishbone Interconnect 
  // ============================================

  // TODO: Instantiate the wishbone interconnect here 

  // IO ( wb master signals ) --> defined before in "Wishbone Master" (previous section)
  assign wb_io_cti_i   = wb_m2s_io_cti;
  assign wb_io_bte_i   = wb_m2s_io_bte;

  // SPI FLASH SIGNALS 
  logic [31:0] wb_spi_flash_adr_o;
  logic [31:0] wb_spi_flash_dat_o;
  logic [ 3:0] wb_spi_flash_sel_o;
  logic        wb_spi_flash_we_o;
  logic        wb_spi_flash_cyc_o;
  logic        wb_spi_flash_stb_o;
  logic [ 2:0] wb_spi_flash_cti_o;
  logic [ 1:0] wb_spi_flash_bte_o;
  logic [31:0] wb_spi_flash_dat_i;
  logic        wb_spi_flash_ack_i;
  logic        wb_spi_flash_err_i;
  logic        wb_spi_flash_rty_i;

  // DMEM (Data Mem)
  logic [31:0] wb_dmem_adr_o;
  logic [31:0] wb_dmem_dat_o;
  logic [ 3:0] wb_dmem_sel_o;
  logic        wb_dmem_we_o;
  logic        wb_dmem_cyc_o;
  logic        wb_dmem_stb_o;
  logic [ 2:0] wb_dmem_cti_o;
  logic [ 1:0] wb_dmem_bte_o;
  logic [31:0] wb_dmem_dat_i;
  logic        wb_dmem_ack_i;
  logic        wb_dmem_err_i;
  logic        wb_dmem_rty_i;

  // IMEM (inst. mem)
  logic [31:0] wb_imem_adr_o;
  logic [31:0] wb_imem_dat_o;
  logic [ 3:0] wb_imem_sel_o;
  logic        wb_imem_we_o;
  logic        wb_imem_cyc_o;
  logic        wb_imem_stb_o;
  logic [ 2:0] wb_imem_cti_o;
  logic [ 1:0] wb_imem_bte_o;
  logic [31:0] wb_imem_dat_i;
  logic        wb_imem_ack_i;
  logic        wb_imem_err_i;
  logic        wb_imem_rty_i;

  // UART
  logic [31:0] wb_uart_adr_o;
  logic [31:0] wb_uart_dat_o;
  logic [ 3:0] wb_uart_sel_o;
  logic        wb_uart_we_o;
  logic        wb_uart_cyc_o;
  logic        wb_uart_stb_o;
  logic [ 2:0] wb_uart_cti_o;
  logic [ 1:0] wb_uart_bte_o;
  logic [31:0] wb_uart_dat_i;
  logic        wb_uart_ack_i;
  logic        wb_uart_err_i;
  logic        wb_uart_rty_i;

  // GPIO
  logic [31:0] wb_gpio_adr_o;
  logic [31:0] wb_gpio_dat_o;
  logic [ 3:0] wb_gpio_sel_o;
  logic        wb_gpio_we_o;
  logic        wb_gpio_cyc_o;
  logic        wb_gpio_stb_o;
  logic [ 2:0] wb_gpio_cti_o;
  logic [ 1:0] wb_gpio_bte_o;
  logic [31:0] wb_gpio_dat_i;
  logic        wb_gpio_ack_i;
  logic        wb_gpio_err_i;
  logic        wb_gpio_rty_i;

  wb_intercon wishbone_intercon (
//      .*,
      .wb_clk_i(clk),
      .wb_rst_i(reset_n),
      
      // IO ( wb master signals )
    .wb_io_adr_i(wb_io_adr_i),
    .wb_io_dat_i(wb_io_dat_i),
    .wb_io_sel_i(wb_io_sel_i),
    .wb_io_we_i(wb_io_we_i),
    .wb_io_cyc_i(wb_io_cyc_i),
    .wb_io_stb_i(wb_io_stb_i),
//    .wb_io_cti_i(wb_io_cti_i),
//    .wb_io_bte_i(wb_io_bte_i),
    .wb_io_cti_i(0),  // use "wb_m2s_io_cti" --> but it's always 0
    .wb_io_bte_i(0),  // ue "wb_m2s_io_bte" --> but it's always 0
    .wb_io_dat_o(wb_io_dat_o),
    .wb_io_ack_o(wb_io_ack_o),
    .wb_io_err_o(wb_io_err_o),
    .wb_io_rty_o(wb_io_rty_o),    

    // SPI FLASH SIGNALS 
    .wb_spi_flash_adr_o(wb_spi_flash_adr_o),
    .wb_spi_flash_dat_o(wb_spi_flash_dat_o),
    .wb_spi_flash_sel_o(wb_spi_flash_sel_o),
    .wb_spi_flash_we_o(wb_spi_flash_we_o),
    .wb_spi_flash_cyc_o(wb_spi_flash_cyc_o),
    .wb_spi_flash_stb_o(wb_spi_flash_stb_o),
    .wb_spi_flash_cti_o(wb_spi_flash_cti_o),
    .wb_spi_flash_bte_o(wb_spi_flash_bte_o),
    .wb_spi_flash_dat_i(wb_spi_flash_dat_i),
    .wb_spi_flash_ack_i(wb_spi_flash_ack_i),
    .wb_spi_flash_err_i(wb_spi_flash_err_i),
    .wb_spi_flash_rty_i(wb_spi_flash_rty_i),

    // DATA MEM
    .wb_dmem_adr_o(wb_dmem_adr_o),
    .wb_dmem_dat_o(wb_dmem_dat_o),
    .wb_dmem_sel_o(wb_dmem_sel_o),
    .wb_dmem_we_o(wb_dmem_we_o), 
    .wb_dmem_cyc_o(wb_dmem_cyc_o),
    .wb_dmem_stb_o(wb_dmem_stb_o),
    .wb_dmem_cti_o(wb_dmem_cti_o),
    .wb_dmem_bte_o(wb_dmem_bte_o),
    .wb_dmem_dat_i(wb_dmem_dat_i),
    .wb_dmem_ack_i(wb_dmem_ack_i),
    .wb_dmem_err_i(wb_dmem_err_i),
    .wb_dmem_rty_i(wb_dmem_rty_i),

    
    // IMEM
    .wb_imem_adr_o(wb_imem_adr_o),
    .wb_imem_dat_o(wb_imem_dat_o),
    .wb_imem_sel_o(wb_imem_sel_o),
    .wb_imem_we_o(wb_imem_we_o), 
    .wb_imem_cyc_o(wb_imem_cyc_o),
    .wb_imem_stb_o(wb_imem_stb_o),
    .wb_imem_cti_o(wb_imem_cti_o),
    .wb_imem_bte_o(wb_imem_bte_o),
    .wb_imem_dat_i(wb_imem_dat_i),
    .wb_imem_ack_i(wb_imem_ack_i),
    .wb_imem_err_i(wb_imem_err_i),
    .wb_imem_rty_i(wb_imem_rty_i),

    // UART 
    .wb_uart_adr_o(wb_uart_adr_o),
    .wb_uart_dat_o(wb_uart_dat_o),
    .wb_uart_sel_o(wb_uart_sel_o),
    .wb_uart_we_o(wb_uart_we_o),
    .wb_uart_cyc_o(wb_uart_cyc_o),
    .wb_uart_stb_o(wb_uart_stb_o),
    .wb_uart_cti_o(wb_uart_cti_o),
    .wb_uart_bte_o(wb_uart_bte_o),
    .wb_uart_dat_i(wb_uart_dat_i),
    .wb_uart_ack_i(wb_uart_ack_i),
    .wb_uart_err_i(wb_uart_err_i),
    .wb_uart_rty_i(wb_uart_rty_i),

    // GPIO
    .wb_gpio_adr_o(wb_gpio_adr_o),
    .wb_gpio_dat_o(wb_gpio_dat_o),
    .wb_gpio_sel_o(wb_gpio_sel_o),
    .wb_gpio_we_o(wb_gpio_we_o),
    .wb_gpio_cyc_o(wb_gpio_cyc_o),
    .wb_gpio_stb_o(wb_gpio_stb_o),
    .wb_gpio_cti_o(wb_gpio_cti_o),
    .wb_gpio_bte_o(wb_gpio_bte_o),
    .wb_gpio_dat_i(wb_gpio_dat_i),
    .wb_gpio_ack_i(wb_gpio_ack_i),
    .wb_gpio_err_i(wb_gpio_err_i),
    .wb_gpio_rty_i(wb_gpio_rty_i)
      
  );

  // ============================================
  //                   Peripherals 
  // ============================================
  // Instantate the peripherals here

  // Here is the tri state buffer logic for setting iopin as input or output based
  // on the bits stored in the en_gpio register
  wire [31:0] en_gpio;
  wire        gpio_irq;

  wire [31:0] i_gpio;
  wire [31:0] o_gpio;

  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : gpio_gen_loop
      bidirec gpio1 (
          .oe(en_gpio[i]),
          .inp(o_gpio[i]),
          .outp(i_gpio[i]),
          .bidir(io_data[i])
      );
    end
  endgenerate

  // ============================================
  //                 GPIO Instantiation
  // ============================================

// Instantiate the GPIO peripheral here 
 gpio_top gpio_instance (
    .wb_clk_i(clk),
    .wb_rst_i(~reset_n),
    .wb_cyc_i(wb_gpio_cyc_o),
    .wb_adr_i(wb_gpio_adr_o[7:0]),
    .wb_dat_i(wb_gpio_dat_o),
    .wb_sel_i(wb_gpio_sel_o),
    .wb_we_i(wb_gpio_we_o),
    .wb_stb_i(wb_gpio_stb_o),
    .wb_dat_o(wb_gpio_dat_i),
    .wb_ack_o(wb_gpio_ack_i),
    .wb_err_o(wb_gpio_err_i),
    .i_gpio(i_gpio),
    .o_gpio(o_gpio),
    .en_gpio(en_gpio)
  );


// =================UART=======================
    
    // UART	signals
//    logic								 srx_pad_i;
//    logic 								 stx_pad_o;
//    logic 								 rts_pad_o;
//    logic								 cts_pad_i;
    logic 								 dtr_pad_o;
    logic								 dsr_pad_i;
    logic								 ri_pad_i;
    logic								 dcd_pad_i;
    logic  								 int_o;
    logic debug ;
    // Instantiate the UART
    uart_top uart(.wb_clk_i(clk), .wb_rst_i(~reset_n), .wb_adr_i(wb_uart_adr_o[2:0]),
              .wb_dat_i(wb_uart_dat_o[7:0]), .wb_dat_o(wb_uart_dat_i[7:0]), .wb_we_i(wb_uart_we_o) ,
              .wb_stb_i(wb_uart_stb_o), .wb_cyc_i(wb_uart_cyc_o), .wb_sel_i(wb_uart_sel_o), .wb_ack_o(wb_uart_ack_i),
              .int_o(int_o), .srx_pad_i(srx_pad_i), .stx_pad_o(stx_pad_o), .rts_pad_o(rts_pad_o), 
              .dtr_pad_o(dtr_pad_o), .dsr_pad_i(dsr_pad_i), .ri_pad_i(ri_pad_i),
              .dcd_pad_i(dcd_pad_i));
    //==============================================
    
  // ============================================
  //             Data Memory Instance
  // ============================================

  // Instantiate data memory here 
    data_mem #(
        .DEPTH(IMEM_DEPTH)
    ) data_mem_inst (
        .clk_i       (clk            ),
        .rst_i       (~reset_n         ),
        .cyc_i       (wb_dmem_cyc_o), 
        .stb_i       (wb_dmem_stb_o),
        .adr_i       (wb_dmem_adr_o      ),
        .we_i        (wb_dmem_we_o ),
        .sel_i       (wb_dmem_sel_o),
        .dat_i       (wb_dmem_dat_o),
        .dat_o       (wb_dmem_dat_i),
        .ack_o       (wb_dmem_ack_i)
    );



// ============================================
    //          Instruction Memory Instance
    // ============================================

    logic [31:0] imem_inst;

    logic [31:0] imem_addr;
    

    assign imem_addr = sel_boot_rom ? wb_imem_adr_o: current_pc;


    data_mem #(
        .DEPTH(IMEM_DEPTH)
    ) inst_mem_inst (
        .clk_i       (clk            ),
        .rst_i       (~reset_n         ),
        .cyc_i       (wb_imem_cyc_o), 
        .stb_i       (wb_imem_stb_o),
        .adr_i       (imem_addr      ),
        .we_i        (wb_imem_we_o ),
        .sel_i       (wb_imem_sel_o),
        .dat_i       (wb_imem_dat_o),
        .dat_o       (wb_imem_dat_i),
        .ack_o       (wb_imem_ack_i)
    );

    assign imem_inst = wb_imem_dat_i;


  // BOOT ROM 
  //   logic [31:0] rom_inst, rom_inst_ff;
  logic [31:0] rom_inst_ff;

  rom rom_instance (
      .addr(current_pc[11:0]),
      .inst(rom_inst)
  );

  // register after boot rom (to syncronize with the pipeline and inst mem)
  n_bit_reg #(
      .n(32)
  ) rom_inst_reg (
      .clk(clk),
      .reset_n(reset_n),
      .data_i(rom_inst),
      .data_o(rom_inst_ff),
      .wen(if_id_reg_en)
  );



  // Inst selection mux
  assign sel_boot_rom = &current_pc[31:12];  // 0xfffff000 - to - 0xffffffff 
  always @(posedge clk) sel_boot_rom_ff <= sel_boot_rom;
  mux2x1 #(
      .n(32)
  ) rom_imem_inst_sel_mux (
      .in0(imem_inst),
      .in1(rom_inst_ff),
      .sel(sel_boot_rom_ff),
      .out(inst)
  );

assign inst_out=inst;
assign current_pc_out=current_pc;

endmodule : rv32i_soc