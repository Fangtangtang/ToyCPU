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
                 (input wire clk,            // clock
                  input rst,
                  input rdy_in,
                  input [1:0] rf_signal,     // nop、读、写
                  input wire [4:0] rs1,      // index of rs1
                  input wire [4:0] rs2,      // index of rs2
                  input wire [4:0] rd,       // index of rd
                  input [LEN-1:0] data,      // write back data
                  output [LEN-1:0] rs1_data,
                  output [LEN-1:0] rs2_data
                //   output rf_vis_finished
                  );
    
    // 32 registers
    reg [4:0]               rs1_index;
    reg [4:0]               rs2_index;
    reg [LEN-1:0]           register[31:0];
    
    // reg                     finished = 0;
    
    assign rs1_data        = register[rs1_index];
    assign rs2_data        = register[rs2_index];
    // assign rf_vis_finished = finished;
    
    // always @(negedge clk) begin
    //     // 在下降沿时将信号置为0
    //     finished <= 0;
    // end
    
    always @(posedge clk) begin
        if ((!rst)&&rdy_in)begin
            // 读
            if (rf_signal == `RF_READ) begin
                rs1_index = rs1;
                rs2_index = rs2;
                // finished <= 1;
            end
            // 写
            else
            if (rf_signal == `RF_WRITE) begin
                register[rd] <= data;
                // finished     <= 1;
            end
            // NOP
            // else
            // if (rf_signal == `RF_NOP) begin
            //     finished <= 1;
            // end
        end
    end
endmodule
