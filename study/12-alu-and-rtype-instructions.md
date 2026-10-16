# ALU and R-type arithmetic/logic instructions

## Goal

Extend the ADDI-only CPU so it retains ADDI and also executes five R-type operations: `ADD`, `SUB`, `AND`, `OR`, and `XOR`. The purpose is to introduce an operation-select ALU and the control logic that steers register operands into it. Branches and data memory are outside this step.

## Concepts and instruction encodings

R-type instructions read two registers and write one register. For the standard RV32I integer register-register encoding, the opcode is `0110011` (`7'b0110011`). The fields are:

| Bits | Field | Use |
|---|---|---|
| `[31:25]` | `funct7` | Distinguishes operations that share a `funct3` value, notably ADD and SUB |
| `[24:20]` | `rs2` | Selects the second source register |
| `[19:15]` | `rs1` | Selects the first source register |
| `[14:12]` | `funct3` | Selects an operation family |
| `[11:7]` | `rd` | Selects the destination register |
| `[6:0]` | `opcode` | Identifies register-register integer operation |

The supported R-type encodings are:

| Instruction | `funct7` | `funct3` | ALU behavior |
|---|---|---|---|
| `ADD` | `0000000` | `000` | `rs1 + rs2` |
| `SUB` | `0100000` | `000` | `rs1 - rs2` |
| `XOR` | `0000000` | `100` | bitwise exclusive OR |
| `OR` | `0000000` | `110` | bitwise OR |
| `AND` | `0000000` | `111` | bitwise AND |

ADDI remains an I-type instruction with opcode `0010011` and `funct3` `000`. It reads `rs1`, uses the sign-extended immediate as its second ALU operand, and writes `rd`.

## Proposed datapath and control

Use one shared ALU for ADDI and the five R-type operations. Its inputs are two 32-bit values and a small operation-select control; its output is a 32-bit result. The CPU connects register-file read port 1 to ALU input A. A combinational operand mux selects either the sign-extended immediate (for ADDI) or register-file read port 2 (for supported R-type instructions) as ALU input B. The ALU result feeds register-file write data.

This reuses arithmetic hardware and makes the operand selection visible in the datapath. The existing `PC + 4` addition remains a separate combinational instance because it is calculated in parallel with the instruction result.

One possible 3-bit ALU control mapping is:

| Control | Operation |
|---|---|
| `3'b000` | ADD |
| `3'b001` | SUB |
| `3'b010` | AND |
| `3'b011` | OR |
| `3'b100` | XOR |

These values are internal CPU/ALU signals, not instruction encodings. The decoder translates the instruction's opcode, `funct3`, and (where needed) `funct7` into this control value. Keep the mapping in one clearly documented place so the ALU and decoder agree.

For an ALU control value outside the five listed operations, drive the result to zero. This gives every combinational path a defined assignment and makes the output deterministic. The CPU's supported-instruction decode must independently keep register write enable low for unsupported instructions, so this default value cannot accidentally commit as an architectural result.

For ADDI, the decoder selects ADD and the immediate operand. For R-type operations, it selects the matching ALU control and `rs2`. Register writes are enabled only for a supported ADDI or one of the five exact supported R-type encodings, and only while `rst_n` is high. Unsupported encodings do not write a register. As in the current milestone, the PC continues to advance by four outside reset; traps are not part of this subset.

## Arithmetic and bitwise behavior

ADD and SUB produce the low 32 bits of the result. For example, 32-bit addition wraps modulo `2^32`; a carry beyond bit 31 is discarded. SUB can be understood as `A + (~B) + 1`, though the RTL may use the SystemVerilog subtraction operator directly. No carry, overflow, or comparison flags are needed for this step.

AND, OR, and XOR operate independently on each corresponding bit. For one bit, AND is 1 only when both inputs are 1; OR is 1 when either input is 1; XOR is 1 when the inputs differ. The ALU is combinational, so its output follows its current operands and control after logic settles. State still changes only at the rising edge: the register file commits the result when write enable is asserted.

## Boundaries and assumptions

- Keep the current PC, reset convention, instruction input interface, register-file behavior, and ADDI semantics.
- Support only the five listed R-type encodings. In particular, ADD/SUB require the exact `funct7` values shown; unsupported `funct7` values must not be treated as a supported operation.
- Do not add shifts, comparisons, branches, loads, stores, exception handling, or ALU flags in this step.
- The ALU operation codes above are a proposed internal encoding. They can be changed before RTL if another mapping is easier to explain, but the decoder and ALU must use the same mapping.

## Reviewable implementation sequence

1. Define the ALU interface and combinational behavior for the five operations. Review the operation-select mapping and default behavior before connecting it to the CPU.
2. Update the CPU datapath to select the ALU's second operand and operation. Add exact decode for ADDI and the five R-type encodings; preserve the PC+4 path and suppress unsupported writes.
3. Extend verification incrementally: first check each ALU operation in isolation, then check CPU-level register writes and confirm ADDI still works. Include cases that distinguish ADD from SUB and verify the supported `funct7` checks.

## CPU integration contract

The standalone ALU is implemented as module `alu` with 32-bit `data_a`, `data_b`, and `data_out`, plus 3-bit `op_control`. The learner reports that its ALU testbench passed.

For CPU integration, connect register-file read port 1 (`rs1_value`) to ALU input A. Add a 32-bit signal for ALU input B and select between `immediate` and register-file read port 2 (`rs2_value`): ADDI selects the immediate; supported R-type instructions select `rs2_value`. Connect the ALU output to the register-file write-data input. The existing PC incrementer remains connected to `instr_addr` and `next_pc` as it is now.

The control logic must identify only these supported encodings:

- ADDI: opcode `0010011`, `funct3` `000`; select ADD, immediate as operand B, and enable the destination write.
- ADD: opcode `0110011`, `funct7` `0000000`, `funct3` `000`; select ADD, `rs2` as operand B, and enable the destination write.
- SUB: opcode `0110011`, `funct7` `0100000`, `funct3` `000`; select SUB, `rs2` as operand B, and enable the destination write.
- AND/OR/XOR: opcode `0110011`, `funct7` `0000000`, and the corresponding `funct3` (`111`/`110`/`100`); select the matching operation, `rs2` as operand B, and enable the destination write.

Use defaults at the top of the combinational control block so every control output is assigned for every instruction. A reasonable default is ADD control, register operand selection, and write disabled. Gate write enable with `rst_n`, preserving the current behavior during reset. Exact `funct7` validation matters: for example, `funct3 == 000` alone is not enough to distinguish ADD from SUB or reject another encoding. Unsupported instructions may still advance the PC by four, matching the current no-trap behavior, but must not write a register.

This is one CPU integration step. Do not change reset behavior, register-file behavior, the external instruction interface, or next-PC logic here. When reviewing the result, follow both paths: ADDI should still use its immediate, while an R-type instruction should use `rs2`; both should write the ALU result at the rising edge.

After implementation, record any deviations or clarified choices here. The CPU integration itself has not yet been made.

## CPU-level ALU verification program

The learner reports that the standalone ALU testbench passed. For CPU-level verification, use a short test program that first initializes two source registers with ADDI, then executes each supported R-type operation using the CPU's actual decode, register reads, ALU, and register-file write port:

| PC | Instruction word | Assembly | Expected destination value |
|---:|---:|---|---:|
| 0 | `32'h00C00093` | `addi x1, x0, 12` | x1 = 12 |
| 4 | `32'h00A00113` | `addi x2, x0, 10` | x2 = 10 |
| 8 | `32'h002081B3` | `add x3, x1, x2` | x3 = 22 |
| 12 | `32'h40208233` | `sub x4, x1, x2` | x4 = 2 |
| 16 | `32'h0020F2B3` | `and x5, x1, x2` | x5 = 8 |
| 20 | `32'h0020E333` | `or x6, x1, x2` | x6 = 14 |
| 24 | `32'h0020C3B3` | `xor x7, x1, x2` | x7 = 6 |

The chosen operands distinguish every operation: `12 + 10 = 22`, `12 - 10 = 2`, `12 & 10 = 8`, `12 | 10 = 14`, and `12 ^ 10 = 6`. The instruction source in the testbench should select a word by `instr_addr`, with a harmless default after the final instruction.

For each instruction, check `write_enable` and `alu_result` after combinational logic settles and before the rising edge. Then wait for the rising edge and check that PC advanced by four and the selected destination register contains the expected value. This checks both datapath computation and state commit. Keep the reset check already in the CPU testbench. The program and checks are a proposed verification plan; simulation results should be recorded after the learner runs the updated testbench.

## Verification result

The learner reports that the standalone ALU testbench passed and the CPU-level testbench passed with the two ADDI setup instructions followed by ADD, SUB, AND, OR, and XOR. The CPU-level checks observed each ALU result before the rising edge and verified the destination register and sequential PC update after the edge.

This completes the agreed ALU/R-type milestone. The implementation supports the five listed R-type operations and retains ADDI. It does not yet include shifts, comparisons, branches, memory instructions, flags, or illegal-instruction traps.
