// #############################################################################################################################
// REGISTER FILE
// 
// 32个32位寄存器
// 
// 命令只需场景：
// - instruction decode阶段读取操作数
// - write back阶段向rd写
// 
// todo:reg file上流水后部件抢用，读写冲突
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
                  input write_back_enabled,
                  output [LEN-1:0] rs1_data,
                  output [LEN-1:0] rs2_data,
                  output [1:0] rf_status);
    
    // 32 registers
    reg [4:0]               rs1_index;
    reg [4:0]               rs2_index;
    reg [LEN-1:0]           register[31:0];
    
    reg [1:0]               status;
    assign rf_status = status;
    
    // integer file;
    // initial begin
    //     file = $fopen("/mnt/f/repo/ToyCPU/user/log.out","w");
    // end
    // always @(*) begin
    //     $fdisplay(file,$realtime);
    //     $fdisplay(file,"reg0:%d %o",register[0],register[0]);
    //     $fdisplay(file,"reg1:%d %o",register[1],register[1]);
    //     $fdisplay(file,"reg2:%d %o",register[2],register[2]);
    //     $fdisplay(file,"reg3:%d %o",register[3],register[3]);
    //     $fdisplay(file,"reg4:%d %o",register[4],register[4]);
    //     $fdisplay(file,"reg5:%d %o",register[5],register[5]);
    // end
    
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
            if (write_back_enabled)begin
                if (rf_signal == `RF_WRITE) begin
                    register[rd] <= data;
                    // status    <= `RF_FINISHED;
                end
                // else begin
                // status <= `RF_NOP;
                // end
                status <= `RF_FINISHED;
            end
            else begin
                status <= `RF_NOP;
            end
            
            
        end
    end
endmodule
