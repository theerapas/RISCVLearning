`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2026 05:12:34 PM
// Design Name: 
// Module Name: program_counter
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


module program_counter(
        input logic clk,
        input logic rst_n,
        input logic [31:0] next_pc,
        output logic [31:0] pc
    );

    always_ff @(posedge clk) begin
        if(!rst_n)
            pc <= 0;
        else
            pc <= next_pc;
    end

endmodule
