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
    logic write_enable;

    logic [31:0] alu_data_b;
    logic [2:0] alu_op_control;
    logic [31:0] alu_result;

    program_counter pc_state (
        .clk(clk),
        .rst_n(rst_n),
        .next_pc(next_pc),
        .pc(instr_addr)
    );

    alu pc_incrementer (
        .data_a(instr_addr),
        .data_b(32'd4),
        .op_control(3'b000),
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
        .write_data(alu_result),
        .read_address1(instr_rdata[19:15]),
        .read_address2(instr_rdata[24:20]),
        .read_data1(rs1_value),
        .read_data2(rs2_value)
    );

    alu alu_module (
        .data_a(rs1_value),
        .data_b(alu_data_b),
        .op_control(alu_op_control),
        .data_out(alu_result)
    );

    always_comb begin
        alu_op_control = 3'b111;
        alu_data_b = rs2_value;
        write_enable = 0;
        if(instr_rdata[6:0] == 7'b0110011) begin // opcode
            case (instr_rdata[31:25]) // funct7
                7'b0000000: begin
                    case (instr_rdata[14:12]) // funct3
                        3'b000: begin
                            alu_op_control = 3'b000;
                            write_enable = rst_n;
                        end 
                        3'b100: begin
                            alu_op_control = 3'b100;
                            write_enable = rst_n;
                        end
                        3'b110: begin
                            alu_op_control = 3'b011;
                            write_enable = rst_n;
                        end
                        3'b111: begin
                            alu_op_control = 3'b010;
                            write_enable = rst_n;
                        end
                        default: ;
                    endcase
                end
                7'b0100000: begin
                    case (instr_rdata[14:12]) // funct3
                        3'b000: begin
                            alu_op_control = 3'b001;
                            write_enable = rst_n;
                        end
                        default: ;
                    endcase
                end
                default: ;
            endcase
        end else if((instr_rdata[6:0] == 7'b0010011) && (instr_rdata[14:12] == 3'b000)) begin // ADDI
            alu_data_b = immediate;
            alu_op_control = 3'b000;
            write_enable = rst_n;
        end
        
    end

endmodule
