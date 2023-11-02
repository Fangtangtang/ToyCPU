// branch controller

`include"src/defines.v"

module branch_controller(input rdy_in,
                         input [1:0] branch_flag,
                         input [1:0] sign_bits,
                         output wire special_pc_flag);
    
    reg flag;
    
    assign special_pc_flag = flag;
    
    always @(*) begin
        if (rdy_in) begin
            case (branch_flag)
                `NOTBRANCH:flag    = 1'b0;
                `UNCONDBRANCH:flag = 1'b1;
                `CONDBRANCH:begin
                    if (sign_bits == `ZERO) begin
                        flag = 1'b1;
                    end
                    else begin
                        flag = 1'b0;
                    end
                end
            endcase
        end
    end
endmodule
