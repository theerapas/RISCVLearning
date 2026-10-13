# First instruction contract: inputs, state, and reset

## Goal

Before writing the first RTL module, define the smallest CPU boundary and agree on reset behavior. Our first observable operation remains `addi x5, x0, 7`.

## What the CPU needs from its environment

The CPU needs a clock, a reset signal, and the instruction bits for its current PC. To keep the test program outside the CPU, use a simple instruction interface:

- `clk`: the clock. CPU state updates on its rising edge (`posedge clk`).
- `rst_n`: active-low reset; 0 means reset is asserted.
- `instr_addr`: address of the instruction the CPU wants to fetch. This is the current PC.
- `instr_rdata`: 32-bit instruction supplied by the testbench for `instr_addr`.

For this first simulation model, the testbench responds combinationally: while the CPU's address is 0, it supplies the 32-bit encoding of `addi x5, x0, 7`. Later, additional addresses can select additional test instructions. There is no ready/valid handshake or wait state in this simple interface.

## State update for the first instruction

The PC is state. During a cycle with PC equal to 0, the instruction input carries `addi x5, x0, 7`. Combinational logic decodes the instruction and calculates the result 7. On the rising clock edge, the CPU writes 7 into register x5 and sets the next PC to 4. The next address then selects the next test instruction.

The register file also stores state. Architectural x0 must always read as zero and must never change. Resetting the PC does not imply that every general-purpose register must have a specified value unless we decide that explicitly; for this project, initialize only state needed to define the first test and avoid implying a broader reset contract.

## Reset timing choices

Reset **polarity** and reset **timing** are separate:

- Active-low polarity means `rst_n == 0` asserts reset.
- A synchronous reset is acted on only at the active clock edge. It uses `always_ff @(posedge clk)` and tests `if (!rst_n)` inside the block.
- An asynchronous reset takes effect as soon as reset is asserted, independent of the clock edge. It uses both the clock edge and reset edge in the event control, such as `@(posedge clk or negedge rst_n)`.

Decision for this first learning CPU: use a **synchronous active-low reset**. It keeps the first sequential block focused on clocked state updates and avoids introducing asynchronous reset timing behavior before we need it. Reset sets the PC to 0 at a rising clock edge while `rst_n` is low. The testbench will hold reset low through a rising edge, then release it before a later rising edge.

## Proposed first CPU interface

```text
Inputs:  clk, rst_n, instr_rdata[31:0]
Outputs: instr_addr[31:0]
```

`instr_addr` exposes the PC to the testbench, which uses it to choose `instr_rdata`. Before RTL, we still need to decide whether we want a temporary way to observe x5 in the first test.

## Cycle trace

| Moment | PC | Instruction input | Effect |
|---|---:|---|---|
| Reset asserted at a rising edge | becomes 0 | ignored for state update | CPU starts from address 0 |
| Before the next rising edge | 0 | `addi x5, x0, 7` | decode and addition calculate 7 |
| At the next rising edge | changes to 4 | same instruction was active before edge | x5 receives 7; PC advances |
| After the edge | 4 | testbench selects instruction at address 4 | next instruction is ready for the following cycle |

The phrase “single cycle” means the instruction's combinational work fits between the edge that begins its cycle and the edge that commits its result. It does not mean that all internal logic changes at one instant.
