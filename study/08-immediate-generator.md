# Second RTL building block: an I-type immediate generator

## Goal

Create a small combinational block that receives a 32-bit instruction and produces its sign-extended I-type immediate. This block will later provide the constant operand for `ADDI`.

## What the block does

For RISC-V I-type instructions, the 12-bit immediate is stored in instruction bits `[31:20]`. The CPU needs a 32-bit value for its datapath, so it sign-extends that 12-bit field: the field's sign bit (bit 11, which is instruction bit 31) is copied into the upper 20 bits.

Examples:

| 12-bit immediate | Signed meaning | 32-bit sign-extended result |
|---|---:|---|
| `12'h007` | 7 | `32'h00000007` |
| `12'hFFF` | -1 | `32'hFFFFFFFF` |
| `12'h800` | -2048 | `32'hFFFFF800` |

For instruction `32'h00700293` (`addi x5, x0, 7`), bits `[31:20]` contain `12'h007`, so the output is `32'h00000007`.

## Why this block has no clock or reset

The immediate generator does not remember anything. Its output is determined entirely by the current instruction input. When the instruction changes, the extracted and extended immediate changes after combinational logic settles. There is no stored state to reset and no reason to wait for a clock edge.

This contrasts with the PC: the PC remembers an address and changes only at a rising edge, while the immediate generator continuously calculates a value from the current instruction.

## Proposed module boundary

```text
Input:  instruction[31:0]
Output: immediate[31:0]
```

For this first version, the module supports only the I-type immediate layout used by `ADDI`. Later, other RISC-V instruction formats will need different bit arrangements; we will extend the module only when we add those instructions.

## Verification plan

Use a small testbench to change the instruction and check the immediate output:

1. For `32'h00700293`, expect `32'h00000007`.
2. For any instruction word whose bits `[31:20]` are `12'hFFF`, expect `32'hFFFFFFFF`.
3. For bits `[31:20]` equal to `12'h800`, expect `32'hFFFFF800`.

Since the block is combinational, each expected output should appear without waiting for a clock edge. In simulation, the testbench must allow a small settling step after changing the instruction before checking the output.

## Testbench results

The immediate-generator testbench drives three instruction words and checks the output after a `#1` settling delay:

| Instruction | Immediate field `[31:20]` | Expected output | What it checks |
|---|---|---|---|
| `32'h00700293` | `12'h007` | `32'h00000007` | Positive immediate |
| `32'hFFF00293` | `12'hFFF` | `32'hFFFFFFFF` | Sign extension of -1 |
| `32'h80000293` | `12'h800` | `32'hFFFFF800` | Sign extension of the most-negative 12-bit value (-2048) |

The learner reported that Vivado behavioral simulation passed these three checks. The testbench uses case inequality (`!==`) so unknown (`X`) or high-impedance (`Z`) output bits count as a failure rather than accidentally matching a 0/1 comparison.

## Learning checkpoint before RTL

What is the immediate field's bit range in an I-type instruction? Why does the immediate generator not need `clk` or `rst_n`? Explain why `12'hFFF` must become `32'hFFFFFFFF` rather than `32'h00000FFF`.

## RTL step: express sign extension as combinational logic

The module interface is `instruction[31:0]` in and `immediate[31:0]` out. The next small step is to describe how the output is calculated; it does not add state, a clock, or reset behavior.

An I-type immediate has 12 bits, but the output has 32. The immediate's sign bit is `instruction[31]`. To preserve the signed two's-complement value, the output's upper 20 bits must all copy that sign bit, while the lower 12 bits come directly from `instruction[31:20]`. The width calculation is `32 - 12 = 20`.

We use a combinational `always_comb` block because the output port is declared `logic`, matching the project's `program_counter` style. The block assigns `immediate` on every evaluation so there is no implied storage. The implementation expression is `{{20{instruction[31]}}, instruction[31:20]}`: the inner replication creates 20 copies of the sign bit, and the surrounding concatenation appends the 12-bit immediate. The result is 32 bits. For example, `instruction[31:20] = 12'h007` gives `32'h00000007`, and `instruction[31:20] = 12'hFFF` gives `32'hFFFFFFFF`.

No decoder, instruction-format selection, or other immediate type is included in this step. The immediate generator RTL is now written; the next step is to check its behavior with a testbench.
