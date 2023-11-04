// Multiplexer
// take several input and a control signal
// select one as output

`include"src/defines.v"

// rd_data_mux mux
// select one from three input
// - npc
// - mem_data
// - result
// output rd_data and control signal
module rd_data_mux#(parameter LEN = 32)
                   (input rst,
                    input rdy_in,
                    input [LEN-1:0] npc,
                    input [LEN-1:0]mem_data,
                    input [LEN-1:0]result,
                    input [1:0] wb_stage_state,
                    output [LEN-1:0] rd_data,
                    output wb_flag);
    reg [LEN-1:0] data;
    reg flag;
    
    assign rd_data = data;
    assign wb_flag = flag;
    
    always @(*) begin
        if ((!rst)&&rdy_in) begin
            case (wb_stage_state)
                `NONE:flag = 0;
                `NPC:begin
                    data = npc;
                    flag = 1;
                end
                `MEM2REG:begin
                    data = mem_data;
                    flag = 1;
                end
                `ARI:begin
                    data = result;
                    flag = 1;
                end
            endcase
        end
    end
endmodule
    
    // mem_addr_mux
    // select mem inst read or mem data r/w
    // select the expected addr
    // use last 17 bits as output
    module mem_addr_mux#(parameter LEN = 32,
        parameter ADDR_WIDTH = 17)
        (
        input rst,
        input rdy_in,
        input pc_flag,
        input [LEN-1:0] inst_addr,
        input  [LEN-1:0] data_addr,
        // output reg inst_fetch_flag,
        output [ADDR_WIDTH-1:0] mem_addr);
        
        reg [ADDR_WIDTH-1:0] addr;
        assign mem_addr = addr;
        always @(*) begin
            if ((!rst)&&rdy_in) begin
                if (pc_flag) begin
                    addr = inst_addr[ADDR_WIDTH-1:0];
                end
                else begin
                    addr = data_addr[ADDR_WIDTH-1:0];
                end
            end
        end
    endmodule
        
        // mem_data_mux
        // select data from mem
        // inst or mem_read
        module mem_data_mux#(parameter LEN = 32) (
            input clk,
            input rst,
            input rdy_in,
            input pc_flag,
            input [LEN-1:0] data,
            output [LEN-1:0] inst,
            output [LEN-1:0] mem_read
            );
            
            reg inst_flag;
            reg [LEN-1:0] instruction;
            reg [LEN-1:0] read_data;
            
            assign inst     = instruction;
            assign mem_read = read_data;
            
            always @(posedge clk) begin
                if ((!rst)&&rdy_in) begin
                    inst_flag <= pc_flag;
                    if (inst_flag) begin
                        instruction = data;
                    end
                    else begin
                        read_data = data;
                    end
                end
            end
        endmodule
