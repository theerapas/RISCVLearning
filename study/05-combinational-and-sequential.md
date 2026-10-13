# From ADDI calculation to clocked state

## Goal

Understand how the CPU can calculate an instruction's result during a cycle, then store it only at a clock edge. This distinction will guide the first RTL and help us predict its waveform.

## Two kinds of behavior

### Combinational logic

Combinational logic calculates outputs from current inputs. It has no memory of a previous cycle. If an input changes and signals settle, the output reflects the new input values.

Examples in the first CPU:

- Instruction fields extracted from `instr_rdata`.
- Sign-extended immediate calculated from the instruction bits.
- The adder result from register x0 and the immediate.
- The next sequential PC value (`pc + 4`).
- The testbench's instruction response selected from `instr_addr`.

### Sequential logic

Sequential logic stores state. Its state changes only at a clock edge, except when a design explicitly includes asynchronous controls. In our CPU, the PC and register file are state. We chose rising-edge updates with synchronous active-low reset.

At a rising edge while `rst_n` is low, the PC becomes 0. At a rising edge with reset released, the CPU commits the current instruction's state changes: for ADDI, write the calculated value to `rd` and update the PC.

## The first instruction's path through one cycle

```text
                         combinational calculations
                    +-----------------------------------+
                    |                                   v
PC state -> instruction address -> instruction -> decode/read x0
   |                                                       |
   |                                                       v
   |                                              sign-extend imm=7
   |                                                       |
   |                                                       v
   |                                                    ALU: 0+7
   |                                                       |
   |                                                       v
   +-- PC+4 --------------------------------------> next-state choices
                                                           |
                                      rising clock edge    v
                                      +--------------------+
                                      | PC <- 4, x5 <- 7
                                      +--------------------+
```

The diagram separates **calculation** from **commit**. Before the edge, signals may settle to show next-state values. The edge is when the stored PC and register values change.

## Why testbench timing matters

The testbench should avoid changing `instr_rdata` at the exact same rising edge when the CPU samples it. For the simple combinational instruction source, it can set up the instruction based on the current address ahead of the edge. After the edge, it can wait a small simulation delay or a simulator scheduling step before checking updated state. This avoids a race where the test and CPU try to read/write at the same instant.

We will choose an explicit testbench timing pattern when we write the test. At the architecture level, the required contract is that the instruction for the current PC is stable before the active edge.

## Design decisions currently established

- CPU state updates on `posedge clk`.
- Reset is synchronous and active low (`rst_n` low is asserted, handled on a rising edge).
- Reset sets PC to address 0.
- The testbench supplies `instr_rdata` combinationally for the current `instr_addr`.
- For `ADDI`, the register write and PC+4 update commit on the rising edge after combinational logic has calculated them.

## Learning checkpoint before RTL

The learner correctly traced the instruction read, immediate sign extension, ALU calculation, PC+4 calculation, and rising-edge updates. One terminology clarification: in `addi x5, x0, 7`, `x5` is the **destination**, not an ALU input. The ALU adds the value read from source register `x0` (zero) to immediate 7. The result 7 is written to destination register `x5` at the rising edge.

This completes the combinational-versus-sequential checkpoint.
