import riscv_types::*;

module FP_add_sub (
    input logic clk,
    input logic rst,
    input logic en,
    input logic [2:0] clear,    // based on number of stages in this pipelined unit 
    input logic add_sub,
    input logic [31:0] num1,
    input logic [31:0] num2,
    input logic [2:0] rm,  // Rounding Mode
    output logic [31:0] sum,  // result
    
    input logic p_start,
    output logic p_result,
    input exe_p_mux_bus_type fadd_sub_pipeline_signals_i,
    output exe_p_mux_bus_type fadd_sub_pipeline_signals_o,
    
    // all rd used within this unit (fadd_sub unit)
    output logic [4:0] uu_rd [0:1],    // means "unit uses these rds"
    output logic [1:0] uu_reg_write,
    output logic [1:0] uu_FP_reg_write
);

logic [31:0] result;
logic p_logic[2:0];
exe_p_mux_bus_type stage [2:0];

// clear logic
assign uu_rd[0] = stage[0].rd;
assign uu_rd[1] = stage[1].rd;
assign uu_reg_write = {stage[1].reg_write, stage[0].reg_write };
assign uu_FP_reg_write = {stage[1].FP_reg_write, stage[0].FP_reg_write };

assign sum = result;

//pipeline logic
always_ff @(posedge clk , negedge rst) begin
if (~rst) begin 
    p_logic[0]                  <=1'b0;
    p_logic[1]                  <=1'b0;
    p_logic[2]                  <=1'b0;
    p_result                    <=1'b0;
    stage[0]                    <='b0;
    stage[1]                    <='b0;
    stage[2]                    <='b0;
    fadd_sub_pipeline_signals_o <='b0;
end
else if (|clear) begin  // if there's any "clear" signal ... do the following ...
    p_logic[0]                  <=clear[0]? 1'b0 : p_start;
    p_logic[1]                  <=clear[1]? 1'b0 : p_logic[0];
    p_result                  <=clear[2]? 1'b0 : p_logic[1];
    stage[0]                    <=clear[0]? 1'b0 : fadd_sub_pipeline_signals_i;
    stage[1]                    <=clear[1]? 'b0 : stage[0];
    fadd_sub_pipeline_signals_o                   <=clear[2]? 'b0 : stage[1];
end 
else if(en) begin 
    
    p_logic[0]<=p_start;
    p_logic[1]<=p_logic[0];
    p_result<=p_logic[1];
    
    stage[0]<=fadd_sub_pipeline_signals_i;
    stage[1]<=stage[0];
    fadd_sub_pipeline_signals_o<=stage[1];
end

end // End always_ff


logic NaN   ;
logic inf1  ;
logic inf2  ;
logic sign1 ;
logic sign2 ;
logic [7:0] exp_res;
logic [47:0] mantissa1_aligned;
logic [47:0] mantissa2_aligned;
        
        // EA extract align stage 
 extract_align_FP extract_stage(
        // inputs 
        .add_sub(add_sub)                      ,
        .num1(num1)                            ,
        .num2(num2)                            ,
        // outputs                             ,
        .NaN(NaN)                              ,
        .inf1(inf1)                            ,
        .inf2(inf2)                            ,
        .sign1(sign1)                            ,
        .sign2(sign2)                            ,
        .exp_res(exp_res)                      ,
        .mantissa1_aligned(mantissa1_aligned)  ,
        .mantissa2_aligned(mantissa2_aligned)  
         

    );
    
    logic             NaN_EA                 ;
    logic             inf1_EA                ;
    logic             inf2_EA                ;
    logic             sign1_EA                ;
    logic             sign2_EA                ;
    logic [7:0]       exp_res_EA             ;
    logic [47:0]      mantissa1_aligned_EA   ;
    logic [47:0]      mantissa2_aligned_EA   ;
    logic [2:0] rm_EA;
    
    
always_ff @(posedge clk , negedge rst) begin
if (~rst) begin 
    
     NaN_EA                 <=1'b0;
     inf1_EA                <=1'b0;
     inf2_EA                <=1'b0;
     exp_res_EA             <=8'b0;
     mantissa1_aligned_EA   <=48'b0;  
     mantissa2_aligned_EA   <=48'b0;  
     sign1_EA<=1'b0;  
     sign2_EA<=1'b0;  
     rm_EA<=3'b000;

end
else if (clear[0]) begin 
    
     NaN_EA                 <=1'b0;
     inf1_EA                <=1'b0;
     inf2_EA                <=1'b0;
     exp_res_EA             <=8'b0;
     mantissa1_aligned_EA   <=48'b0;  
     mantissa2_aligned_EA   <=48'b0;
     sign1_EA<=1'b0;  
     sign2_EA<=1'b0;    
     rm_EA<=3'd0;

end 
else if(en) begin 
    
     NaN_EA                 <=NaN;
     inf1_EA                <=inf1;
     inf2_EA                <=inf2;
     exp_res_EA             <=exp_res;
     mantissa1_aligned_EA   <=mantissa1_aligned;  
     mantissa2_aligned_EA   <=mantissa2_aligned;
     sign1_EA<=sign1;  
     sign2_EA<=sign2;  
     rm_EA<=rm;

end

end


        logic [23:0] grs;
        logic [23:0] mantissa_sum;
        logic carry;
        logic sign_res;
        
        //AS  add sub stage 
 add_sub_FP add_sub_stage(
        //inputs
        .sign1              (sign1_EA),
        .sign2              (sign2_EA),
        .mantissa1_aligned  (mantissa1_aligned_EA),
        .mantissa2_aligned  (mantissa2_aligned_EA),
        //outputs
        .grs                (grs),
        .mantissa_sum       (mantissa_sum),
        .carry              (carry),
        .sign_res           (sign_res)
        
        
    );
    
        logic [23:0] grs_AS             ;
        logic [23:0] mantissa_sum_AS    ;
        logic        carry_AS           ;
        logic        sign_res_AS        ;  
        logic [7:0]       exp_res_AS             ;
        logic NaN_AS   ;
        logic inf1_AS  ;
        logic inf2_AS  ;
        logic sign1_AS ;
        logic sign2_AS ;
        logic [2:0] rm_AS ;
  
  
  
  
    


always_ff @(posedge clk , negedge rst) begin
if (~rst) begin 
   
        grs_AS            <=24'd0;
        mantissa_sum_AS   <=24'd0;
        carry_AS          <=1'b0;
        sign_res_AS       <=1'b0; 
        exp_res_AS       <=7'd0;
        NaN_AS            <=1'b0;
        inf1_AS           <=1'b0;
        inf2_AS           <=1'b0;
        sign1_AS          <=1'b0;
        sign2_AS          <=1'b0;
        rm_AS             <=3'd0;

end
else if (clear[1]) begin 
    

        grs_AS            <=24'd0;
        mantissa_sum_AS   <=24'd0;
        carry_AS          <=1'b0;
        sign_res_AS       <=1'b0;
        exp_res_AS        <=7'd0;
        NaN_AS            <=1'b0;
        inf1_AS           <=1'b0;
        inf2_AS           <=1'b0;
        sign1_AS          <=1'b0;
        sign2_AS          <=1'b0;
        rm_AS             <=3'd0;



  
end 
else if(en) begin 


        grs_AS            <=grs;
        mantissa_sum_AS   <=mantissa_sum;
        carry_AS          <=carry;
        sign_res_AS       <=sign_res;
        exp_res_AS        <=exp_res_EA;
        NaN_AS            <=NaN_EA    ;
        inf1_AS           <=inf1_EA   ;
        inf2_AS           <=inf2_EA   ;
        sign1_AS          <=sign1_EA ;
        sign2_AS          <=sign2_EA  ;
        rm_AS<=rm_EA;



end

end
        logic [22:0] mantissa_norm;
        logic [7:0] exp_norm;
        logic underflow;
             // N  normalize stage
normalize_FP normalize_stage(
        
        // inputs 
        .mantissa_sum        (mantissa_sum_AS),
        .exp_res             (exp_res_AS),
        .carry               (carry_AS),
        .sign1(sign1_AS),
        .sign2(sign2_AS),

        //output
        .mantissa_norm       (mantissa_norm),
        .exp_norm            (exp_norm),
        .underflow(underflow)
        
    );

        logic [22:0] mantissa_norm_N;
        logic [23:0] grs_N;
        logic [7:0]  exp_norm_N      ;
        logic        sign_res_N      ;
        logic   NaN_N;   
        logic  inf1_N;  
        logic  inf2_N;  
        logic sign1_N;
        logic sign2_N; 
        logic underflow_N; 
        logic [2:0] rm_N; 
        
        
always_ff @(posedge clk , negedge rst) begin
if (~rst) begin 
   
mantissa_norm_N    <=23'd0;
exp_norm_N         <=8'd0;
sign_res_N         <=1'b0;
grs_N               <=24'd0;
NaN_N             <=1'b0;
inf1_N             <=1'b0;
inf2_N             <=1'b0;
sign1_N             <=1'b0;
sign2_N             <=1'b0;   
rm_N<=3'd0;
underflow_N<=1'b0;


end
else if (clear[2]) begin 
    

   
mantissa_norm_N    <=23'd0;
exp_norm_N         <=8'd0;
sign_res_N         <=1'b0;    
grs_N               <=24'd0       ;
  NaN_N             <=1'b0;
 inf1_N             <=1'b0;
 inf2_N             <=1'b0;
sign1_N             <=1'b0;
sign2_N             <=1'b0;
rm_N<=3'd0;
underflow_N<=1'b0;

end 
else if(en) begin 

mantissa_norm_N     <=mantissa_norm;
exp_norm_N          <=exp_norm     ;
sign_res_N          <=sign_res_AS     ;
grs_N               <=grs_AS       ;
  NaN_N             <=  NaN_AS;
 inf1_N             <= inf1_AS;
 inf2_N             <= inf2_AS;
sign1_N             <=sign1_AS;
sign2_N             <=sign2_AS;
rm_N<=rm_AS;
underflow_N<=underflow;




end

end

 round_FP round_stage(
 
        //inputs
        .NaN            (NaN_N),
        .inf1           (inf1_N),
        .inf2           (inf2_N),
        .sign1          (sign1_N),
        .sign2          (sign2_N),
        .grs            (grs_N),
        .rm             (rm_N),
//        .rm             (~rm_N),    // negate it if you're using RISC-V32 toolchain (like gcc-toolchain or gnu-toolchain)
        .exp_norm       (exp_norm_N),
        .mantissa_norm  (mantissa_norm_N),
        .sign_res       (sign_res_N),
        .underflow       (underflow_N),

       //outputs
        .result         (result)
    );

endmodule
