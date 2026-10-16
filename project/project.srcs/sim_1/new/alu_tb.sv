`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2026 02:24:29 PM
// Design Name: 
// Module Name: alu_tb
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


module alu_tb();
    logic [31:0] data_a;
    logic [31:0] data_b;
    logic [2:0] op_control;
    logic [31:0] data_out;
    alu dut (
        .data_a(data_a),
        .data_b(data_b),
        .op_control(op_control),
        .data_out(data_out)
    );

    // op_control = 000 (ADD), 001 (SUB), 010 (AND), 011 (OR), 100 (XOR), other -> 0
    initial begin
        data_a = 32'd5;
        data_b = 32'd7;
        op_control = 3'b000;
        #1;
        if(data_out !== 32'd12)
            $fatal(1,"ADD failed, data_out is %h, expect 12",data_out);
        
        #1;
        data_a = 32'h00000001;
        data_b = 32'h00000002;
        op_control = 3'b001;
        #1;
        if(data_out !== 32'hFFFFFFFF)
            $fatal(1,"SUB failed, data_out is %h, expect FFFFFFFF",data_out);

        #1;
        data_a = 32'h0000FFFF;
        data_b = 32'h0F0F0F0F;
        op_control = 3'b010;
        #1;
        if(data_out !== 32'h00000F0F)
            $fatal(1,"AND failed, data_out is %h, expect 00000F0F",data_out);

        #1;
        data_a = 32'h0000FFFF;
        data_b = 32'h0F0F0F0F;
        op_control = 3'b011;
        #1;
        if(data_out !== 32'h0F0FFFFF)
            $fatal(1,"OR failed, data_out is %h, expect 0F0FFFFF",data_out);

        #1;
        data_a = 32'h0000FFFF;
        data_b = 32'h0F0F0F0F;
        op_control = 3'b100;
        #1;
        if(data_out !== 32'h0F0FF0F0)
            $fatal(1,"XOR failed, data_out is %h, expect 0F0FF0F0",data_out);

        #1;
        data_a = 32'h0000FFFF;
        data_b = 32'h0F0F0F0F;
        op_control = 3'b111;
        #1;
        if(data_out !== 32'd0)
            $fatal(1,"default case failed, data_out is %h, expect 0",data_out);

        $display("ALU checks passed");
        $finish;
    end

endmodule
