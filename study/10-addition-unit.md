# Next RTL building block: a 32-bit addition unit

## Goal

Provide the arithmetic operation needed by the first CPU instruction, `ADDI`. The unit receives two 32-bit operands and produces a 32-bit sum. For the first instruction, the values are x0 (`0`) and the sign-extended immediate (`7`), so the result is `7`.

## Architecture concepts

This block is combinational: its output depends only on its current operands. It has no stored state, so it needs no clock or reset. The source register value and immediate can flow through it during the instruction cycle; the register file stores the result later at a rising edge.

The block is deliberately separate from the sequential register file. This makes it possible to reason about the arithmetic independently before wiring the datapath together.

## Module interface

```text
Inputs:  data_a[31:0], data_b[31:0]
Output:  data_out[31:0]
```

For the first milestone, the only required operation is addition. The minimal design therefore has no operation-select input, clock, reset, carry output, or overflow output. If later instructions need several ALU operations, we can revisit whether to extend this module or add a separate ALU control interface.

## Expected behavior

`data_out` follows `data_a + data_b` after combinational logic settles. The implementation uses an `always_comb` block and assigns the sum every time the inputs change, so no storage is inferred. The output is 32 bits, matching the operands. The first CPU datapath case is `32'd0 + 32'd7 = 32'd7`.

The learner implemented the add-only module. The next step is to verify the combinational behavior with a small testbench.

## Incremental verification plan

Check a few operand pairs in a small combinational testbench, including `0 + 7 = 7`. Change the inputs, allow a short settling step, and check the output without waiting for a clock edge.

## Testbench results

The testbench checks `32'd0 + 32'd7 = 32'd7` and `32'hFFFFFFFF + 32'h00000001 = 32'h00000000`. The second case checks that a carry beyond the 32-bit result width is discarded. The learner reported that Vivado behavioral simulation passed both checks.

## Learning checkpoint before RTL

Why does the addition unit not need a clock? For the first milestone, should this be a direct add-only block, or include an operation-select signal for future ALU instructions?
