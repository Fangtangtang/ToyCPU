// register file
// 32 registers

module reg_file #(parameter LEN = 32)
                 (input wire clk,             // clock
                  input rst,
                  input rdy_in,
                  input reg_ex_signal,
                  input wire [4:0] rs1,       // index of rs1
                  input wire [4:0] rs2,       // index of rs2
                  input wire wb_flag,         // whether write back
                  input wire [4:0] rd,        // index of rd
                  input [LEN-1:0] data,       // write back data
                  output reg_stall,
                  output [LEN-1:0] rs1_data,
                  output [LEN-1:0] rs2_data);
    
    // 32 registers
    reg [4:0]               rs1_index;
    reg [4:0]               rs2_index;
    reg [LEN-1:0]           reg1;
    reg [LEN-1:0]           reg2;
    reg [LEN-1:0]           register[31:0];
    reg                     flag = 0;
    
    assign rs1_data  = reg1;
    assign rs2_data  = reg2;
    assign reg_stall = flag;
    always @(posedge clk) begin
        if ((!rst)&&rdy_in)begin
            if (reg_ex_signal) begin
                flag = 1;
                // read from register
                reg1 <= register[rs1_index];
                reg2 <= register[rs2_index];
                // write back
                if (wb_flag == 1) begin
                    register[rd] <= data;
                end
            end
            else begin
                flag = 0;
            end
        end
    end
endmodule
