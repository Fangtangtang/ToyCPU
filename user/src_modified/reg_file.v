// #############################################################################################################################
// REGISTER FILE
// 
// 32个32位寄存器
// 
// 命令只需场景：
// - instruction decode阶段读取操作数
// - write back阶段向rd写
// 
// todo:reg file上流水后部件抢用
// #############################################################################################################################
`include "src_modified/defines.v"

module REG_FILE #(parameter LEN = 32)
                 (input wire clk,             // clock
                  input rst,
                  input rdy_in,
                  input rf_signal,            // nop、读、写
                  input wire [4:0] rs1,       // index of rs1
                  input wire [4:0] rs2,       // index of rs2
                  input wire [4:0] rd,        // index of rd
                  input [LEN-1:0] data,       // write back data
                  output [LEN-1:0] rs1_data,
                  output [LEN-1:0] rs2_data);
    
    // 32 registers
    reg [4:0]               rs1_index;
    reg [4:0]               rs2_index;
    reg [LEN-1:0]           register[31:0];
    
    
    assign rs1_data = register[rs1_index];
    assign rs2_data = register[rs2_index];
    
    always @(posedge clk) begin
        if (rst) begin
            for (integer i = 0 ;i < 32 ;i = i + 1) begin
                register[i] <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        if ((!rst)&&rdy_in)begin
            // 读
            rs1_index = rs1;
            rs2_index = rs2;
            // 写
            // else
            if (rf_signal == `RF_WRITE) begin
                register[rd] <= data;
            end
        end
    end
endmodule
