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
// 简易版(memory controler)，cashe size4
// 状态机取数据
// #############################################################################################################################
`include "src_modified/defines.v"

module CACHE#(parameter ADDR_WIDTH = 17,
              parameter LEN = 32,
              parameter BYTE_SIZE = 8)
             (input wire clk,
              input [ADDR_WIDTH-1:0] mem_inst_addr,   // instruction fetch
              input inst_fetch_signal,
              output reg [LEN-1:0] instruction,
              input [ADDR_WIDTH-1:0] mem_data_addr,   // memory visit
              input [LEN-1:0] mem_write_data,
              input [1:0] memory_vis_signal,
              output reg [LEN-1:0] mem_read_data,
              output reg [1:0] mem_vis_status,
              input [BYTE_SIZE-1:0] mem_data,         // interact with main memory
              output reg [BYTE_SIZE-1:0] writen_data, // 写入memory的数据
              output [ADDR_WIDTH-1:0] mem_vis_addr,   // 访存地址
              output [1:0] mem_vis_signal);
    
    // todo:merge storage and data?
    
    reg [BYTE_SIZE-1:0] storage [0:3];
    reg [2:0] MEM_VIS_CNT = 0;
    
    reg [LEN-1:0] data;
    wire [BYTE_SIZE-1:0] byte0, byte1, byte2, byte3;
    assign byte0 = data[7:0];
    assign byte1 = data[15:8];
    assign byte2 = data[23:16];
    assign byte3 = data[31:24];
    
    // reg [ADDR_WIDTH-1:0] init_addr;
    reg [ADDR_WIDTH-1:0] addr;
    assign mem_vis_addr = addr;
    
    reg [1:0] mem_vis_type = 0;
    assign mem_vis_signal  = mem_vis_type;
    
    always @(posedge clk) begin
        case (MEM_VIS_CNT)
            // 刚开始访存
            5:begin
                MEM_VIS_CNT = MEM_VIS_CNT - 1;
                mem_vis_status <= `WORKING;
                // write
                if (mem_vis_type == `WRITE) begin
                    writen_data = byte0;
                    addr <= addr+1;
                end
                // read
                else begin
                    addr <= addr+1;
                    // mem_vis_addr   = addr;
                    // mem_vis_signal = `READ_DATA;
                    // storage[0]     = mem_data;
                    // $monitor("%b",mem_data);

                end
            end
            4:begin
                MEM_VIS_CNT = MEM_VIS_CNT - 1;
                mem_vis_status <= `WORKING;
                // write
                if (mem_vis_type == `WRITE) begin
                    writen_data = byte1;
                    addr <= addr+1;
                    // mem_vis_addr   = addr + 1;
                    // mem_vis_signal = `WRITE;
                end
                // read
                else begin
                    addr <= addr+1;
                    // mem_vis_addr   = addr + 1;
                    // mem_vis_signal = `READ_DATA;
                    // storage[1]     = mem_data;
                    storage[0] = mem_data;

                end
            end
            3:begin
                MEM_VIS_CNT = MEM_VIS_CNT - 1;
                mem_vis_status <= `WORKING;
                // write
                if (mem_vis_type == `WRITE) begin
                    writen_data = byte2;
                    addr <= addr+1;
                    // mem_vis_addr   = addr + 2;
                    // mem_vis_signal = `WRITE;
                
                end
                // read
                else begin
                    addr <= addr+1;
                    // mem_vis_addr   = addr + 2;
                    // mem_vis_signal = `READ_DATA;
                    // storage[2]     = mem_data;
                    storage[1] = mem_data;
                    // $display("%b",mem_data);
                    
                end
            end
            2:begin
                MEM_VIS_CNT = MEM_VIS_CNT - 1;
                // write
                if (mem_vis_type == `WRITE) begin
                    mem_vis_status <= `R_W_FINISHED;
                    writen_data       = byte3;
                    // mem_vis_addr   = addr + 3;
                    // mem_vis_signal = `WRITE;
                end
                // read
                else begin
                    storage[2] = mem_data;
                end
            end
            1:begin
                MEM_VIS_CNT = MEM_VIS_CNT - 1;
                if (mem_vis_type == `WRITE) begin
                    mem_vis_status <= `R_W_FINISHED;
                    writen_data       = byte3;
                end
                else if (mem_vis_type == `READ_DATA)begin
                    mem_vis_status <= `R_W_FINISHED;
                    storage[3] = mem_data;
                    
                    mem_read_data = {storage[3],storage[2],storage[1],storage[0]};
                end
                else if (mem_vis_type == `READ_INST) begin
                    mem_vis_status <= `IF_FINISHED;
                    storage[3] = mem_data;
                    
                    instruction = {storage[3],storage[2],storage[1],storage[0]};
                end
            end
            0:begin
                if (mem_vis_type == `MEM_NOP) begin
                    if (inst_fetch_signal) begin
                        mem_vis_type = `READ_INST;
                        addr         = mem_inst_addr;
                        MEM_VIS_CNT  = 5;
                        mem_vis_status <= `WORKING;
                    end
                    else begin
                        case (memory_vis_signal)
                            `READ_DATA:begin
                                mem_vis_type <= `READ_DATA;
                                addr        = mem_data_addr;
                                MEM_VIS_CNT = 5;
                                mem_vis_status <= `WORKING;
                            end
                            `READ_INST:begin
                                mem_vis_type <= `READ_INST;
                                addr        = mem_inst_addr;
                                MEM_VIS_CNT = 5;
                                mem_vis_status <= `WORKING;
                            end
                            `WRITE:begin
                                mem_vis_type <= `WRITE;
                                addr        = mem_data_addr;
                                data        = mem_write_data;
                                MEM_VIS_CNT = 5;
                                mem_vis_status <= `WORKING;
                            end
                        endcase
                    end
                end
                else begin
                    mem_vis_type = `MEM_NOP;
                    mem_vis_status <= `RESTING;
                end
            end
            default:
            $display("[ERROR]:unexpected counter\n");
        endcase
    end
    
    
endmodule
