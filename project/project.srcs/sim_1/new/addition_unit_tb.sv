`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2026 12:01:39 PM
// Design Name: 
// Module Name: addition_unit_tb
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


module addition_unit_tb();
    logic [31:0] data_a;
    logic [31:0] data_b;
    logic [31:0] data_out;
    addition_unit dut (
        .data_a(data_a),
        .data_b(data_b),
        .data_out(data_out)
    );

    initial begin
        data_a = 32'd0;
        data_b = 32'd7;
        #1;
        if(data_out !== 32'd7)
            $fatal(1,"data_out is %h, expect 7",data_out);
        
        #1;
        data_a = 32'hFFFFFFFF;
        data_b = 32'h00000001;
        #1;
        if(data_out !== 0)
            $fatal(1,"data_out is %h, expect 0",data_out);

        $display("Addition unit checks passed");
        $finish;
    end
endmodule
