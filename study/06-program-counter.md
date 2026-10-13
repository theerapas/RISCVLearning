# First RTL building block: the program counter

## Goal

Implement only the program counter (PC), the state element that remembers the address of the instruction the CPU is executing. This is the first RTL block because it gives us a focused place to learn SystemVerilog clocked logic and our reset contract before building the rest of the datapath.

## What the PC does

The PC is a 32-bit stored value. Its current value is presented as the instruction address. Other logic calculates a next-PC value. On a rising clock edge, the PC either resets to 0 or captures that next-PC value.

For the first milestone, there are no branches, jumps, or stalls. The only normal next-PC calculation is `pc + 4`, because the supported instructions are 32 bits (4 bytes) long. We will add alternate next-PC behavior only when we introduce instructions that need it.

## Reset contract

We chose synchronous active-low reset:

- `rst_n == 0` means reset is asserted.
- Since reset is synchronous, the PC changes because of reset at a rising clock edge, not immediately when `rst_n` goes low.
- At a rising edge with reset asserted, the PC becomes 0. Reset has priority over capturing `next_pc`.
- At a rising edge with reset released (`rst_n == 1`), the PC captures `next_pc`.

This behavior is often described with a clocked process and an `if / else` choice. We will write and explain that syntax together rather than hiding it in generated code.

## Proposed PC module interface

```text
Inputs:  clk, rst_n, next_pc[31:0]
Output:  pc[31:0]
```

The PC block does not calculate `pc + 4`; a separate combinational expression will calculate the next value and connect it back to `next_pc`. Separating the stored PC from its next-state calculation helps distinguish sequential from combinational logic.

## Expected behavior table

| At rising edge | `rst_n` | `next_pc` | Stored `pc` after edge |
|---|---:|---:|---:|
| Reset edge | 0 | any value | 0 |
| Normal edge | 1 | 4 | 4 |
| Normal edge | 1 | 8 | 8 |

Values between rising edges do not change the stored PC. For example, changing `next_pc` from 4 to 8 while `clk` is not at a rising edge does not immediately change `pc`.

## Learning check before writing this module

If reset is low at a rising edge while `next_pc` is 12, what value should the PC store? If reset is high at the next rising edge and `next_pc` is 4, what should it store? Explain why `next_pc` does not change the PC between edges.

The learner answered: the PC becomes 0 at the first edge because reset is asserted; at the next edge with reset released, it captures `next_pc` (4). `next_pc` alone cannot change stored PC state between edges because the clocked state element makes its update decision only at the rising edge. This checkpoint is complete.

## First coding exercise

Create only a `program_counter` module with `clk`, `rst_n`, and `next_pc[31:0]` inputs and a `pc[31:0]` output. The clocked block should reset `pc` to zero when `rst_n` is low at a rising edge; otherwise it should capture `next_pc`. Keep the `pc + 4` calculation outside this module for now. The learner should draft this small module, then review the SystemVerilog syntax and behavior together before adding it to the Vivado project.
