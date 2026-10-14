`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2026 11:58:05 AM
// Design Name: 
// Module Name: addition_unit
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


module addition_unit(
    input logic [31:0] data_a,
    input logic [31:0] data_b,
    output logic [31:0] data_out
    );

    always_comb begin
        data_out = data_a + data_b;
    end
endmodule
