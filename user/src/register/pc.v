// program counter

`include"src/defines.v"

// sequential logic
module pc#(parameter LEN = 32)
          (input wire clk,
           input wire rst,
           input rdy_in,
           input pc_ex_signal,
           input [LEN-1:0] npc,
           input [LEN-1:0] special_npc,
           input use_special_pc_flag,
           output pc_stall,
           output if_flag,
           output [LEN-1:0] cur_pc);
    
    // store pc state
    reg [LEN-1:0] pc_register;
    reg flag        = 0;
    assign cur_pc   = pc_register;
    assign pc_stall = flag;
    assign if_flag  = flag;
    
    // start executing
    // begin with instruction fetch
    // always @(negedge rst) begin
    // flag = 1;
    // end
    
    always @(posedge clk) begin
        if (rst == `TRUE) begin
            pc_register <= 0;
        end
        else
            if (rdy_in) begin
                if (pc_ex_signal) begin
                    flag = 1;
                    if (use_special_pc_flag == `TRUE) begin
                        pc_register <= special_npc;
                    end
                    else begin
                        pc_register <= npc;
                    end
                end
                else begin
                    flag = 0;
                end
            end
    end
    
endmodule
