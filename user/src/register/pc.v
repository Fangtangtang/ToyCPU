// program counter

`include"src/defines.v"

// sequential logic
module pc#(parameter LEN = 32)
          (input wire clk,
           input wire rst,
           input rdy_in,
           input [LEN-1:0] pre_pc,
           input [LEN-1:0] npc,
           input [LEN-1:0] special_npc,
           input control_signal,
           output if_flag,
           output [LEN-1:0] cur_pc);
    
    // store pc state
    reg [LEN-1:0] pc_register;
    reg flag;
    assign cur_pc  = pc_register;
    assign if_flag = flag;
    
    always @(posedge clk) begin
        if (rst == `TRUE) begin
            pc_register <= 0;
        end
        else
            if (rdy_in) begin
                if (pre_pc == pc_register) begin
                    flag = 1;
                    if (control_signal == `TRUE) begin
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
