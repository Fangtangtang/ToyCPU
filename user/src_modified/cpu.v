// #############################################################################################################################
// CPU
// 
// 分为五阶段执行，为简单版本一级流水
// transfer register等部分不借助module
// 仅必须的封装模块使用module
// 
// 接口说明：
// - 外部总控制信号：clk,rst,rdy_in
// - 与memory(cache)交互接口：instruction,mem_read_data,mem_vis_finished,mem_write_data,mem_addr,mem_vis_signal
// 
// module说明：
// - ALU：计算专用
// - Register File
// - Immediate Generator：纯粹为了封装
// 
// #############################################################################################################################

`include "src_modified/defines.v"

module CPU#(parameter LEN = 32,
            parameter ADDR_WIDTH = 17)
           (input clk,
            input rst,
            input rdy_in,
            input [LEN-1:0] instruction,
            input [LEN-1:0] mem_read_data,
            input mem_vis_finished,           // 访存状态
            output [LEN-1:0] mem_write_data,
            output [ADDR_WIDTH-1:0] mem_addr, // pc/adddr
            output [1:0] mem_vis_signal);
    
    // REGISTER
    // ---------------------------------------------------------------------------------------------
    // program counter
    reg [LEN-1:0]   PC;
    
    // transfer register
    // if-id
    reg [LEN-1:0]   IF_ID_PC;
    // id-exe
    reg [LEN-1:0]   ID_EXE_PC;
    reg [LEN-1:0]   ID_EXE_RS1;              // 从register file读取到的rs1数据
    reg [LEN-1:0]   ID_EXE_RS2;              // 从register file读取到的rs2数据
    reg [LEN-1:0]   ID_EXE_IMM;              // immediate generator提取的imm
    reg [4:0]       ID_EXE_RD_INDEX;         // 记录的rd位置
    reg [3:0]       ID_EXE_FUNC_CODE;        // func部分
    reg [2:0]       ID_EXE_ALU_SIGNAL;       // ALU信号
    reg [1:0]       ID_EXE_MEM_VIS_SIGNAL;   // 访存信号
    reg             ID_EXE_BRANCH_SIGNAL;
    reg [1:0]       ID_EXE_WB_SIGNAL;
    // exe_mem
    reg [LEN-1:0]   EXE_MEM_PC;
    reg [LEN-1:0]   EXE_MEM_RESULT;       // 计算结果
    reg [LEN-1:0]   EXE_MEM_RS2;          // 可能用于写的数据
    reg [4:0]       EXE_MEM_RD_INDEX;     // 记录的rd位置
    reg [1:0]       EXE_MEM_ZERO_BITS;    // condition
    reg [1:0]       EXE_MEM_MEM_VIS_SIGNAL;
    reg             EXE_MEM_BRANCH_SIGNAL;
    reg [1:0]       EXE_MEM_WB_SIGNAL;
    // mem_wb
    reg [LEN-1:0]   MEM_WB_PC;
    reg [LEN-1:0]   MEM_WB_MEM_DATA;  // 从内存读取的数据
    reg [LEN-1:0]   MEM_WB_RESULT;    // 计算结果
    reg [4:0]       MEM_WB_RD_INDEX;
    reg [1:0]       MEM_WB_WB_SIGNAL;
    
    // DECODER
    // ---------------------------------------------------------------------------------------------
    wire [4:0]      rs1_index;
    wire [4:0]      rs2_insdex;
    wire[4:0]       rd_index;
    assign rs1_index  = instruction[19:15];
    assign rs2_insdex = instruction[24:20];
    assign rd_index   = instruction[11:7];
    
    wire [6:0]      opcode;
    assign opcode = instruction[6:0];
    
    wire [3:0]      func_code;
    assign func_code = {instruction[30],instruction[14:12]};
    
    wire            R_type; // binary and part of imm binary
    wire            I_type; // jalr,load and part of imm binary
    wire            S_type; // store
    wire            B_type; // branch
    wire            U_type; // big int
    wire            J_type; // jump
    
    wire special_func_code = func_code == 4'b0001||func_code == 4'b0101||func_code == 4'b1101;
    assign R_type          = (opcode == 7'b0110011)||(opcode == 7'b0010011&&special_func_code);
    assign I_type          = (opcode == 7'b0110011&&(!special_func_code))||(opcode == 7'b0000011)||(opcode == 7'b1100111&&func_code[2:0] == 3'b000);
    assign S_type          = opcode == 7'b0100011;
    assign B_type          = opcode == 7'b1100011;
    assign U_type          = opcode == 7'b0110111||opcode == 7'b0010111;
    assign J_type          = opcode == 7'b1101111&&(!func_code[2:0] == 3'b000);
    
    reg [2:0]       alu_signal;
    reg [1:0]       mem_vis_signal;
    reg             branch_signal;
    reg [1:0]       wb_signal;
    
    // 组合逻辑解码获取信号
    always @(*) begin
        if (R_type) begin
            case (opcode)
                7'b0110011: begin
                    alu_signal     = `BINARY;
                    mem_vis_signal = `MEM_NOP;
                    branch_signal  = 0;
                    wb_signal      = `ARITH;
                end
                7'b0010011: begin
                    alu_signal     = `IMM_BINARY;
                    mem_vis_signal = `MEM_NOP;
                    branch_signal  = 0;
                    wb_signal      = `ARITH;
                end
                default:
                $display("[ERROR]:unexpected R type instruction\n");
            endcase
        end
        else if (I_type) begin
            case (opcode)
                7'b0010011: begin
                    alu_signal     = `IMM_BINARY;
                    mem_vis_signal = `MEM_NOP;
                    branch_signal  = 0;
                    wb_signal      = `ARITH;
                end
                7'b0000011:begin
                    alu_signal     = `MEM_ADDR;
                    mem_vis_signal = `READ_DATA;
                    branch_signal  = 0;
                    wb_signal      = `MEM_TO_REG;
                end
                7'b1100111:begin
                    alu_signal     = `MEM_ADDR;
                    mem_vis_signal = `MEM_NOP;
                    branch_signal  = 1;
                    wb_signal      = `INCREASED_PC;
                end
                default:
                $display("[ERROR]:unexpected I type instruction\n");
            endcase
        end
        else
        
        if (S_type) begin
            alu_signal     = `MEM_ADDR;
            mem_vis_signal = `WRITE;
            branch_signal  = 0;
            wb_signal      = `WB_NOP;
        end
        else
        
        if (B_type) begin
            alu_signal     = `BRANCH_COND;
            mem_vis_signal = `MEM_NOP;
            branch_signal  = 1;
            wb_signal      = `WB_NOP;
        end
        else
        
        if (U_type) begin
            case (opcode)
                7'b0110111:begin
                    alu_signal     = `IMM;
                    mem_vis_signal = `MEM_NOP;
                    branch_signal  = 0;
                    wb_signal      = `ARITH;
                end
                7'b0010111:begin
                    alu_signal     = `PC_BASED;
                    mem_vis_signal = `MEM_NOP;
                    branch_signal  = 0;
                    wb_signal      = `ARITH;
                end
                default:
                $display("[ERROR]:unexpected U type instruction\n");
            endcase
        end
        else
        
        if (J_type) begin
            alu_signal     = `ALU_NOP;
            mem_vis_signal = `MEM_NOP;
            branch_signal  = 1;
            wb_signal      = `WB_NOP;
        end
    end
    
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // PIPELINE
    // STAGE1 : INSTRUCTION FETCH
    // ---------------------------------------------------------------------------------------------
    
    
    reg IF_STATE_CTR;
    
    // STAGE2 : INSTRUCTION DECODE
    // - 考虑的指令中func7中仅有[30]起标示作用，func用4位
    // ---------------------------------------------------------------------------------------------
    
    
    reg ID_STATE_CTR;
    
    
    
    // STAGE3 : EXECUTE
    // ---------------------------------------------------------------------------------------------
    
    reg EXE_STATE_CTR;
    
    
    
    
    // STAGE4 : MEMORY VISIT
    // ---------------------------------------------------------------------------------------------
    
    reg MEM_STATE_CTR;
    
    // STAGE5 : WRITE BACK
    // ---------------------------------------------------------------------------------------------
    
    reg WB_STATE_CTR;
    
    
    
endmodule
