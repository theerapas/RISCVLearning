# Development setup: SystemVerilog and simulation

## Goal

Be able to edit SystemVerilog, run a testbench, and inspect the CPU's behavior. We already have Vivado 2025.2 and VS Code, so this project does not need another simulator to get started.

## What each tool does

- **VS Code** is where we can edit `.sv` files and Markdown study notes. It is an editor; by itself it does not compile or simulate the CPU.
- **Vivado Simulator (XSim)** compiles the SystemVerilog design and testbench, runs the simulation, and shows signal waveforms. AMD's Vivado simulation guide documents SystemVerilog support and testbench-based simulation.
- **A VS Code SystemVerilog extension** is optional. It can add syntax highlighting, code navigation, and editor diagnostics, but it does not replace Vivado/XSim as the simulator.

## Minimum setup for this project

1. Keep Vivado 2025.2 installed with its Vivado Simulator component available.
2. Use Vivado to create or open the project and run **Behavioral Simulation** with a SystemVerilog testbench as the simulation top.
3. Edit the source in VS Code if preferred; add the same source files to the Vivado project so XSim compiles the files we are editing.
4. Optionally install a VS Code SystemVerilog language extension for highlighting and navigation. We can choose one after seeing whether VS Code already recognizes `.sv` files well enough.

We do not need to install Icarus Verilog, Verilator, Questa, GTKWave, a RISC-V toolchain, or an FPGA board for the first instruction-level simulation. Those may be useful later for particular learning goals, but adding them now would add setup work without helping the first `ADDI` test.

## Vivado project wizard choices

For the initial simulation-only project:

- Choose **RTL Project**.
- Since we have not written RTL yet, choose **Do not specify sources at this time** if that checkbox is offered. We can add design and testbench files after we create them.
- In the source-language options, choose **Verilog** as the target language; our `.sv` files will use SystemVerilog syntax based on their file type. **Mixed** is fine for simulator language.
- Skip constraints for now. Pin and timing constraints are needed when targeting and implementing a real FPGA board, not for the first behavioral simulation.
- Do not select a board unless we own that board and intend to target it. If the wizard allows the part to remain unspecified, leave it unspecified for now. If it requires a part, use an available placeholder only for simulation; we will need to select the actual FPGA part before synthesis/implementation.

## First setup check (before coding)

Open Vivado and confirm that **Behavioral Simulation** can launch and that the simulator window appears. This checks that XSim is installed and available. We can do this with a tiny temporary simulator example or when we create our first testbench; no CPU RTL is required to understand this check.

## Simulation vocabulary

- **Compile:** parse the HDL files and check their syntax and types.
- **Elaborate:** resolve module instances, parameters, and the simulation top into a runnable design.
- **Simulate:** advance simulated time while the testbench drives inputs and the design reacts.
- **Waveform:** a time-based view of signals such as `clk`, `rst_n`, `pc`, instruction, and register write data.
- **Behavioral simulation:** checks the RTL's logical behavior before synthesis or FPGA implementation.

For our CPU, a useful simulation will show the testbench instruction at the CPU's instruction input, PC at 0 before execution, and the expected state update after a rising clock edge.
