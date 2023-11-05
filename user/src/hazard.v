// hazard
// used to control stall in every module
module hazard (input pc_stall,
               input reg_stall,
               input alu_stall,
               input mem_stall,
               output pc_ex_signal,
               output reg_ex_signal,
               output alu_ex_signal,
               output mem_ex_signal);
    
    assign pc_ex_signal  = ~(reg_stall||alu_stall||mem_stall);
    assign reg_ex_signal = ~(pc_stall||alu_stall||mem_stall);
    assign alu_ex_signal = ~(pc_stall||reg_stall||mem_stall);
    assign mem_ex_signal = ~(pc_stall||reg_stall||alu_stall);
    
endmodule
