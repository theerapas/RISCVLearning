`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2026 10:33:29 AM
// Design Name: 
// Module Name: register_file
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


module register_file(
    input logic clk,
    input logic write_enable,
    input logic [4:0] write_address,
    input logic [31:0] write_data,
    input logic [4:0] read_address1,
    input logic [4:0] read_address2,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
    );

    logic [31:0] registers [0:31];

    always_comb begin
        if(read_address1 == 0)
            read_data1 = 0;
        else
            read_data1 = registers[read_address1];
        if(read_address2 == 0)
            read_data2 = 0;
        else
            read_data2 = registers[read_address2];
    end

    always_ff @(posedge clk) begin
        if(write_enable && (write_address != 0)) begin
            registers[write_address] <= write_data;
        end
    end
endmodule
