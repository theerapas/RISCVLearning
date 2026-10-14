`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2026 09:59:14 AM
// Design Name: 
// Module Name: immediate_generator_tb
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


module immediate_generator_tb();
    logic [31:0] instruction;
    logic [31:0] immediate;
    immediate_generator dut(
        .instruction(instruction),
        .immediate(immediate)
    );

    initial begin
        instruction = 32'h00700293;
        #1;
        if(immediate !== 32'h00000007)
            $fatal(1,"Immediate is %h, expect 32'h00000007",immediate);
        
        instruction = 32'hFFF00293;
        #1;
        if(immediate !== 32'hFFFFFFFF)
            $fatal(1,"Immediate is %h, expect 32'hFFFFFFFF",immediate);

        instruction = 32'h80000293;
        #1;
        if(immediate !== 32'hFFFFF800)
            $fatal(1,"Immediate is %h, expect 32'hFFFFF800",immediate);

        $display("Immediate generation checks passed");
        $finish;
    end
endmodule
