`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2026 08:11:49 PM
// Design Name: 
// Module Name: riscv_cpu
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


module riscv_cpu(
    input logic clk,
    input logic rst_n,
    input logic [31:0] instr_rdata,
    output logic [31:0] instr_addr
    );

    logic [31:0] next_pc;
    logic [31:0] rs1_value;
    logic [31:0] rs2_value;
    logic [31:0] immediate;
    logic [31:0] addi_result;
    logic write_enable;

    program_counter pc_state (
        .clk(clk),
        .rst_n(rst_n),
        .next_pc(next_pc),
        .pc(instr_addr)
    );

    addition_unit pc_incrementer (
        .data_a(instr_addr),
        .data_b(32'd4),
        .data_out(next_pc)
    );

    immediate_generator imm_gen (
        .instruction(instr_rdata),
        .immediate(immediate)
    );

    register_file rf (
        .clk(clk),
        .write_enable(write_enable),
        .write_address(instr_rdata[11:7]),
        .write_data(addi_result),
        .read_address1(instr_rdata[19:15]),
        .read_address2(instr_rdata[24:20]),
        .read_data1(rs1_value),
        .read_data2(rs2_value)
    );

    addition_unit addi_adder (
        .data_a(rs1_value),
        .data_b(immediate),
        .data_out(addi_result)
    );

    always_comb begin
        write_enable = rst_n && (instr_rdata[6:0] == 7'b0010011) && (instr_rdata[14:12] == 3'b000); // decode from opcode and funct3
    end

endmodule
