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
            32'd0: instr_rdata = 32'h00700293; // addi x5, x0, 7
            default: instr_rdata = 32'h00000013; // addi x0, x0, 0
        endcase
    end

    initial begin
        rst_n = 1'b0;
        @(posedge clk);
        #1;
        if(instr_addr !== 32'd0)
            $fatal(1,"Reset failed, instr_addr is %h, expect 0",instr_addr);
        if(dut.write_enable !== 1'b0)
            $fatal(1,"write_enable should be 0 during reset");

        @(negedge clk);
        rst_n = 1'b1;
        #1;

        // check before commit
        if(dut.rs1_value !== 32'd0)
            $fatal(1,"x0 is %h, expect 0",dut.rs1_value);
        if (dut.immediate !== 32'd7)
            $fatal(1,"Immediate is %h, expect 7",dut.immediate);
        if (dut.addi_result !== 32'd7)
            $fatal(1,"addi_result is %h, expect 7",dut.addi_result);

        // check write x5 = x0 + 7 and pc + 4
        @(posedge clk);
        #1;
        if (instr_addr !== 32'd4)
            $fatal(1,"PC is %h, expect 4",instr_addr);

        if (dut.rf.registers[5] !== 32'd7)
            $fatal(1,"x5 is %h, expect 7",dut.rf.registers[5]);

        $display("ADDI CPU check passed");
        $finish;
    end
endmodule
