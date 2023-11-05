// self-made top module
// only cpu core and memory included
`include"src/core.v"
`include"src/memory.v"

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
    
    // outports wire
    wire mem_stall;
    wire [LEN-1:0] mem_data;
    wire [MEM_ADDR_WIDTH-1:0] mem_addr;
    wire [LEN-1:0] write_data;
    wire [1:0] mem_stage_state;
    
    cpu #(.LEN(LEN))
    u_cpu(
    .clk         	    (clk),
    .rst         	    (rst),
    .rdy_in             (cpu_rdy),
    .mem_stall          (mem_stall),
    .mem_data         	(mem_data),
    .mem_addr        	(mem_addr),
    .write_data      	(write_data),
    .mem_vis_stage_state(mem_stage_state)
    );
    
    mem #(
    .ADDR_WIDTH(MEM_ADDR_WIDTH),
    .LEN(LEN),
    .BYTE_SIZE(8))
    u_mem(
    .clk         	    (clk),
    .addr               (mem_addr),
    .mem_write          (write_data),
    .mem_stage_state    (mem_stage_state),
    .mem_stall          (mem_stall),
    .mem_read           (mem_data)
    );
    
    
endmodule
