// #############################################################################################################################
// testbench top module file
// for simulation only
// #############################################################################################################################

`include "src_modified/top.v"

`timescale 1ns/1ps

module testbench;

    reg clk; 
    reg rst; 
    top top_(.clk(clk), .btnC(rst));
    
    initial begin
        clk               = 0;
        rst               = 1;
        repeat(50) #1 clk = !clk;
        rst               = 0;
        forever #1 clk    = !clk;
        
        $finish;
    end
    
    // 生成vcd文件
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, testbench);
        $dumpall;
        #3000 $finish;
    end
    
endmodule
