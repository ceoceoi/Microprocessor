//import riscv_types::*;
//`timescale 1ns / 1ps


//// Define the RVFI output structure type
//typedef struct packed {
//    logic        rvfi_valid;
//    logic finished_flag;  // for RTL team
//    logic [31:0] rvfi_insntruction;
//    logic [31:0] rvfi_rd_wdata;     // result (p_mux)
//    logic [4:0]  rvfi_rs1_address;
//    logic [4:0]  rvfi_rs2_address;
//    logic [4:0]  rvfi_rs3_address;
//    logic [31:0] rvfi_rs1_rdata;
//    logic [31:0] rvfi_rs2_rdata;
//    logic [31:0] rvfi_rs3_rdata;
//    logic [4:0]  rvfi_rd_address;  // ID stage
//    logic [31:0] rvfi_pc_id;    // rvfi_pc_rdata
//    logic [31:0] rvfi_next_pc;  // pc+4  or next pc if jump
//    alu_t alu_ctrl_id;
////    logic [31:0] rvfi_mem_address;
////    logic [ 3:0] rvfi_mem_rmask;  // we don't have 
////    logic [ 3:0] rvfi_mem_wmask;  // we don't have
////    logic [31:0] rvfi_mem_wdata;
////    logic [31:0] rvfi_mem_rdata;
////    logic finished_flag;  // for RTL team
//} rvfi_trace_t;


//module rvfi_tracker(
//    input  logic clk,
//    input  logic reset_n,
    
//    // Instruction information inputs
//    input  alu_t alu_ctrl_id,
//    input  logic [31:0] inst_id,
//    input  logic [4:0]  rs1_address_id,
//    input  logic [4:0]  rs2_address_id,
//    input  logic [4:0]  rs3_address_id,
//    input  logic [31:0] reg_rdata1_id,
//    input  logic [31:0] reg_rdata2_id,
//    input  logic [31:0] reg_rdata3_id,
//    input  logic [4:0]  rd_address_id,
//    input  logic [31:0] p_mux_result,  // "rvfi_rd_wdata"  -> result from p_mux
//    input  logic [31:0] current_pc_id,
//    input  logic [31:0] p_mux_pc_plus_4,  // PC+4 from p_mux signals
////    input logic [31:0] rvfi_mem_addr,   // TODO: change their names
////    input logic rvfi_mem_rmask;  // we don't have 
////    input logic rvfi_mem_wmask;  // we don't have
////    input logic [31:0] rvfi_mem_wdata,
////    input logic [31:0] rvfi_mem_rdata
    
//    // signals for RTL team
//    input logic stalled,
    
//    // RVFI output interface
//    output logic        rvfi_valid,
//    output logic [31:0] rvfi_insn,
//    output logic [4:0]  rvfi_rs1_addr,
//    output logic [4:0]  rvfi_rs2_addr,
//    output logic [4:0]  rvfi_rs3_addr,
//    output logic [31:0] rvfi_rs1_rdata,
//    output logic [31:0] rvfi_rs2_rdata,
//    output logic [31:0] rvfi_rs3_rdata,
//    output logic [4:0]  rvfi_rd_addr,
//    output logic [31:0] rvfi_rd_wdata,
//    output logic [31:0] rvfi_pc_rdata,
//    output logic [31:0] rvfi_pc_wdata  // next pc
////    output logic [31:0] rvfi_mem_addr,  // TODO: write on them later if needed
////    output logic rvfi_mem_rmask;  // we don't have 
////    ouptut logic rvfi_mem_wmask;  // we don't have
////    output logic [31:0] rvfi_mem_wdata,
////    output logic [31:0] rvfi_mem_rdata
//);

//    // Declare a dynamic array of rvfi_trace_t to store instruction traces
//    rvfi_trace_t inst_file[$];  // Dynamic array to hold instruction traces
//    rvfi_trace_t new_trace;

//    // debugging signals
//    logic inst_got_result, inst_out_finish_flag;
//    logic valid_inst;
//    logic [31:0] index_written;
//    logic [31:0] pc_index_written;


//    // writing to the dynamic array
//    always @(posedge clk) begin
////        if (stalled) begin
////            rvfi_valid = 'b0;
////            rvfi_insn = 'b0;
////            rvfi_rs1_addr = 'b0;
////            rvfi_rs2_addr = 'b0;
////            rvfi_rs3_addr = 'b0;  // handled by alu_ctrl
////            rvfi_rs1_rdata ='b0;
////            rvfi_rs2_rdata ='b0;
////            rvfi_rs3_rdata ='b0;  // handled by alu_ctrl
////            rvfi_rd_addr = 'b0;
////            rvfi_rd_wdata = 'b0;  // result
////            rvfi_pc_rdata = 'b0;
////            rvfi_pc_wdata = 'b0;  // next pc
////        end else if (!stalled) begin
//            // Create an entry for the instruction

//            // Fill the new_trace with information
//            rvfi_valid = 1'b1;  // valid instruction
//            new_trace.rvfi_valid = 1'b1;
//            new_trace.rvfi_insntruction = inst_id;
//            new_trace.rvfi_rs1_address = rs1_address_id;
//            new_trace.rvfi_rs2_address = rs2_address_id;
//            new_trace.rvfi_rs3_address = rs3_address_id;
//            new_trace.rvfi_rs1_rdata = reg_rdata1_id;
//            new_trace.rvfi_rs2_rdata = reg_rdata2_id;
//            new_trace.rvfi_rs3_rdata = reg_rdata3_id;
//            new_trace.rvfi_rd_address = rd_address_id;
//            new_trace.rvfi_rd_wdata = 1'b0;  // result
//            new_trace.rvfi_pc_id = current_pc_id;
//            new_trace.rvfi_next_pc = p_mux_pc_plus_4;
//            new_trace.alu_ctrl_id = alu_ctrl_id;
//            new_trace.finished_flag = 1'b0; // indicates that instruction has finished
            
//            valid_inst = new_trace.rvfi_insntruction!='b0;
//            if( valid_inst ) begin
//                inst_file.push_back(new_trace);  // Append to the end of the dynamic array
//             end
//            if(inst_file.size()>1) begin 
//            if (inst_file[inst_file.size()-1].rvfi_pc_id==inst_file[inst_file.size()-2].rvfi_pc_id)
//            inst_file.delete(inst_file.size()-1);
//            end 

//            // put that instruction as "ready to verify" if its result received
//            for (int i=0; i<inst_file.size(); i++) begin
//                inst_got_result = p_mux_pc_plus_4-4==inst_file[i].rvfi_pc_id   &&   inst_file[i].finished_flag==0;
////                if (p_mux_pc_plus_4-4  == inst_file[i].rvfi_pc_id && inst_file[i].finished_flag==0) begin   // same instruction and not finished
//                if (inst_got_result) begin   // same instruction and not finished
//                    inst_file[i].rvfi_rd_wdata = p_mux_result;
//                    inst_file[i].finished_flag = 1'b1;
//                    index_written= i;
//                    pc_index_written = p_mux_pc_plus_4 - 4;
//                    break;
//                end
//            end
            
            
            
////        end  // End writing logic
        

//        // regadless if the system stalled or not, read informations of the first instruction entered (FIFO memory)
////        if (inst_file[0].finished_flag) begin
//        inst_out_finish_flag = inst_file[0].finished_flag;
//              $display("time: %d",$time);
//            foreach(inst_file[i]) begin
//$display(" element %d: operation = %s --rs1 =%h  --rs2 =%h  --rs3=%h --result=%h  --F= %b --pc = %h ",
//                  i,
//                  inst_file[i].alu_ctrl_id.name(),
//                  inst_file[i].rvfi_rs1_rdata,
//                  inst_file[i].rvfi_rs2_rdata,
//                  inst_file[i].rvfi_rs3_rdata,
//                  inst_file[i].rvfi_rd_wdata,
//                  inst_file[i].finished_flag,
//                  inst_file[i].rvfi_pc_id      );
//            end
//            $display("====================================");
 
                    
//        // read instruction information
//        if (inst_out_finish_flag) begin
//            rvfi_valid = inst_file[0].rvfi_valid;
//            rvfi_insn = inst_file[0].rvfi_insntruction;
//            rvfi_rs1_addr = inst_file[0].rvfi_rs1_address;
//            rvfi_rs2_addr = inst_file[0].rvfi_rs2_address;
//            rvfi_rs3_addr = inst_file[0].rvfi_rs3_address;  // handled by alu_ctrl
//            rvfi_rs1_rdata = inst_file[0].rvfi_rs1_rdata;
//            rvfi_rs2_rdata = inst_file[0].rvfi_rs2_rdata;
//            rvfi_rs3_rdata = inst_file[0].rvfi_rs3_rdata;  // handled by alu_ctrl
//            rvfi_rd_addr = inst_file[0].rvfi_rd_address;
//            rvfi_rd_wdata = inst_file[0].rvfi_rd_wdata;
//            rvfi_pc_rdata = inst_file[0].rvfi_pc_id;
//            rvfi_pc_wdata = inst_file[0].rvfi_next_pc;
            
//            // remove the instruction has read
//            inst_file.pop_front();
//        end  // end reading logic
//        else begin
//            rvfi_valid = 'b0;
//            rvfi_insn = 'b0;
//            rvfi_rs1_addr = 'b0;
//            rvfi_rs2_addr = 'b0;
//            rvfi_rs3_addr = 'b0;  // handled by alu_ctrl
//            rvfi_rs1_rdata ='b0;
//            rvfi_rs2_rdata ='b0;
//            rvfi_rs3_rdata ='b0;  // handled by alu_ctrl
//            rvfi_rd_addr = 'b0;
//            rvfi_rd_wdata = 'b0;  // result
//            rvfi_pc_rdata = 'b0;
//            rvfi_pc_wdata = 'b0;  // next pc
//        end
//    end  // End always block
    
    
    
    
//endmodule

