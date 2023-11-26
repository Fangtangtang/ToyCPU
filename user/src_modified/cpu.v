// #############################################################################################################################
// CPU
// 
// 分为五阶段执行，为简单版本一级流水
// transfer register等部分不借助module
// 仅必须的封装模块使用module
// 
// 接口说明：
// - 外部总控制信号：clk,rst,rdy_in
// - 与memory(cache)交互接口：instruction,mem_read_data,mem_vis_status,mem_write_data,mem_addr,mem_vis_signal
// 
// module说明：
// - ALU：计算专用
// - Register File
// - Immediate Generator：纯粹为了封装
// 
// #############################################################################################################################

`include "src_modified/defines.v"
`include "src_modified/imm_gen.v"
`include "src_modified/alu.v"
`include "src_modified/reg_file.v"

module CPU#(parameter LEN = 32,
            parameter ADDR_WIDTH = 17)
           (input clk,
            input rst,
            input rdy_in,
            input [LEN-1:0] instruction,
            input [LEN-1:0] mem_read_data,
            input [1:0] mem_vis_status,            // 访存状态
            output [LEN-1:0] mem_write_data,
            output [ADDR_WIDTH-1:0] mem_inst_addr, // pc
            output [ADDR_WIDTH-1:0] mem_data_addr, // addr
            output inst_fetch_enabled,
            output mem_vis_enabled,
            output [1:0] memory_vis_signal,
            output [1:0] memory_vis_data_size);
    
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
    reg [1:0]       ID_EXE_MEM_VIS_DATA_SIZE;
    reg [1:0]       ID_EXE_BRANCH_SIGNAL;
    reg [1:0]       ID_EXE_WB_SIGNAL;
    // exe_mem
    reg [LEN-1:0]   EXE_MEM_PC;
    reg [LEN-1:0]   EXE_MEM_RESULT;       // 计算结果
    reg [LEN-1:0]   EXE_MEM_RS2;          // 可能用于写的数据
    reg [LEN-1:0]   EXE_MEM_IMM;
    reg [4:0]       EXE_MEM_RD_INDEX;     // 记录的rd位置
    reg [3:0]       EXE_MEM_FUNC_CODE;
    reg [1:0]       EXE_MEM_ZERO_BITS;    // condition
    reg [1:0]       EXE_MEM_MEM_VIS_SIGNAL;
    reg [1:0]       EXE_MEM_MEM_VIS_DATA_SIZE;
    reg [1:0]       EXE_MEM_BRANCH_SIGNAL;
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
    wire [4:0]       rd_index;
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
    assign I_type          = (opcode == 7'b0010011&&(!special_func_code))||(opcode == 7'b0000011)||(opcode == 7'b1100111&&func_code[2:0] == 3'b000);
    assign S_type          = opcode == 7'b0100011;
    assign B_type          = opcode == 7'b1100011;
    assign U_type          = opcode == 7'b0110111||opcode == 7'b0010111;
    assign J_type          = opcode == 7'b1101111&&(func_code[2:0] == 3'b000);
    
    reg [2:0]       alu_signal;
    reg [1:0]       mem_vis_signal;
    reg [1:0]       data_size;
    reg [1:0]       branch_signal;
    reg [1:0]       wb_signal;
    
    // 组合逻辑解码获取信号
    always @(*) begin
        if (R_type) begin
            case (opcode)
                7'b0110011: begin
                    alu_signal     = `BINARY;
                    mem_vis_signal = `MEM_NOP;
                    data_size      = `NOT_ACCESS;
                    branch_signal  = `NOT_BRANCH;
                    wb_signal      = `ARITH;
                end
                7'b0010011: begin
                    alu_signal     = `IMM_BINARY;
                    mem_vis_signal = `MEM_NOP;
                    data_size      = `NOT_ACCESS;
                    branch_signal  = `NOT_BRANCH;
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
                    data_size      = `NOT_ACCESS;
                    branch_signal  = `NOT_BRANCH;
                    wb_signal      = `ARITH;
                end
                // load
                7'b0000011:begin
                    alu_signal     = `MEM_ADDR;
                    mem_vis_signal = `READ_DATA;
                    branch_signal  = `NOT_BRANCH;
                    wb_signal      = `MEM_TO_REG;
                    case (func_code[2:0])
                        3'b000:data_size = `BYTE;
                        3'b001:data_size = `HALF;
                        3'b010:data_size = `WORD;
                        default:
                        $display("[ERROR]:unexpected load instruction\n");
                    endcase
                end
                // jalr
                7'b1100111:begin
                    alu_signal     = `MEM_ADDR;
                    mem_vis_signal = `MEM_NOP;
                    data_size      = `NOT_ACCESS;
                    branch_signal  = `UNCONDITIONAL_RESULT;
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
            branch_signal  = `NOT_BRANCH;
            wb_signal      = `WB_NOP;
            case (func_code[2:0])
                3'b000:data_size = `BYTE;
                3'b001:data_size = `HALF;
                3'b010:data_size = `WORD;
                default:
                $display("[ERROR]:unexpected load instruction\n");
            endcase
        end
        else
        
        if (B_type) begin
            alu_signal     = `BRANCH_COND;
            mem_vis_signal = `MEM_NOP;
            data_size      = `NOT_ACCESS;
            branch_signal  = `CONDITIONAL;
            wb_signal      = `WB_NOP;
        end
        else
        
        if (U_type) begin
            case (opcode)
                7'b0110111:begin
                    alu_signal     = `IMM;
                    mem_vis_signal = `MEM_NOP;
                    data_size      = `NOT_ACCESS;
                    branch_signal  = `NOT_BRANCH;
                    wb_signal      = `ARITH;
                end
                7'b0010111:begin
                    alu_signal     = `PC_BASED;
                    mem_vis_signal = `MEM_NOP;
                    data_size      = `NOT_ACCESS;
                    branch_signal  = `NOT_BRANCH;
                    wb_signal      = `ARITH;
                end
                default:
                $display("[ERROR]:unexpected U type instruction\n");
            endcase
        end
        else
        
        if (J_type) begin
            alu_signal     = `PC_BASED;
            mem_vis_signal = `MEM_NOP;
            data_size      = `NOT_ACCESS;
            branch_signal  = `UNCONDITIONAL;
            wb_signal      = `INCREASED_PC;
        end
    end
    
    // MEM VISIT
    // ---------------------------------------------------------------------------------------------
    // todo:当memory被占用时,如何stall
    
    assign mem_inst_addr      = PC[ADDR_WIDTH-1:0];
    assign inst_fetch_enabled = IF_STATE_CTR;
    assign mem_vis_enabled    = MEM_STATE_CTR;
    
    assign mem_data_addr        = EXE_MEM_RESULT[ADDR_WIDTH-1:0];
    assign memory_vis_signal    = MEM_STATE_CTR ? EXE_MEM_MEM_VIS_SIGNAL:`MEM_NOP;
    assign memory_vis_data_size = EXE_MEM_MEM_VIS_DATA_SIZE;
    assign mem_write_data       = EXE_MEM_RS2;
    
    
    
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // PIPELINE
    // 每一个stage,从上面的transfer register继承的值可靠
    // 本阶段组合逻辑得到的结果不一定可靠,等待一个周期?
    
    // STATE CONTROLER
    // 
    // stall or not
    // 可能因为访存等原因stall
    
    reg         IF_STATE_CTR  = 0;
    reg         ID_STATE_CTR  = 0;
    reg         EXE_STATE_CTR = 0;
    reg         MEM_STATE_CTR = 0;
    reg         WB_STATE_CTR  = 0;
    
    // REGISTER FILE
    // ----------------------------------------------------------------------------
    wire [1:0]              rf_signal;
    wire [1:0]              rf_status;
    wire                    write_back_enabled;
    reg [LEN-1:0]           reg_write_data;
    wire [LEN-1:0]          rs1_value;
    wire [LEN-1:0]          rs2_value;
    
    assign  write_back_enabled = WB_STATE_CTR;
    assign  rf_signal          = (WB_STATE_CTR&&rb_flag)? `RF_WRITE:`RF_NOP;
    
    REG_FILE reg_file(
    .clk            (clk),
    .rst            (rst),
    .rdy_in         (rdy_in),
    .rf_signal      (rf_signal),
    .rs1            (rs1_index),
    .rs2            (rs2_insdex),
    .rd             (MEM_WB_RD_INDEX),
    .data           (reg_write_data),
    .write_back_enabled(write_back_enabled),
    .rs1_data       (rs1_value),
    .rs2_data       (rs2_value),
    .rf_status      (rf_status)
    );
    
    // IMMIDIATE GENETATOR
    // -----------------------------------------------------------------------------
    wire [LEN-1:0]          immediate;
    IMMEDIATE_GENETATOR immediate_generator(
    .chip_enable(chip_enable),
    .instruction        (instruction),
    .inst_type          ({R_type,I_type,S_type,B_type,U_type,J_type}),
    .immediate          (immediate)
    );
    
    // ALU
    // -----------------------------------------------------------------------------
    wire [LEN-1:0]      alu_result;
    wire [1:0]          sign_bits;
    
    ALU alu(
    .rs1        (ID_EXE_RS1),
    .rs2        (ID_EXE_RS2),
    .imm        (ID_EXE_IMM),
    .pc         (ID_EXE_PC),
    .alu_signal (ID_EXE_ALU_SIGNAL),
    .func_code  (ID_EXE_FUNC_CODE),
    .result     (alu_result),
    .sign_bits  (sign_bits)
    );
    
    
    // rst为1，整体开始工作
    // -------------------------------------------------------------------------------
    reg chip_enable;
    reg start_cpu = 0;
    
    always @ (posedge clk) begin
        if (rst == 0) begin
            if (!start_cpu) begin
                IF_STATE_CTR <= 1;
                start_cpu    <= 1;
            end
            chip_enable <= 1;
        end
        else
            chip_enable <= 0;
    end
    
    // STAGE1 : INSTRUCTION FETCH
    // - memory visit取指令
    // - 更新transfer register的PC
    // ---------------------------------------------------------------------------------------------
    
    always @(posedge clk) begin
        if (rdy_in) begin
            if (chip_enable&&start_cpu) begin
                if (IF_STATE_CTR) begin
                    IF_ID_PC <= PC;
                end
                // IF没有结束，向下加stall
                if (mem_vis_status == `IF_FINISHED) begin
                    ID_STATE_CTR <= 1;
                end
                else begin
                    ID_STATE_CTR <= 0;
                end
            end
            else begin
                PC = 0;
            end
        end
    end
    
    // STAGE2 : INSTRUCTION DECODE
    // - decode(组合逻辑接线解决)
    // - 访问register file取值
    // 更新transfer register
    // ---------------------------------------------------------------------------------------------
    always @(posedge clk) begin
        if ((!rst)&&rdy_in&&start_cpu) begin
            if (ID_STATE_CTR) begin
                ID_EXE_PC                <= IF_ID_PC;
                ID_EXE_RD_INDEX          <= rd_index;
                ID_EXE_ALU_SIGNAL        <= alu_signal;
                ID_EXE_FUNC_CODE         <= func_code;
                ID_EXE_BRANCH_SIGNAL     <= branch_signal;
                ID_EXE_MEM_VIS_SIGNAL    <= mem_vis_signal;
                ID_EXE_MEM_VIS_DATA_SIZE <= data_size;
                ID_EXE_WB_SIGNAL         <= wb_signal;
                ID_EXE_IMM               <= immediate;
                ID_EXE_RS1               <= rs1_value; // 时间有误，存到了旧的数据
                ID_EXE_RS2               <= rs2_value;
                EXE_STATE_CTR            <= 1;
            end
            else begin
                EXE_STATE_CTR <= 0;
            end
        end
    end
    
    // STAGE3 : EXECUTE
    // - alu执行运算
    // ---------------------------------------------------------------------------------------------
    always @(posedge clk) begin
        if ((!rst)&&rdy_in&&start_cpu)begin
            if (EXE_STATE_CTR) begin
                EXE_MEM_PC                <= ID_EXE_PC;
                EXE_MEM_RD_INDEX          <= ID_EXE_RD_INDEX;
                EXE_MEM_FUNC_CODE         <= ID_EXE_FUNC_CODE;
                EXE_MEM_BRANCH_SIGNAL     <= ID_EXE_BRANCH_SIGNAL;
                EXE_MEM_MEM_VIS_SIGNAL    <= ID_EXE_MEM_VIS_SIGNAL;
                EXE_MEM_MEM_VIS_DATA_SIZE <= ID_EXE_MEM_VIS_DATA_SIZE;
                EXE_MEM_WB_SIGNAL         <= ID_EXE_WB_SIGNAL;
                EXE_MEM_IMM               <= ID_EXE_IMM;
                EXE_MEM_RS2               <= ID_EXE_RS2;
                EXE_MEM_RESULT            <= alu_result;
                EXE_MEM_ZERO_BITS         <= sign_bits;
                MEM_STATE_CTR             <= 1;
            end
            else begin
                MEM_STATE_CTR <= 0;
            end
        end
    end
    
    
    // STAGE4 : MEMORY VISIT
    // - visit memory
    // - pc update
    // ---------------------------------------------------------------------------------------------
    
    reg [LEN-1:0] increased_pc;
    reg [LEN-1:0] special_pc;
    
    reg branch_flag;
    
    // branch
    always @(*) begin
        if (EXE_MEM_BRANCH_SIGNAL == `CONDITIONAL) begin
            case (EXE_MEM_FUNC_CODE[2:0])
                3'b000:begin
                    if (EXE_MEM_ZERO_BITS == `ZERO) begin
                        branch_flag = 1;
                    end
                    else begin
                        branch_flag = 0;
                    end
                end
                3'b001:begin
                    if (EXE_MEM_ZERO_BITS == `ZERO) begin
                        branch_flag = 0;
                    end
                    else begin
                        branch_flag = 1;
                    end
                end
                default:
                $display("[ERROR]:unexpected branch instruction\n");
            endcase
        end
        else if (EXE_MEM_BRANCH_SIGNAL == `NOT_BRANCH) begin
            branch_flag = 0;
        end
        else begin
            branch_flag = 1;
        end
    end
    
    always @(*) begin
        increased_pc = EXE_MEM_PC + 4;
        if (EXE_MEM_BRANCH_SIGNAL == `UNCONDITIONAL_RESULT) begin
            special_pc = EXE_MEM_RESULT &~ 1;
        end
        else begin
            special_pc = EXE_MEM_PC + EXE_MEM_IMM;
        end
    end
    
    // memory visit
    always @(posedge clk) begin
        if ((!rst)&&rdy_in&&start_cpu) begin
            if (MEM_STATE_CTR) begin
                
                if (mem_vis_status == `RESTING) begin
                    // update pc
                    if (branch_flag) begin
                        PC <= special_pc;
                    end
                    else begin
                        PC <= increased_pc;
                    end
                    MEM_WB_PC        <= EXE_MEM_PC;
                    MEM_WB_RD_INDEX  <= EXE_MEM_RD_INDEX;
                    MEM_WB_WB_SIGNAL <= EXE_MEM_WB_SIGNAL;
                    MEM_WB_RESULT    <= EXE_MEM_RESULT;
                end
            end
            
            if (mem_vis_status == `R_W_FINISHED) begin
                // data from memmory
                MEM_WB_MEM_DATA <= mem_read_data;
                WB_STATE_CTR    <= 1;
            end
            else begin
                WB_STATE_CTR <= 0;
            end
        end
    end
    
    // STAGE5 : WRITE BACK
    // - write back to register
    // ---------------------------------------------------------------------------------------------
    
    reg [LEN-1:0] register_write_data;
    reg rb_flag;
    
    always @(*) begin
        case (MEM_WB_WB_SIGNAL)
            `MEM_TO_REG:begin
                reg_write_data = MEM_WB_MEM_DATA;
                rb_flag        = 1;
            end
            `ARITH:begin
                reg_write_data = MEM_WB_RESULT;
                rb_flag        = 1;
            end
            `INCREASED_PC:begin
                reg_write_data = 4 + MEM_WB_PC;
                rb_flag        = 1;
            end
            `WB_NOP:begin
                rb_flag = 0;
            end
        endcase
    end
    
    always @(posedge clk) begin
        if ((!rst)&&rdy_in&&start_cpu)begin
            if (rf_status == `RF_FINISHED) begin
                IF_STATE_CTR <= 1;
            end
            else begin
                IF_STATE_CTR <= 0;
            end
        end
    end
endmodule
