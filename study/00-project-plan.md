# Project plan: a small single-cycle RISC-V CPU

## What we are building

We are building a small processor in SystemVerilog for learning computer architecture. It will execute RISC-V instructions using a **single-cycle datapath**: the work for one instruction happens during one clock cycle, and the CPU commits that instruction's state changes at the active clock edge.

We will begin with a deliberately small milestone: execute `ADDI`, such as `addi x5, x0, 7`. Later, we can add more instructions in small groups. We will decide the exact instruction subset and hardware details as we reach each step, rather than silently assuming them now.

## How a processor runs an instruction

The CPU has state that persists between instructions. The most visible state is the **program counter (PC)**, which holds the address of the current instruction. The register file is also state: it holds the integer registers `x0` through `x31`.

For each instruction, the CPU uses the current PC to fetch an instruction, interprets its bit fields, reads any needed registers, computes a result, and decides what state should change. In a single-cycle design, these operations are connected by combinational logic and settle within the cycle. At the active clock edge, the CPU writes the result to a register (if required) and updates the PC. Then the next instruction begins from the new state.

For the first `ADDI` example, the intended behavior is:

1. Fetch the instruction at the current PC.
2. Decode that it is `ADDI`, with destination register `x5`, source register `x0`, and immediate value `7`.
3. Read `x0`. RISC-V defines `x0` to always read as zero.
4. Add the register value and immediate: `0 + 7 = 7`.
5. At the clock edge, write `7` to `x5` and advance the PC to the next sequential instruction. For the base 32-bit instruction in this first milestone, that means PC plus 4.

The result is that `x5` contains 7 after the edge. The instruction itself does not change other general-purpose registers.

## Main pieces we will learn

- **PC and next-PC logic:** selects which instruction address to use next. Sequential execution advances by four bytes for ordinary 32-bit instructions; branches will later require a different choice.
- **Instruction memory:** supplies the instruction bits for an address. For the initial simulation-focused design, we plan to use a combinational read, so the instruction is available during the same cycle. We will revisit this assumption if we target FPGA block RAM.
- **Instruction decoder and control:** interprets instruction fields and determines which operations and writes are needed.
- **Register file:** stores the integer registers. The architectural `x0` register always reads as zero, even if the internal implementation does not store it as ordinary writable state.
- **Immediate generation:** extracts and sign-extends constant values encoded in instructions.
- **ALU:** performs arithmetic and logic operations. The first milestone needs addition.
- **Data memory:** will be needed for load and store instructions, which are outside the first milestone.
- **Clock and reset:** define when state changes and the initial CPU state. We will explicitly choose reset behavior before implementing sequential logic.
- **Verification:** small tests will check observable behavior, beginning with whether executing `addi x5, x0, 7` leaves `x5` equal to 7 and advances the PC as specified.

## Learning sequence

Each step starts with a study note in this folder. We will read and discuss the concepts, agree on the behavior and interface, and only then make a small RTL change. We will explain and verify that change before moving forward.

1. **Instruction trace and contract:** understand `ADDI`, its RISC-V fields, the PC, and the clock-edge update. Confirm reset and instruction-memory assumptions.
2. **Combinational versus sequential logic:** learn what changes continuously with inputs and what changes only at a clock edge. Draw the first datapath before coding it.
3. **Small RTL building blocks:** implement and explain the PC, instruction source, register file behavior, immediate extraction, and adder in manageable pieces.
4. **Connect the first instruction:** add only the control and datapath needed for `ADDI`; follow the instruction from fetched bits to register writeback.
5. **Test and debug:** use a small testbench to check reset, execution, and register results. Learn to read waveforms and diagnose failures.
6. **Extend deliberately:** add instructions in groups (for example register-register arithmetic, then branches, then memory operations), with a written explanation and tests for each group.
7. **Measure and document:** once behavior is stable, explore synthesis or FPGA implementation and record what the reports mean. This is a later goal, not needed to understand the first CPU.

The sequence is a guide, not a commitment to implement every feature. We will keep the design focused on the learner's goals and revisit the plan when new choices arise.

## Working assumptions for the first milestone

- ISA family: RISC-V, 32-bit integer registers and 32-bit instructions for the initial subset.
- Initial instruction: `ADDI` only.
- Initial memory model: combinational instruction read for simulation and learning.
- The `x0` architectural register reads as zero.
- A normal 32-bit instruction advances the PC by four bytes.
- Reset details and the exact instruction-memory interface are still to be decided before writing sequential RTL.

## Questions to answer before the first RTL

- **PC reset value:** decided: reset sets the PC to address zero.
- **Instruction source:** decided for the first milestone: the testbench supplies the instruction in response to the CPU's instruction address. This keeps the CPU logic separate from the test program.
- **Clock edge:** decided: update CPU state on the rising edge (`posedge clk`). This is the common convention and makes the cycle boundary easy to describe.
- **Reset:** decided: synchronous active-low reset. `rst_n == 0` asserts reset, and the CPU acts on it at a rising clock edge.

For simulation, the testbench can hold reset active through a rising edge, release it before a later rising edge, let the CPU's combinational logic settle, and inspect results after the rising edge. The testbench does not need a falling-edge CPU to coordinate safely.

We will keep these decisions and their reasoning here so the implementation follows an explicit contract.
