// decoder
// take one input and transfer to multiple outputs

`include"src/defines.v"


// decoder
// take instruction as input
// 1.decode ex\m\wb control signals
// - EX:    stage state, opcode
// - MEM:   stage state, special_pc_flag, branch flag
// - WB:    stage state,
// 2.generate immediate number
module decoder#(parameter LEN = 32)
               (input rdy_in,
                input wire [LEN-1:0] instruction,
                output wire [2:0] ex_stage_state,
                output wire [3:0] opcode,
                output wire [1:0] mem_stage_state,
                output wire special_pc_flag,
                output wire [1:0] branch_flag,
                output wire [1:0] wb_stage_state,
                output wire [LEN-1:0] immediate);
    
    wire [6:0] typecode;
    wire sign_bit;
    
    reg [2:0] ex;
    reg [1:0] mem;
    reg spc_flag;
    reg [1:0] br;
    reg [1:0] wb;
    reg [LEN-1:0] imm;
    
    
    assign typecode = instruction[6:0];
    assign sign_bit = instruction[31];
    
    assign opcode          = {instruction[30],instruction[14:12]};
    assign ex_stage_state  = ex;
    assign mem_stage_state = mem;
    assign special_pc_flag = spc_flag;
    assign branch_flag     = br;
    assign wb_stage_state  = wb;
    assign immediate       = imm;
    
    always @(*) begin
        if (rdy_in) begin
            case (typecode)
                `LUI:    begin
                    ex       = 3'b110;          // IMMONLY
                    mem      = 2'b00;           // NONE
                    spc_flag = 1'b0;            // FALSE
                    br       = 2'b00;           // NOTBRANCH
                    wb       = 2'b11;           // ARI
                    imm      = { instruction[31:12],{12{1'b0}}};
                end
                `AUIPC:     begin
                    ex       = 3'b101;          // PCBASED
                    mem      = 2'b00;           // NONE
                    spc_flag = 1'b0;            // FALSE
                    br       = 2'b00;           // NOTBRANCH
                    wb       = 2'b11;           // ARI
                    imm      = {instruction[31:12],{12{1'b0}}};
                end
                `JAL:      begin
                    ex       = 3'b000;          // NONEEXE
                    mem      = 2'b00;           // NONE
                    spc_flag = 1'b1;            // TRUE
                    br       = 2'b10;           // UNCONDBRANCH
                    wb       = 2'b00;           // NONE
                    imm      = {{13{sign_bit}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21]};
                end
                `JALR:    begin
                    ex       = 3'b011;          // IMMEXPR
                    mem      = 2'b00;           // NONE
                    spc_flag = 1'b1;            // TRUE
                    br       = 2'b10;           // UNCONDBRANCH
                    wb       = 2'b00;           // NONE
                    imm      = {{20{sign_bit}}, instruction[31:20]};
                end
                `BRANCH:    begin
                    ex       = 3'b001;          // BRANCHCOND
                    mem      = 2'b00;           // NONE
                    spc_flag = 1'b1;            // TRUE
                    br       = 2'b01;           // CONDBRANCH
                    wb       = 2'b00;           // NONE
                    imm      = {{20{sign_bit}}, sign_bit, instruction[7], instruction[30:25], instruction[11:8]};
                end
                `LOAD:  begin
                    ex       = 3'b010;          // MEMADDR
                    mem      = 2'b01;           // READ
                    spc_flag = 1'b0;            // FALSE
                    br       = 2'b00;           // NOTBRANCH
                    wb       = 2'b10;           // MEM2REG
                    imm      = {{20{sign_bit}}, instruction[31:20]};
                end
                `STORE: begin
                    ex       = 3'b010;          // MEMADDR
                    mem      = 2'b10;           // WRITE
                    spc_flag = 1'b0;            // FALSE
                    br       = 2'b00;           // NOTBRANCH
                    wb       = 2'b00;           // NONE
                    imm      = {{20{sign_bit}}, instruction[31:25], instruction[11:7]};
                end
                `IMM: begin
                    ex       = 3'b011;          // IMMEXPR
                    mem      = 2'b00;           // NONE
                    spc_flag = 1'b0;            // FALSE
                    br       = 2'b00;           // NOTBRANCH
                    wb       = 2'b11;           // ARI
                    imm      = {{20{sign_bit}}, instruction[31:20]};
                end
                `BINARY:begin
                    ex       = 3'b100;          // BINARYEXPR
                    mem      = 2'b00;           // NONE
                    spc_flag = 1'b0;            // FALSE
                    br       = 2'b00;           // NOTBRANCH
                    wb       = 2'b11;           // ARI
                end
            endcase
        end
    end
endmodule
    
    
