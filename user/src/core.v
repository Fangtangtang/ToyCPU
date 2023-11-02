// cpu
// connect all the components here

// todo: 需要always块时序逻辑？
`include"src/alu.v"
`include"src/register/pc.v"
`include"src/register/register_file.v"
`include"src/register/transfer_register.v"
`include"src/selector/decoder.v"
`include"src/selector/branch_controller.v"
`include"src/selector/mux.v"


module cpu#(parameter LEN = 32,
            parameter ADDR_WIDTH = 17)
           (input clk,
            input rst,
            input rdy_in,
            input [LEN-1:0] mem_data,          // data input bus
            output [ADDR_WIDTH-1:0] mem_addr,
            output [LEN-1:0] write_data,       // data output bus
            output [1:0] mem_vis_stage_state);
    
    // PC
    wire [LEN-1:0]  special_npc;
    wire [LEN-1:0]  prev_pc;
    wire use_special_pc_flag;
    
    
    pc u_pc(
    .clk            	(clk),
    .rst                (rst),
    .rdy_in             (rdy_in),
    .pre_pc             (prev_pc),
    .npc            	(npc),
    .special_npc    	(special_npc),
    .control_signal 	(use_special_pc_flag),
    .if_flag            (if_flag),
    .cur_pc         	(cur_pc)
    );
    
    wire if_flag;
    wire [LEN-1:0] 	cur_pc;
    wire [LEN-1:0] 	npc;
    
    pc_adder u_pc_adder(
    .pc  	(cur_pc),
    .npc 	(npc)
    );
    
    wire [LEN-1:0] instruction;
    wire [LEN-1:0] read_data;
    wire [LEN-1:0] data_addr;
    wire [ADDR_WIDTH-1:0] mem_addr;
    
    // IF
    mem_addr_mux u_mem_addr_mux(
    .rdy_in         (rdy_in),
    .pc_flag        (if_flag),
    .inst_addr      (cur_pc),
    .data_addr      (data_addr),
    .mem_addr       (mem_addr)
    );
    
    mem_data_mux u_mem_data_mux(
    .rdy_in             (rdy_in),
    .pc_flag        (if_flag),
    .data           (mem_data),
    .inst           (instruction),
    .mem_read       (read_data)
    );
    
    // IF/ID
    // outports wire
    wire o_pc_update_signal;
    wire [LEN-1:0] 	o_c_pc;
    wire [LEN-1:0] 	o_n_pc;
    
    if_id_transfer_reg u_if_id_transfer_reg(
    .clk    	        (clk),
    .rdy_in             (rdy_in),
    .c_pc   	    (cur_pc),
    .o_c_pc 	    (o_c_pc),
    .n_pc   	    (npc),
    .o_n_pc 	    (o_n_pc)
    );
    
    // ID
    // outports wire
    wire [2:0]     	ex_stage_state;
    wire [3:0]     	opcode;
    wire [1:0]     	mem_stage_state;
    wire           	special_pc_flag;
    wire [1:0]     	branch_flag;
    wire [1:0]     	wb_stage_state;
    wire [LEN-1:0] 	immediate;
    
    decoder u_decoder(
    .rdy_in             (rdy_in),
    .instruction     	(instruction),
    .ex_stage_state  	(ex_stage_state),
    .opcode          	(opcode),
    .mem_stage_state 	(mem_stage_state),
    .special_pc_flag 	(special_pc_flag),
    .branch_flag        (branch_flag),
    .wb_stage_state  	(wb_stage_state),
    .immediate       	(immediate)
    );
    
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    wire [4:0] rd  = instruction[11:7];
    
    wire [4:0] rd_pos;
    wire [LEN-1:0] write_reg_data;
    wire            wb_flag;
    
    // outports wire
    wire [LEN-1:0] 	rs1_data;
    wire [LEN-1:0] 	rs2_data;
    
    reg_file u_reg_file(
    .clk       	(clk),
    .rdy_in             (rdy_in),
    .rs1       	(rs1),
    .rs2       	(rs2),
    .wb_flag   	(wb_flag),
    .rd        	(rd_pos),
    .data      	(write_reg_data),
    .rs1_data  	(rs1_data),
    .rs2_data  	(rs2_data)
    );
    
    // ID/EX
    
    // outports wire
    wire            id_ex_o_pc_update_signal;
    wire [LEN-1:0] 	id_ex_o_c_pc;
    wire [LEN-1:0] 	id_ex_o_n_pc;
    wire [2:0]     	o_ex_stage_state;
    wire [1:0]     	o_branch_flag;
    wire [1:0]     	o_mem_stage_state;
    wire [1:0]     	o_wb_stage_state;
    wire [LEN-1:0] 	o_imm;
    wire [LEN-1:0] 	o_rs1;
    wire [LEN-1:0] 	o_rs2;
    wire [3:0]     	o_opcode;
    wire [4:0]     	o_rd;
    
    id_ex_transfer_reg u_id_ex_transfer_reg(
    .clk               	(clk),
    .rdy_in             (rdy_in),
    .c_pc              	(o_c_pc),
    .o_c_pc            	(id_ex_o_c_pc),
    .n_pc              	(o_n_pc),
    .o_n_pc            	(id_ex_o_n_pc),
    .ex_stage_state    	(ex_stage_state),
    .o_ex_stage_state  	(o_ex_stage_state),
    .branch_flag       	(branch_flag),
    .o_branch_flag     	(o_branch_flag),
    .mem_stage_state   	(mem_stage_state),
    .o_mem_stage_state 	(o_mem_stage_state),
    .wb_stage_state    	(wb_stage_state),
    .o_wb_stage_state  	(o_wb_stage_state),
    .imm               	(immediate),
    .o_imm             	(o_imm),
    .rs1               	(rs1_data),
    .o_rs1             	(o_rs1),
    .rs2               	(rs2_data),
    .o_rs2             	(o_rs2),
    .opcode            	(opcode),
    .o_opcode          	(o_opcode),
    .rd                	(rd),
    .o_rd              	(o_rd)
    );
    
    // EX
    
    // outports wire
    wire [LEN-1:0] 	offset_pc;
    
    pc_offset_adder u_pc_offset_adder(
    .pc        	(id_ex_o_c_pc),
    .imm       	(o_imm),
    .offset_pc 	(offset_pc)
    );
    
    // outports wire
    wire [LEN-1:0] 	result;
    wire [1:0]     	sign_bits;
    
    alu u_alu(
    .rdy_in             (rdy_in),
    .rs1          	(o_rs1),
    .rs2          	(o_rs2),
    .imm          	(o_imm),
    .pc           	(id_ex_o_c_pc),
    .ex_stage_state (o_ex_stage_state),
    .opcode       	(o_opcode),
    .result       	(result),
    .sign_bits    	(sign_bits)
    );
    
    // EX/MEM
    // outports wire
    wire [LEN-1:0]  ex_mem_o_c_pc;
    wire [LEN-1:0]  o_offset_pc;
    wire [LEN-1:0] 	ex_mem_o_n_pc;
    wire [1:0]     	ex_mem_o_branch_flag;
    wire [1:0]     	ex_mem_o_mem_stage_state;
    wire [1:0]     	ex_mem_o_wb_stage_state;
    wire [1:0]     	o_sign_bits;
    wire [LEN-1:0] 	o_result;
    wire [LEN-1:0] 	ex_mem_o_rs2;
    wire [4:0]     	ex_mem_o_rd;
    
    assign special_npc = o_offset_pc;
    ex_mem_transfer_reg u_ex_mem_transfer_reg(
    .clk               	(clk),
    .rdy_in             (rdy_in),
    .c_pc               (id_ex_o_c_pc),
    .o_c_pc             (ex_mem_o_c_pc),
    .n_pc              	(id_ex_o_n_pc),
    .o_n_pc            	(ex_mem_o_n_pc),
    .offset_pc          (offset_pc),
    .o_offset_pc        (o_offset_pc),
    .branch_flag       	(o_branch_flag),
    .o_branch_flag     	(ex_mem_o_branch_flag),
    .mem_stage_state   	(o_mem_stage_state),
    .o_mem_stage_state 	(ex_mem_o_mem_stage_state),
    .wb_stage_state    	(o_wb_stage_state),
    .o_wb_stage_state  	(ex_mem_o_wb_stage_state),
    .sign_bits         	(sign_bits),
    .o_sign_bits       	(o_sign_bits),
    .result            	(result),
    .o_result          	(o_result),
    .rs2               	(o_rs2),
    .o_rs2             	(ex_mem_o_rs2),
    .rd                	(o_rd),
    .o_rd              	(ex_mem_o_rd)
    );
    
    // MEM
    branch_controller u_branch_controller(
    .rdy_in             (rdy_in),
    .branch_flag     	(ex_mem_o_branch_flag),
    .sign_bits       	(o_sign_bits),
    .special_pc_flag 	(use_special_pc_flag)
    );
    
    assign data_addr           = o_result;
    assign write_data          = ex_mem_o_rs2;
    assign mem_vis_stage_state = if_flag ? 2'b01 : ex_mem_o_mem_stage_state;
    
    // outports wire
    wire [LEN-1:0]  mem_wb_o_c_pc;
    wire [LEN-1:0] 	mem_wb_o_n_pc;
    wire [1:0]     	mem_wb_o_wb_stage_state;
    wire [LEN-1:0] 	mem_wb_o_result;
    wire [LEN-1:0]  o_mem_data;
    wire [4:0]     	mem_wb_o_rd;
    
    assign rd_pos  = mem_wb_o_rd;
    assign prev_pc = mem_wb_o_c_pc;
    mem_wb_transfer_reg u_mem_wb_transfer_reg(
    .clk              	(clk),
    .rdy_in             (rdy_in),
    .c_pc               (ex_mem_o_c_pc),
    .o_c_pc             (mem_wb_o_c_pc),
    .n_pc             	(ex_mem_o_n_pc),
    .o_n_pc           	(mem_wb_o_n_pc),
    .wb_stage_state   	(o_wb_stage_state),
    .o_wb_stage_state 	(mem_wb_o_wb_stage_state),
    .result           	(o_result),
    .o_result         	(mem_wb_o_result),
    .mem_data         	(read_data),
    .o_mem_data       	(o_mem_data),
    .rd               	(ex_mem_o_rd),
    .o_rd             	(mem_wb_o_rd)
    );
    
    wire [LEN-1:0] o_rd_data;
    wire o_wb_flag;
    
    assign write_reg_data = o_rd_data;
    assign wb_flag        = o_wb_flag;
    
    rd_data_mux u_rd_data_mux(
    .rdy_in             (rdy_in),
    .npc                (mem_wb_o_n_pc),
    .mem_data           (o_mem_data),
    .result             (mem_wb_o_result),
    .wb_stage_state     (mem_wb_o_wb_stage_state),
    .rd_data            (o_rd_data),
    .wb_flag            (o_wb_flag)
    );
    
endmodule
