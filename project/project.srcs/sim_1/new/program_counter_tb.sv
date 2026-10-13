`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2026 05:56:18 PM
// Design Name: 
// Module Name: program_counter_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module program_counter_tb();
    logic clk = 1'b0;
    logic rst_n;
    logic [31:0] next_pc;
    logic [31:0] pc;

    program_counter dut (
        .clk(clk),
        .rst_n(rst_n),
        .next_pc(next_pc),
        .pc(pc)
    );

    always #5 clk = ~clk;

    initial begin
        rst_n = 1'b0;
        next_pc = 32'd12;
        @(posedge clk);
        #1;
        if(pc !== 32'd0)
            $fatal(1, "Reset check failed: pc is %h, expected 0",pc);
        
        @(negedge clk);
        rst_n = 1'b1;
        next_pc = 32'd4;
        #1;
        if(pc !== 32'b0)
            $fatal(1,"PC changed before rising edge: pc is %h",pc);

        @(posedge clk);
        #1;
        if(pc !== 32'd4)
            $fatal(1,"Capture check failed: pc is %h, expected 4",pc);

        @(negedge clk);
        next_pc = 32'd8;
        #1;
        if(pc !== 32'd4)
            $fatal(1,"Capture check failed: pc is %h, expected 4",pc);

        @(posedge clk);
        #1;
        if(pc !== 32'd8)
            $fatal(1,"Capture check failed: pc is %h, expected 8",pc);

        $display("PC reset and capture checks passed");
        $finish;
    end
endmodule
