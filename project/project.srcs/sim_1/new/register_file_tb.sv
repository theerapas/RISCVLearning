`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2026 10:45:44 AM
// Design Name: 
// Module Name: register_file_tb
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


module register_file_tb();
    logic clk = 1'b0;
    logic write_enable;
    logic [4:0] write_address;
    logic [31:0] write_data;
    logic [4:0] read_address1;
    logic [4:0] read_address2;
    logic [31:0] read_data1;
    logic [31:0] read_data2;
    register_file dut (
        .clk(clk),
        .write_enable(write_enable),
        .write_address(write_address),
        .write_data(write_data),
        .read_address1(read_address1),
        .read_address2(read_address2),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    always #5 clk = ~clk;

    initial begin
        read_address1 = 0;
        read_address2 = 0;
        #1;
        if(read_data1 !== 0)
            $fatal(1,"read_data1 is %h, expect 0",read_data1);
        if(read_data2 !== 0)
            $fatal(1,"read_data2 is %h, expect 0",read_data2);

        #1;
        write_enable = 1;
        write_address = 5'd5;
        write_data = 32'd7;
        read_address1 = 5'd5;
        read_address2 = 5'd5;
        @(posedge clk);
        #1;
        if(read_data1 !== 32'd7)
            $fatal(1,"Write failed, read_data1 is %h, expected 32'd7",read_data1);
        if(read_data2 !== 32'd7)
            $fatal(1,"Write failed, read_data2 is %h, expected 32'd7",read_data2);
        @(negedge clk);
        write_address = 0;
        write_data = 32'd1;
        read_address1 = 0;
        read_address2 = 0;
        @(posedge clk);
        #1;
        if(read_data1 !== 0)
            $fatal(1,"Write failed, read_data1 is %h, expected 0",read_data1);
        if(read_data2 !== 0)
            $fatal(1,"Write failed, read_data2 is %h, expected 0",read_data2);
        
        $display("Register file read and write checks passed");
        $finish;
    end
endmodule
