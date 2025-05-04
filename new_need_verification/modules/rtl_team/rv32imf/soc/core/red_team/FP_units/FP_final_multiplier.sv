import riscv_types::*;

module FP_final_Multiplier (
    input logic clk,rst,clear,en,
    input logic [31:0] a,   
    input logic [31:0] b, 
    input logic [2:0] rm,
    input logic P_signal,
    input exe_p_mux_bus_type fadd_sub_pipeline_signals_i,
    output exe_p_mux_bus_type fadd_sub_pipeline_signals_o,
    output logic P_O_signal,
    output logic [31:0] result
    
);
    //for pipeline 
    logic [2:0] rm_pi;
    logic p_pi_signal,sgin_res_pi;
    logic [47:0]mant_round_pi;
    logic [7:0] exp_a_pi, exp_b_pi;
    logic [31:0] a_pi, b_pi;
  
    logic sign_a, sign_b, sign_res;
    logic [7:0] exp_a, exp_b;
    logic [8:0] exp_res,exp_round;
    logic [23:0] mant_a, mant_b;
    logic [47:0] mant_res, mant_round;
    logic [7:0] final_exp;
    logic [22:0] final_mant;

    assign sign_a = a[31];
    assign sign_b = b[31];
    assign exp_a_pi = a[30:23];
    assign exp_b_pi = b[30:23];
    assign mant_a = (exp_a_pi == 8'h00) ? {1'b0, a[22:0]} : {1'b1, a[22:0]}; // Handle subnormal numbers
    assign mant_b = (exp_b_pi == 8'h00) ? {1'b0, b[22:0]} : {1'b1, b[22:0]}; // Handle subnormal numbers
    
     logic G,R,S;
    
    assign sgin_res_pi = sign_a ^ sign_b;
    
    
    
    assign mant_round_pi = mant_a * mant_b;
    
 logic inc_overflow; 
 
      always@(posedge clk ,negedge rst)begin 
     
        if(!rst)begin
            a_pi <= 'b0;
            b_pi <= 'b0;
            
            sign_res <= 0;
            P_O_signal <= 0;
            rm_pi <= 0;
            mant_round <= 0;
            exp_a <=0 ;
            exp_b <=0;
            fadd_sub_pipeline_signals_o <= 0;
        
        end else if (clear)begin
            a_pi <= 'b0;
            b_pi <= 'b0;
            
            sign_res <= 0;
            P_O_signal <= 0;
            rm_pi <= 0;
            mant_round <= 0;
            exp_a <=0 ;
            exp_b <=0;
            fadd_sub_pipeline_signals_o <= 0;
        
        
         end else if (en) begin 
            a_pi <= a;
            b_pi <= b;
            
            sign_res <= sgin_res_pi;
            P_O_signal <= P_signal;
            rm_pi <= rm;
            mant_round <= mant_round_pi;
            exp_a <= exp_a_pi;
            exp_b <= exp_b_pi;
      
            fadd_sub_pipeline_signals_o <= fadd_sub_pipeline_signals_i;
     
        end 
    end
    
 
     always_comb begin
        if (exp_a == 8'h00) exp_round = exp_b - 127; // Subnormal handling
        else if (exp_b == 8'h00) exp_round = exp_a - 127; // Subnormal handling
        else exp_round = exp_a + exp_b - 127;
    end 
    
    always_comb begin
        G = mant_round[22];
        R = mant_round[21];
        S = |mant_round[20:0];

                case (rm_pi)
                3'b000: begin // *RNE: Round to Nearest, Ties to Even*
                    if(G) begin
                        case ({R,S})
                        2'b00: begin

                            if(mant_round[24]) begin
                                {inc_overflow,mant_res} = mant_round + 48'd8388608;
                                if(inc_overflow) begin
                                    exp_res = exp_round + 1;
                                end
                                else begin
                                    exp_res = exp_round;
                                end
                            end
                            else begin
                               mant_res = mant_round;
                               exp_res = exp_round;
                            end
                        end
                        default: begin
                           {inc_overflow,mant_res} = mant_round + 48'd8388608;
                                 if(inc_overflow) begin
                                    exp_res = exp_round + 1;
                                end
                                else begin
                                    exp_res = exp_round;
                                end
                        end
                        endcase
                    end
                    else 
                       mant_res = mant_round;
                        exp_res = exp_round;
                end

                3'b001: begin // *RTZ: Round Toward Zero (Truncate)*
                      mant_res = mant_round;
                        exp_res = exp_round;
                end

                3'b010: begin // *RDN: Round Down (-∞)*
                    if (sign_res && (R || S || G)) begin
                        {inc_overflow,mant_res} = mant_round + 48'd8388608;
                        if(inc_overflow) begin
                            exp_res = exp_round + 48'd8388608;
                        end
                        else begin
                            exp_res = exp_round;
                        end
                    end
                    else
                          mant_res = mant_round;
                        exp_res = exp_round;
                end

                3'b011: begin // *RUP: Round Up (+∞)*
                    if (~sign_res && (R || S || G)) begin
                        {inc_overflow,mant_res} = mant_round + 48'd8388608;
                        if(inc_overflow) begin
                            exp_res = exp_round + 1;
                        end
                        else begin
                             exp_res = exp_round ;
                        end
                    end
                    else
                          mant_res = mant_round;
                        exp_res = exp_round;
                end

                3'b100: begin // round to maximum magnitude 
                    if (G) begin
                        {inc_overflow,mant_res} = mant_round + 48'd8388608;
                        if(inc_overflow) begin
                            exp_res = exp_round + 1;
                        end
                        else begin
                            exp_res = exp_round;
                        end  
                        
                    end
                    else
                        mant_res = mant_round;
                        exp_res = exp_round;
                end
                default : 
                begin 
               mant_res = mant_round;
                        exp_res = exp_round;     
                end
                endcase
            end
    
    // Normalize
    always_comb begin
        if (mant_res[47]) begin  
            final_mant = mant_res[46:24];  // Normalize by shifting left
            final_exp = exp_res + 1;       // Increase the exponent
        end else begin

            final_mant = mant_res[45:23];  // Normalize
            final_exp = exp_res;
        end
    end
    
    // Special cases handling
    always_comb begin
        if ((exp_a == 8'hFF && a_pi[22:0] != 0) || (exp_b == 8'hFF && b_pi[22:0] != 0)) begin
            // NaN case (if any input is NaN, result is NaN)
            result = {1'b0, 8'hFF, 23'h400000};  // Canonical NaN
        end else if (exp_a == 8'hFF || exp_b == 8'hFF) begin
            if ((a_pi == 32'h7F800000 && b_pi == 32'h00000000) || (a_pi == 32'h00000000 && b_pi == 32'h7F800000)) begin
                result = {1'b0, 8'hFF, 23'h400000};  // NaN (Inf * 0 case)
            end else begin
                result = {sign_res, 8'hFF, 23'b0};  // Infinity case
            end
        end else if (a_pi == 32'b0 || b_pi == 32'b0) begin
            // Zero case (if any input is zero, result is zero)
            result = 32'b0;
        end else if (final_exp >= 8'hFF) begin
            // Overflow case (result is greater than max value, return infinity)
            result = {sign_res, 8'hFF, 23'b0};
        end else if (final_exp <= 0 || mant_res == 0) begin
            // Underflow case (result is too small, return zero)
            result = 32'b0;
        end else if (exp_a != 0 && exp_b != 0 && exp_res[8] == 1 )begin
            result = {sign_res, 8'hFF, 23'b0}; 
            // result overflow 
        end else if (exp_a + exp_b < 127 )begin
            result = 32'b0;
            //   result underflow 
        end else begin
            // Normal case (result is valid)
            result = {sign_res, final_exp, final_mant};
        end
    end
    
    endmodule
