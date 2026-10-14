# First CPU integration: execute `addi x5, x0, 7`

## Goal

Connect the existing PC, immediate generator, register file, and addition unit so one instruction can flow through the datapath and update architectural state. Keep the first CPU focused on `ADDI`; do not add branches, loads, stores, or an instruction-memory module.

## External CPU interface

The boundary was established in [02-first-instruction-contract.md](02-first-instruction-contract.md):

```text
Inputs:  clk, rst_n, instr_rdata[31:0]
Output:  instr_addr[31:0]
```

The CPU's PC drives `instr_addr`. The testbench supplies the instruction corresponding to that address on `instr_rdata`, with no handshake or wait state. The PC uses the already chosen rising-edge update and synchronous active-low reset to zero.

## Data path for ADDI

For `addi x5, x0, 7`, the instruction fields and existing modules connect as follows:

1. `instr_rdata[19:15]` selects `rs1` (x0) at register-file read port 1.
2. The immediate generator extracts and sign-extends `instr_rdata[31:20]` (7).
3. The addition unit adds the register-file value (0) and immediate (7).
4. `instr_rdata[11:7]` selects `rd` (x5), and the sum feeds the register-file write data.
5. At the rising edge, the register file stores 7 in x5 when write enable is asserted.

The register file's second read port is not used by `ADDI`; connect its address to `instr_rdata[24:20]` for a regular instruction-field mapping and leave its data output unused for this instruction.

## Control and PC update

The first control condition recognizes ADDI by checking opcode `[6:0] == 7'b0010011` and funct3 `[14:12] == 3'b000`. That condition drives register-file write enable. This version has no illegal-instruction trap: only ADDI writes a register. The PC's next value is current PC plus 4 for this sequential-only milestone.

There are two additions needed in the same cycle: `rs1 + immediate` and `PC + 4`. A single-cycle datapath calculates both concurrently, so instantiate the same addition-unit module twice. Reusing a module definition does not mean reusing one physical adder instance.

## State versus combinational logic

Instruction field selection, immediate generation, ADDI decode, register reads, both additions, and PC next-address calculation are combinational. The PC and register-file write are state updates at the rising clock edge. Reset affects the PC only; x1 through x31 remain unspecified until written, while x0 reads as zero and ignores writes.

## Incremental integration steps

1. Write the CPU module boundary with the agreed ports.
2. Add internal signals and instantiate the existing datapath blocks together, reviewing widths and data flow. Leave the ADDI write-enable signal declared but not decoded yet.
3. Add the ADDI write-enable decode; the PC-plus-four connection is part of step 2.
4. Build a CPU-level testbench that supplies the instruction based on `instr_addr`, then checks PC and x5 after the active edge using the chosen hierarchical simulation observation.

Do not implement all four steps in one edit. Explain and review each stage before continuing.

### Signal map for step 2

Declare 32-bit signals for the current PC, next PC, both register-file read values, the generated immediate, and the ADDI result. Declare a 1-bit write-enable signal for the later decode step. The PC output drives `instr_addr`; a `PC + 4` addition-unit instance drives next PC. The immediate generator receives `instr_rdata`. The register-file address inputs come from instruction fields `[19:15]`, `[24:20]`, and `[11:7]`; its data outputs connect to the read-value signals and its write data connects to the ADDI result. The ADDI addition-unit instance adds read port 1's value and the immediate. The register-file write-enable signal will be driven by opcode/funct3 decode in step 3.

The CPU module boundary is now written as `riscv_cpu` with input `instr_rdata`, matching the established contract.

The learner has added the internal signals and instantiated the PC, PC incrementer, immediate generator, register file, and ADDI adder. The current `write_enable` signal has no driver yet, so the CPU is not ready to simulate.

### RTL step 3: decode ADDI write enable and suppress writes during reset

An instruction decoder examines instruction fields to decide which state changes are allowed. For this first supported instruction, assert `write_enable` only when `rst_n` is high, opcode `[6:0]` equals `7'b0010011`, and funct3 `[14:12]` equals `3'b000`. Use a combinational block because decode depends only on the current instruction and reset input. The CPU contract says the instruction is ignored during reset, so no register write may occur while active-low reset is asserted. This gate does not reset the register file; it only prevents a write during reset. This version has no illegal-instruction trap: unsupported encodings do not write a register, while the sequential PC continues to advance by four outside reset.

The learner added the opcode/funct3 decode. The next RTL correction is to include `rst_n` in that condition. The destination address, source addresses, immediate, and arithmetic value are already wired from instruction fields and datapath signals.

The learner added the `rst_n` gate. When active-low reset is asserted, `write_enable` is low even if the instruction bits happen to encode ADDI. This suppresses instruction state changes during reset without resetting x1 through x31.

### RTL step 4: CPU-level testbench timing

The testbench acts as the instruction source: when `instr_addr` is 0, return `32'h00700293` (`addi x5, x0, 7`); at other addresses, return a harmless instruction such as `32'h00000013` (ADDI x0, x0, 0). A default instruction should also be provided while the PC is unknown before reset.

Use the existing rising-edge clock convention. Start with `rst_n` low and hold it through a rising edge; after a small delay, check that `instr_addr` is zero and `write_enable` is zero. Release reset on a falling edge. Before the next rising edge, allow combinational logic to settle and check that the source value is zero, the immediate is 7, and the ADDI result is 7. After the next rising edge and a small delay, check that `instr_addr` is 4 and `dut.rf.registers[5]` is 7.

The register check is a hierarchical simulation observation, as chosen in [03-observing-register-state.md](03-observing-register-state.md). It intentionally depends on the CPU's `rf` instance name and the register array name. The testbench should use `$fatal` with case inequality for failed comparisons and call `$finish` after all checks.

## CPU-level testbench result

The testbench supplies `32'h00700293` at address 0, holds active-low reset through a rising edge, then releases reset on a falling edge. Before the instruction's commit edge, it checks x0's read value is zero, the immediate is 7, and the adder result is 7. After the next rising edge, it checks PC is 4 and x5 is 7 through `dut.rf.registers[5]`. The learner reported that Vivado behavioral simulation passed.

The initial test attempt left `rst_n` low after the reset edge, so the following rising edge correctly reset the PC to 0 again. Releasing reset on the falling edge allowed the next rising edge to execute the instruction. This demonstrates that synchronous reset remains active at every rising edge while `rst_n` is low.

## Learning checkpoint before integration

Trace the 32-bit value 7 from instruction bits `[31:20]` through the immediate generator and addition unit to x5. Why does the single-cycle CPU need separate addition instances for the instruction result and `PC + 4`?

Checkpoint completed: the learner traced 7 from the instruction's immediate field, through sign extension and addition with x0's value of zero, to the x5 write. They identified that the ADDI result and `PC + 4` must be calculated in the same cycle, so the datapath needs two addition instances.
