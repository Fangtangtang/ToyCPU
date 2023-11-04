// Arithmetic and Logic Unit for multiple use
// combinational logic

// universal version
// mainly used in arithmetic and logic operation in execution stage

// `include"defines.v"
`include"src/defines.v"

module alu#(parameter LEN = 32)
           (input rst,
            input rdy_in,
            input [LEN - 1:0] rs1,
            input [LEN - 1:0] rs2,
            input [LEN - 1:0] imm,
            input [LEN - 1:0] pc,
            input [2:0] ex_stage_state,
            input [3:0] opcode,
            output reg [LEN - 1:0] result,
            output reg [1:0] sign_bits);
    
    always @(*) begin
        if ((!rst)&&rdy_in) begin
            case (ex_stage_state)
                `BRANCHCOND:            result = rs1 - rs2;
                `MEMADDR:               result = rs1 + imm;
                `IMMEXPR:begin
                    case (opcode)
                        `ADDI:          result = rs1 + imm;
                        // todo
                    endcase
                end
                `BINARYEXPR:begin
                    case (opcode)
                        `ADD:           result = rs1 + rs2;
                        // todo
                    endcase
                end
                `PCBASED:               result = pc + imm;
                `IMMONLY:               result = imm;
            endcase
            // todo: different cases for branch
            if (result>0) begin
                sign_bits = `POS;
            end
            else if (result == 0) begin
                sign_bits = `ZERO;
            end
            else begin
                sign_bits = `NEG;
            end
        end
    end
endmodule
    
    
    // simple version
    // for pc incrament
    // pc + 4
    module pc_adder #(
        parameter LEN = 32)
        (
        input   [LEN - 1:0]    pc,
        output  [LEN - 1:0]    npc
        );
        
        assign npc = pc + 3'b100;
        
    endmodule
        
        // simple version
        // for pc calculation
        // pc + offset(shift first)
        module pc_offset_adder#(
            parameter LEN = 32)(
            input   [LEN - 1:0]     pc,
            input   [LEN - 1:0]     imm,
            output  [LEN - 1:0]     offset_pc
            );
            
            wire    [LEN - 1:0]     shifted_imm;
            
            assign shifted_imm = {imm[LEN-2:0], 1'b0};
            assign offset_pc   = shifted_imm + pc;
            
        endmodule
            
            
            // simple version
            // pc address rounding
            // select special pc form pc_offset and rounded_pc
            // todo: jalr use rounded, special selector needed here
            module pc_addr_rounder#(
                parameter LEN = 32)(
                input    [LEN - 1:0]     offset_pc,
                input    [LEN - 1:0]     addr,
                // input    [1:0]           branch_flag,
                output   [LEN - 1:0]     special_pc
                );
                
                assign rounded_addr = addr &~ 1;
                
            endmodule
