# Next RTL building block: the register file

## Goal

Design a small register file that supports the first CPU instruction, `addi x5, x0, 7`. It must provide the current value of source register `x0` during the cycle and store the computed result into destination register `x5` at a rising clock edge.

## Architecture concepts

The RV32 integer register file has 32 architectural registers, each 32 bits wide. An instruction names registers with 5-bit fields such as `rs1` and `rd`.

Register reads are combinational: a read address selects a stored value and the output follows that address after logic settles. Register writes are sequential: on a rising clock edge, write-enable and write-address controls determine whether a new value is stored. This lets an instruction read its source and calculate a result during a cycle, then commit the destination value at the edge.

Architectural `x0` is special: every read returns zero, and writes to `x0` must have no architectural effect. This behavior is required regardless of how the storage array is implemented internally.

## Choices to make before RTL

### Number of read ports

- One read port is enough for `ADDI`, whose second operand is the immediate. This keeps the first version focused; a later register-register instruction would require adding another read port.
- Two read ports match the usual integer register-file interface and will support later instructions that read `rs1` and `rs2`.

Decision: use **two combinational read ports** so the interface also fits later register-register instructions.

### Representation of x0

- Use a 32-entry array, force reads at address zero to return zero, and suppress writes to address zero. This preserves direct correspondence between a 5-bit architectural address and an array index, while making the special behavior explicit.
- Alternatively, store only x1 through x31 and handle address zero separately; this saves one unused word but requires index handling that is less direct for this learning milestone.

Decision: use a **32-entry array** indexed directly by the 5-bit architectural address. Entry zero is not relied on for reads or writes: reads at address zero will be forced to zero, and writes at address zero will be ignored.

### Reset behavior

The PC has a synchronous active-low reset. That does not automatically mean the register file must reset. For the first test, only x0 must be defined before execution, and x5 is checked after it is written. Decide explicitly whether x1 through x31 are reset to zero or left unspecified at reset; leaving them unspecified avoids adding a broad initialization behavior that this instruction does not need.

Decision: do **not** reset x1 through x31. The register file has no reset port in this version. Reads of x0 still return zero at all times, and writes to x0 still have no effect.

## Proposed module interface

The interface needs a clock, a write enable/address/data group, two read addresses, and two read-data outputs. A 5-bit address selects one of 32 architectural registers; each data value is 32 bits. Suggested signal names are `clk`, `write_enable`, `write_address[4:0]`, `write_data[31:0]`, `read_address1[4:0]`, `read_address2[4:0]`, `read_data1[31:0]`, and `read_data2[31:0]`. There is no reset input because the selected reset behavior leaves x1 through x31 unspecified.

The learner will first write only this module declaration and port list. Storage and behavior will be added in later small steps.

## Expected first-instruction behavior

For `addi x5, x0, 7`, the read address selects x0 and produces zero. The CPU calculates `0 + 7`. At a rising edge with write enabled and destination address 5, x5 becomes 7. A read of x0 continues to return zero, including if a write is attempted to address zero.

## Incremental verification plan

Before integrating the CPU, test the register-file contract directly:

1. Read address zero and check that the output is zero.
2. Write a nonzero value to a nonzero address on a rising edge, then check that reading that address returns the stored value.
3. Attempt a write to address zero, then check that reading address zero still returns zero.

The testbench will use the same rising-edge convention as the PC and may use hierarchical observation only where appropriate for later CPU-level testing.

## Learning checkpoint before RTL

Why should reads be combinational while writes occur at a clock edge? Reads are available to the current instruction's datapath during the cycle; writes commit architectural state at a defined rising edge. Avoiding race conditions is mainly a testbench scheduling concern, rather than the reason register writes are clocked. What must happen when address zero is read or written? Which read-port count and register reset behavior should this first implementation use?

The learner chose two read ports and no reset for x1 through x31. Address zero must still read as zero, and writes to it must be ignored.

The learner chose a 32-entry array so architectural register addresses map directly to array indices. The next RTL step is only to declare that 32-word by 32-bit storage array; no read or write behavior is added in that step.

## RTL step: add both read ports and the write port

After the array declaration, add its behavior in two blocks. An `always_comb` block calculates both read outputs from their current addresses. For each port, address zero produces constant zero; any other address selects the corresponding array entry. Assign both outputs in every branch so the logic remains combinational and does not infer a latch.

An `always_ff @(posedge clk)` block performs writes. It stores `write_data` into `registers[write_address]` only when `write_enable` is high and `write_address` is nonzero. Use a nonblocking assignment (`<=`) because the array is state that updates on a clock edge. There is no reset branch: x1 through x31 are intentionally unspecified until written, and x0's externally visible behavior is enforced by the read and write rules.

In synthesizable RTL, use logical inequality (`!=`) for the nonzero-address condition. Case inequality (`!==`) is useful in a testbench when an unknown (`X`) or high-impedance (`Z`) value must count as a mismatch; it is not the intended hardware comparison here. The testbench's `!==` checks and the RTL's `!=` condition serve different purposes.

The learner added these two behavior blocks. This is the complete initial two-read, one-write register-file behavior; no CPU integration is included yet. The read block forces zero for address zero and selects the array for all other addresses. The clocked write block uses `write_enable` and logical inequality (`!=`) to ignore writes to address zero.

The next step is one compact module-level testbench covering x0 reads, a write to a nonzero register followed by reads through both ports, and an attempted write to x0. Because x1 through x31 have no reset, the test must write a register before expecting its stored value.

## Testbench results

The register-file testbench checks that both read ports return zero for address zero, writes `32'd7` to address 5 at a rising edge, checks that both read ports then return 7, and attempts a write to address zero before checking that both ports still read zero. The testbench reports success and calls `$finish`. The learner reported that Vivado behavioral simulation passed.

The x0 output check confirms the architectural read behavior. Since reads of address zero are deliberately forced to zero, that output check alone does not reveal whether the unused internal array entry zero was written; the RTL write guard is reviewed separately to ensure writes to address zero are suppressed.
