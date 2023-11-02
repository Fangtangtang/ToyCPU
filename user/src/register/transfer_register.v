// transfer registers
// maintain information between different stages


// Instrction fetch \ Instruction decode
module if_id_transfer_reg #(parameter LEN = 32)
                           (input wire clk,           // input pc_update_signal, output o_pc_update_signal, 
                            input rdy_in,
                            input [LEN-1:0] c_pc,
                            output [LEN-1:0] o_c_pc,
                            input [LEN-1:0] n_pc,
                            output [LEN-1:0] o_n_pc);
    // reg pc_update;
    reg [LEN-1:0] cur_pc;
    reg [LEN-1:0] new_pc;
    
    // assign o_pc_update_signal = pc_update ;
    assign o_c_pc                = cur_pc;
    assign o_n_pc                = new_pc;
    always @(posedge clk)begin
        if (rdy_in) begin
            // pc_update <= pc_update_signal;
            cur_pc       <= c_pc;
            new_pc       <= n_pc;
        end
    end
    
endmodule
    
    
    // Instruction decode \ Execute
    module id_ex_transfer_reg #(parameter LEN = 32)(
        // clock
        input   wire clk,
        input rdy_in,
        // PC
        // signal
        // input wire pc_update_signal,
        // output o_pc_update_signal,
        // current pc
        input   [LEN-1:0]   c_pc,
        output  [LEN-1:0]   o_c_pc,
        // new pc
        input   [LEN-1:0]   n_pc,
        output  [LEN-1:0]   o_n_pc,
        
        // CONTROL
        // ex
        input   [2:0]       ex_stage_state,
        output  [2:0]       o_ex_stage_state,
        // mem
        input   [1:0]       branch_flag,
        output  [1:0]       o_branch_flag,
        input   [1:0]       mem_stage_state,
        output  [1:0]       o_mem_stage_state,
        // wb
        input   [1:0]       wb_stage_state,
        output  [1:0]       o_wb_stage_state,
        
        // OPERAND
        input   [LEN-1:0]   imm,
        output  [LEN-1:0]   o_imm,
        input   [LEN-1:0]   rs1,
        output  [LEN-1:0]   o_rs1,
        input   [LEN-1:0]   rs2,
        output  [LEN-1:0]   o_rs2,
        
        // OPCODE
        input   [3:0]       opcode,
        output  [3:0]       o_opcode,
        
        // RD
        input   [4:0]       rd,
        output  [4:0]       o_rd
        );
        
        // PC
        // reg pc_update;
        reg [LEN-1:0] cur_pc;
        reg [LEN-1:0] new_pc;
        
        // assign o_pc_update_signal = pc_update ;
        assign o_c_pc                = cur_pc;
        assign o_n_pc                = new_pc;
        always @(posedge clk)begin
            if (rdy_in) begin
                // pc_update <= pc_update_signal;
                cur_pc       <= c_pc;
                new_pc       <= n_pc;
            end
        end
        
        // CONTROL
        // ex
        reg [2:0] cur_ex_stage_state;
        
        assign o_ex_stage_state = cur_ex_stage_state;
        always @(posedge clk)begin
            if (rdy_in) begin
                cur_ex_stage_state <= ex_stage_state;
            end
        end
        // mem
        reg [1:0] cur_branch_flag;
        reg [1:0] cur_mem_stage_state;
        
        assign o_branch_flag     = cur_branch_flag;
        assign o_mem_stage_state = cur_mem_stage_state;
        always @(posedge clk)begin
            if (rdy_in) begin
                cur_branch_flag = branch_flag;
                cur_mem_stage_state <= mem_stage_state;
            end
        end
        // wb
        reg [1:0] cur_wb_stage_state;
        
        assign o_wb_stage_state = cur_wb_stage_state;
        always @(posedge clk)begin
            if (rdy_in) begin
                cur_wb_stage_state <= wb_stage_state;
            end
        end
        
        // OPERAND
        reg [LEN-1:0] cur_imm;
        reg [LEN-1:0] cur_rs1;
        reg [LEN-1:0] cur_rs2;
        
        assign o_imm = cur_imm;
        assign o_rs1 = cur_rs1;
        assign o_rs2 = cur_rs2;
        always @(posedge clk)begin
            if (rdy_in) begin
                cur_imm <= imm;
                cur_rs1 <= rs1;
                cur_rs2 <= rs2;
            end
        end
        
        // OPCODE
        reg [3:0] cur_opcode;
        
        assign o_opcode = cur_opcode;
        always @(posedge clk) begin
            if (rdy_in) begin
                cur_opcode <= opcode;
            end
        end
        
        // RD
        reg [LEN-1:0] cur_rd;
        
        assign o_rd = cur_rd;
        always @(posedge clk) begin
            if (rdy_in) begin
                cur_rd <= rd;
            end
        end
    endmodule
        
        
        // Execute \ Memory visit
        module ex_mem_transfer_reg #(parameter LEN = 32)(
            // clock
            input   wire clk,
            input rdy_in,
            // PC
            // signal
            // input wire pc_update_signal,
            // output o_pc_update_signal,
            // current pc
            input   [LEN-1:0]   c_pc,
            output  [LEN-1:0]   o_c_pc,
            // new pc
            input   [LEN-1:0]   n_pc,
            output  [LEN-1:0]   o_n_pc,
            input   [LEN-1:0]   offset_pc,
            output  [LEN-1:0]   o_offset_pc,
            
            // CONTROL
            // mem
            input   [1:0]       branch_flag,
            output  [1:0]       o_branch_flag,
            input   [1:0]       mem_stage_state,
            output  [1:0]       o_mem_stage_state,
            // wb
            input   [1:0]       wb_stage_state,
            output  [1:0]       o_wb_stage_state,
            
            // ARITHMATIC
            input   [1:0]   sign_bits,
            output  [1:0]   o_sign_bits,
            input   [LEN-1:0]   result,
            output  [LEN-1:0]   o_result,
            input   [LEN-1:0]   rs2,
            output  [LEN-1:0]   o_rs2,
            
            // RD
            input   [4:0]       rd,
            output  [4:0]       o_rd
            );
            
            // PC
            // reg pc_update;
            reg [LEN-1:0] cur_pc;
            reg [LEN-1:0] new_pc;
            reg [LEN-1:0] cur_offset_pc;
            
            // assign o_pc_update_signal = pc_update ;
            assign o_c_pc                = cur_pc ;
            assign o_n_pc                = new_pc;
            assign o_offset_pc           = cur_offset_pc;
            
            always @(posedge clk)begin
                if (rdy_in) begin
                    // pc_update  <= pc_update_signal;
                    cur_pc        <= c_pc;
                    new_pc        <= n_pc;
                    cur_offset_pc <= offset_pc;
                end
            end
            
            // CONTROL
            // mem
            reg [1:0] cur_branch_flag;
            reg [1:0] cur_mem_stage_state;
            
            assign o_branch_flag     = cur_branch_flag;
            assign o_mem_stage_state = cur_mem_stage_state;
            always @(posedge clk)begin
                if (rdy_in) begin
                    cur_branch_flag = branch_flag;
                    cur_mem_stage_state <= mem_stage_state;
                end
            end
            // wb
            reg [1:0] cur_wb_stage_state;
            
            assign o_wb_stage_state = cur_wb_stage_state;
            always @(posedge clk)begin
                if (rdy_in) begin
                    cur_wb_stage_state <= wb_stage_state;
                end
            end
            
            // ARITHMATIC
            reg [1:0] cur_sign_bits;
            reg [LEN-1:0] cur_result;
            reg [LEN-1:0] cur_rs2;
            
            assign o_sign_bits = cur_sign_bits;
            assign o_result    = cur_result;
            assign o_rs2       = cur_rs2;
            always @(posedge clk)begin
                if (rdy_in) begin
                    cur_sign_bits <= sign_bits;
                    cur_result    <= result;;
                    cur_rs2       <= rs2;
                end
            end
            
            // RD
            reg [LEN-1:0] cur_rd;
            
            assign o_rd = cur_rd;
            always @(posedge clk) begin
                if (rdy_in) begin
                    cur_rd <= rd;
                end
            end
        endmodule
            
            // Memory visit \ Write back
            module mem_wb_transfer_reg #(parameter LEN = 32)(
                // clock
                input   wire clk,
                input rdy_in,
                // PC
                // signal
                // input wire pc_update_signal,
                // output o_pc_update_signal,
                // current pc
                input   [LEN-1:0]   c_pc,
                output  [LEN-1:0]   o_c_pc,
                // new pc
                input   [LEN-1:0]   n_pc,
                output  [LEN-1:0]   o_n_pc,
                
                // CONTROL
                // wb
                input   [1:0]       wb_stage_state,
                output  [1:0]       o_wb_stage_state,
                
                // DATA
                input   [LEN-1:0]   result,
                output  [LEN-1:0]   o_result,
                input   [LEN-1:0]   mem_data,
                output  [LEN-1:0]   o_mem_data,
                
                // RD
                input   [4:0]       rd,
                output  [4:0]       o_rd
                );
                
                // PC
                // reg pc_update;
                reg [LEN-1:0] cur_pc;
                reg [LEN-1:0] new_pc;
                
                // assign o_pc_update_signal = pc_update ;
                assign o_c_pc                = cur_pc;
                assign o_n_pc                = new_pc;
                always @(posedge clk)begin
                    if (rdy_in) begin
                        // pc_update <= pc_update_signal;
                        cur_pc       <= c_pc;
                        new_pc       <= n_pc;
                    end
                end
                
                // CONTROL
                // wb
                reg [1:0] cur_wb_stage_state;
                
                assign o_wb_stage_state = cur_wb_stage_state;
                always @(posedge clk)begin
                    if (rdy_in) begin
                        cur_wb_stage_state <= wb_stage_state;
                    end
                end
                
                // DATA
                reg [LEN-1:0] cur_result;
                reg [LEN-1:0] cur_mem_data;
                
                assign o_result   = cur_result;
                assign o_mem_data = cur_mem_data;
                always @(posedge clk)begin
                    if (rdy_in) begin
                        cur_result   <= result;
                        cur_mem_data <= mem_data;
                    end
                end
                
                // RD
                reg [LEN-1:0] cur_rd;
                
                assign o_rd = cur_rd;
                always @(posedge clk) begin
                    if (rdy_in) begin
                        cur_rd <= rd;
                    end
                end
            endmodule
