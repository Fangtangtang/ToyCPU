// register file
// 32 registers

module reg_file #(parameter LEN = 32)
                 (input wire clk,             // clock
                  input rdy_in,
                  input wire [4:0] rs1,       // index of rs1
                  input wire [4:0] rs2,       // index of rs2
                  input wire wb_flag,         // whether write back
                  input wire [4:0] rd,        // index of rd
                  input [LEN-1:0] data,       // write back data
                  output [LEN-1:0] rs1_data,
                  output [LEN-1:0] rs2_data);
    
    // 32 registers
    reg [4:0]               rs1_index;
    reg [4:0]               rs2_index;
    reg [LEN-1:0]           reg1;
    reg [LEN-1:0]           reg2;
    reg [LEN-1:0]           register[31:0];
    
    assign rs1_data = reg1;
    assign rs2_data = reg2;
    
    always @(posedge clk) begin
        if (rdy_in)begin
            // read from register
            // if (read_flag == 1) begin
            reg1 <= register[rs1_index];
            reg2 <= register[rs2_index];
            // end
            
            // write back
            if (wb_flag == 1) begin
                register[rs1_index] <= data;
            end
        end
    end
endmodule
