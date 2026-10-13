# How should the first test observe x5?

## Goal

The first test must determine whether `addi x5, x0, 7` worked. The PC and instruction bus are visible at the CPU boundary, but x5 is internal CPU state. We need to choose how the testbench observes that state.

## The decision is about the test boundary

A processor's architectural behavior is defined by its state and outputs over time. A physical CPU does not normally have an external pin for every internal register. In simulation, however, a testbench needs some way to check that the destination register received the expected value.

There are several reasonable ways to do that:

### Option A: hierarchical simulation-only observation

The testbench refers to the register storage inside the CPU instance by its hierarchy, for example conceptually “look at x5 inside this CPU instance.” This adds no debug port to the CPU interface and is simple for the first tiny test.

Tradeoff: the test depends on internal names and structure. If we rename or reorganize the register file, the test's observation path must change. This is acceptable for a first learning test if we clearly label it as a simulation probe rather than a hardware interface.

It is called **hierarchical** because a design is organized as nested scopes: a testbench can instantiate a CPU, and the CPU can instantiate a register-file module. A testbench reference can follow that tree using dot-separated instance names, conceptually `testbench.cpu.register_file.registers[5]`. If the register array lives directly inside the CPU module, one level is omitted, conceptually `testbench.cpu.registers[5]`. These names are examples only; we will choose actual module and signal names when we design the RTL.

### Option B: add a debug output

The CPU exposes a signal such as `debug_x5` or a selected-register debug read port. The testbench checks that output like any other port.

Tradeoff: this makes observation easier and visible at the top-level waveform, but adds a non-architectural debug interface to the CPU. A single fixed `debug_x5` port does not scale well; a selectable debug port adds more design logic and choices.

### Option C: verify through a program-visible effect

Once we support more instructions, a program can use x5 in another instruction and make the result visible through a defined output or memory behavior. A more developed CPU can also expose a standard retirement/trace interface.

Tradeoff: this checks behavior through the architecture rather than peeking inside, but it requires more instructions and hardware. It is more appropriate after the first instruction works.

## Recommendation for the first milestone

Use **Option A**, a clearly documented hierarchical simulation-only observation, for the first `ADDI` test. It keeps the CPU's hardware interface small while letting us inspect the register file before the CPU has enough instructions to reveal x5 through a program-visible effect. We should first design the register file so its internal state is understandable and inspectable in simulation.

Later, we can add program-level tests and decide whether a reusable debug/retirement interface is useful. The first test should not make `debug_x5` part of the CPU's permanent architectural interface by accident.

## Expected check

After reset has set PC to zero and one rising edge has executed `addi x5, x0, 7`, the test should observe x5 equal to 7 and PC equal to 4. It should also check that x0 still reads as zero. This checks the result and the CPU's basic sequential progression.

## Decision

Use **hierarchical simulation-only observation** for the first test. The testbench will inspect x5 inside the CPU after the instruction executes. This is a test-only observation path; it is not a permanent CPU hardware interface.
