// #############################################################################################################################
// CACHE
// 
// 接口：
// - 信号：clk
// - cpu交互：地址，数据（inst、data），操作指令，finished
// - memory交互：地址，数据，操作指令
// 
// cpu和memory交互的中间单元
// 主要用于辨别取instruction还是data
// 简易版，cashe size4
// 倒计时取数据
// #############################################################################################################################

`include "src_modified/defines.v"
module CACHE#(parameter ADDR_WIDTH = 17,
              parameter LEN = 32,
              parameter BYTE_SIZE = 8)
             (input wire clk,
              input [ADDR_WIDTH-1:0] addr,
              input [LEN-1:0] mem_write_data,
              input [1:0] mem_signal,
              input [BYTE_SIZE-1:0] mem_data,
              output [LEN-1:0] instruction,
              output [ADDR_WIDTH-1:0] mem_vis_addr, // 访存地址
              output mem_vis_signal,                // 0:read, 1:write
              output [LEN-1:0] mem_read_data,
              output [BYTE_SIZE-1:0] writen_data,   // 写入memory的数据
              output mem_vis_finished);
    
    reg [BYTE_SIZE-1:0] storage [0:3];
    
    reg [LEN-1:0] data;
    reg [ADDR_WIDTH-1:0] first_address;
    reg [ADDR_WIDTH-1:0] address;
    reg [2:0] STATE_CTR = 0;
    
    assign mem_vis_addr = address;
    
    reg finished            = 0;
    assign mem_vis_finished = finished;
    
    reg memory_vis_signal;
    assign mem_signal = memory_vis_signal;
    
    always @(negedge clk) begin
        if (finished)begin
            finished <= 0;
        end
    end
    
    always @(posedge clk) begin
        // 当前空闲
        if (!STATE_CTR) begin
            if (mem_signal == `MEM_NOP) begin
                finished <= 1;
            end
            else
            begin
                STATE_CTR     <= 4;
                first_address <= addr;
                case (mem_signal)
                    `WRITE: begin
                        memory_vis_signal <= 1;
                        data              <= mem_write_data;
                    end
                    `READ_DATA:begin
                        memory_vis_signal <= 0;
                    end
                    `READ_INST:begin
                        memory_vis_signal <= 0;
                    end
                    default:
                    $display("[ERROR]:unexpected mem_signal\n");
                endcase
            end
        end
        else begin // 访存工作中
            if (STATE_CTR == 4) begin
                
            end
            
            else
            if (STATE_CTR == 3) begin
                
            end
        end
    end
endmodule
