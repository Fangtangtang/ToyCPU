// toy ram
// self-made memory, register array to store value
// inst and data use the same port
// todo: enable different data size
`include "src/defines.v"

module mem#(parameter ADDR_WIDTH = 17,
            parameter LEN = 32,
            parameter BYTE_SIZE = 8)
           (input wire clk,
            input [ADDR_WIDTH-1:0] addr,
            input [LEN-1:0] mem_write,
            input [1:0] mem_stage_state,
            output[LEN-1:0] mem_read);
    
    reg [BYTE_SIZE-1:0] storage [0:2**ADDR_WIDTH-1];
    
    reg [ADDR_WIDTH-1:0] read_addr;
    
    assign mem_read = {storage[read_addr+3],storage[read_addr+2],storage[read_addr+1],storage[read_addr]};
    
    // 4byte数据拆解
    wire [BYTE_SIZE-1:0] byte0, byte1, byte2, byte3;
    
    // storage[addr + 3] = MemoryUnit(inf >> 24);
    // storage[addr + 2] = MemoryUnit(inf >> 16);
    // storage[addr + 1] = MemoryUnit(inf >> 8);
    // storage[addr]     = (MemoryUnit) inf;
    assign byte0         = mem_write[7:0];
    assign byte1         = mem_write[15:8];
    assign byte2         = mem_write[23:16];
    assign byte3         = mem_write[31:24];
    
    // 编译为二进制的测试点命名为test.data
    initial begin
        for (integer i = 0;i<2**ADDR_WIDTH;i = i+1) begin
            storage[i] = 0;
        end
        $readmemh("/mnt/f/repo/ToyCPU/user/testspace/test.data", storage);
    end
    
    always @(posedge clk) begin
        // read from memory
        if (mem_stage_state == `READ) begin
            read_addr <= addr;
        end
        // write to memory
        else
        if (mem_stage_state == `WRITE) begin
            storage[addr]   <= byte0;
            storage[addr+1] <= byte1;
            storage[addr+2] <= byte2;
            storage[addr+3] <= byte3;
        end
    end
    
endmodule
