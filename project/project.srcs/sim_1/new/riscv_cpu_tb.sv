`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/14/2026 10:46:13 PM
// Design Name: 
// Module Name: riscv_cpu_tb
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


module riscv_cpu_tb();
    logic clk = 1'b0;
    logic rst_n;
    logic [31:0] instr_rdata;
    logic [31:0] instr_addr;

    riscv_cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .instr_rdata(instr_rdata),
        .instr_addr(instr_addr)
    );

    always #5 clk = ~clk;

    always_comb begin
        case (instr_addr)
            32'd0:  instr_rdata = 32'h00C00093; // addi x1, x0, 12
            32'd4:  instr_rdata = 32'h00A00113; // addi x2, x0, 10
            32'd8:  instr_rdata = 32'h002081B3; // add x3, x1, x2
            32'd12: instr_rdata = 32'h40208233; // sub x4, x1, x2
            32'd16: instr_rdata = 32'h0020F2B3; // and x5, x1, x2
            32'd20: instr_rdata = 32'h0020E333; // or x6, x1, x2
            32'd24: instr_rdata = 32'h0020C3B3; // xor x7, x1, x2
            default: instr_rdata = 32'h00000013; // nop
        endcase
    end

    task automatic run_and_check(
        input logic [31:0] expected_result,
        input logic [4:0] expected_rd,
        input logic [31:0] expected_next_pc
    );
    begin
        #1;
        if (dut.write_enable !== 1'b1)
            $fatal(1, "Write enable is low at PC %0d", instr_addr);
        if (dut.alu_result !== expected_result)
            $fatal(1, "ALU result at PC %0d is %h, expect %h", instr_addr, dut.alu_result, expected_result);

        @(posedge clk);
        #1;
        if (instr_addr !== expected_next_pc)
            $fatal(1, "PC is %0d, expect %0d", instr_addr, expected_next_pc);
        if (dut.rf.registers[expected_rd] !== expected_result)
            $fatal(1, "x%0d is %h, expect %h", expected_rd, dut.rf.registers[expected_rd], expected_result);
    end
    endtask

    initial begin
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        if(instr_addr !== 32'd0)
            $fatal(1,"Reset failed, PC is %h, expect 0",instr_addr);
        if(dut.write_enable !== 1'b0)
            $fatal(1,"write_enable should be 0 during reset");

        @(negedge clk);
        rst_n = 1'b1;
        
        run_and_check(32'd12, 5'd1, 32'd4);
        run_and_check(32'd10, 5'd2, 32'd8);
        run_and_check(32'd22, 5'd3, 32'd12);
        run_and_check(32'd2,  5'd4, 32'd16);
        run_and_check(32'd8,  5'd5, 32'd20);
        run_and_check(32'd14, 5'd6, 32'd24);
        run_and_check(32'd6,  5'd7, 32'd28);

        $display("CPU ALU checks passed");
        $finish;
    end
endmodule
