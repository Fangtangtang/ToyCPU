// #############################################################################################################################
// TOP
// #############################################################################################################################
`include"src_modified/cpu.v"
`include"src_modified/cache.v"
`include"src_modified/main_memory.v"

module top#(parameter LEN = 32)
           (input wire clk,
            input wire btnC);
    
    localparam MEM_ADDR_WIDTH = 17;
    
    reg rst;
    reg rst_delay;
    
    always @(posedge clk or posedge btnC)
    begin
        if (btnC)
        begin
            rst       <= 1'b1;
            rst_delay <= 1'b1;
        end
        else
        begin
            rst_delay <= 1'b0;
            rst       <= rst_delay;
        end
    end
    
    wire cpu_rdy = 1;
    
    wire [LEN-1:0] instruction;
    wire [LEN-1:0] mem_read_data;
    wire [1:0] mem_vis_status;
    wire [LEN-1:0] mem_write_data;
    wire [ADDR_WIDTH-1:0] mem_inst_addr;
    wire [ADDR_WIDTH-1:0] mem_data_addr;
    wire inst_fetch_signal;
    wire [1:0] memory_vis_signal;
    
    CPU cpu(
    .clk(clk),
    .rst(rst),
    .rdy_in(cpu_rdy),
    .instruction(instruction),
    .mem_read_data(mem_read_data),
    .mem_vis_status(mem_vis_status),
    .mem_write_data(mem_write_data),
    .mem_inst_addr(mem_inst_addr),
    .mem_data_addr(mem_data_addr),
    .inst_fetch_signal(inst_fetch_signal),
    .memory_vis_signal(memory_vis_signal)
    );
    
    wire [BYTE_SIZE-1:0] mem_data;
    wire [BYTE_SIZE-1:0] writen_data;
    wire [ADDR_WIDTH-1:0] mem_vis_addr;
    wire [1:0] mem_vis_signal;

    CACHE cache(
    .clk(clk),
    .mem_inst_addr(mem_inst_addr),
    .inst_fetch_signal(inst_fetch_signal),
    .instruction(instruction),
    .mem_data_addr(mem_data_addr),
    .mem_write_data(mem_write_data),
    .memory_vis_signal(memory_vis_signal),
    .mem_read_data(mem_read_data),
    .mem_vis_status(mem_vis_status),
    .mem_data(mem_data),
    .writen_data(writen_data),
    .mem_vis_addr(mem_vis_addr),
    .mem_vis_signal(mem_vis_signal)
    );

    MAIN_MEMORY main_memory(
        .clk(clk),
        .writen_data(writen_data),
        .mem_vis_addr(mem_vis_addr),
        .mem_vis_signal(mem_vis_signal),
        .mem_data(mem_data)
    );
    
endmodule
