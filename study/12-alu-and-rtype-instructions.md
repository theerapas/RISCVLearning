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

No RTL has been changed as part of writing this note. Record final interface or behavior changes here after the implementation is reviewed.
