# Verifying the program counter

## Goal

Check the `program_counter` module on its own before connecting it to the instruction decoder or ALU. This isolates one behavior: the PC resets to zero when synchronous active-low reset is asserted, and otherwise captures `next_pc` only at a rising clock edge.

## What a testbench is

A testbench is a simulation-only SystemVerilog module that creates the environment around the design under test (DUT). For this PC test, the testbench will:

1. Instantiate `program_counter` as the DUT.
2. Generate a clock that alternates between low and high.
3. Drive `rst_n` and `next_pc` at deliberate times.
4. Observe `pc` in the waveform or check it with an assertion / conditional test.

The testbench is not synthesized into the CPU hardware. It is stimulus and observation code for simulation.

## Behavior to check

The main check is that state changes at the intended edge and reset has priority:

| Situation | Expected `pc` |
|---|---:|
| `rst_n` is low at a rising edge, even if `next_pc` is 12 | 0 |
| Reset is released and `next_pc` changes to 4 between edges | remains 0 until the next rising edge |
| The next rising edge occurs with `rst_n` high and `next_pc` equal to 4 | 4 |
| `next_pc` changes to 8 between edges | remains 4 until the next rising edge |
| The following rising edge occurs with `rst_n` high and `next_pc` equal to 8 | 8 |

These cases check three ideas separately: active-low reset, reset priority, and edge-triggered capture.

## Avoiding testbench races

The testbench should not change `rst_n` or `next_pc` at exactly the same simulation instant as a rising clock edge. Otherwise, the testbench and DUT may race over which value the DUT samples. A simple approach is to drive inputs while the clock is low, then allow the next rising edge to sample stable values. For checking, wait until the simulator has processed the edge and the nonblocking assignment update before comparing `pc`.

## Vivado workflow

1. Add a SystemVerilog file under **Simulation Sources** for the testbench.
2. Make the testbench the simulation top; the DUT remains a design source.
3. Run **Run Simulation → Run Behavioral Simulation** to launch XSim.
4. Add `clk`, `rst_n`, `next_pc`, and `pc` to the waveform and compare the trace with the table above.

We will create this testbench one concept at a time. First we need to understand the testbench structure; we should not add a full test or assertions without explaining what they do.

## Learning checkpoint before writing the testbench

The learner correctly explained that driving inputs while the clock is low avoids a race with the rising edge, and that `pc` should be inspected after the rising-edge update. More specifically, a clocked block using a nonblocking assignment schedules the new `pc` value in SystemVerilog's nonblocking-assignment event region; a testbench check in the same active event at `posedge clk` could run before that update. We should sample after it settles, such as later in the cycle.

This checkpoint is complete.

## First test sequence

We will write and understand a small, self-checking testbench in stages. Do not generate a large testbench all at once.

1. **Reset priority:** hold `rst_n` low and set `next_pc` to a nonzero value such as 12. At a rising edge, verify that `pc` becomes 0. This shows reset takes priority over `next_pc`.
2. **Capture next_pc:** release reset and set `next_pc` to 4 while the clock is low. Verify that `pc` is still 0 before the next rising edge. After that edge and the scheduled update settle, verify that `pc` is 4.
3. **Capture a later value:** set `next_pc` to 8 while the clock is low. Verify that `pc` remains 4 before the next edge, then becomes 8 after that edge settles.

These checks cover reset, edge-triggered capture, and the fact that input changes between edges do not directly alter stored state. We will implement the clock, DUT instance, stimulus, and checks one piece at a time, explaining the testbench syntax as we go.

## Result

The learner ran the testbench in Vivado/XSim and reported that it passed. The PC's synchronous reset, reset priority, and rising-edge capture behavior are verified for the tested values.

## Compile troubleshooting from the first testbench

The first XSim compile reported two useful issues:

- The testbench file was named `.v`, so Vivado parsed it as Verilog 2001. The SystemVerilog declaration type `logic` was then reported as unknown. Use a `.sv` filename or set that file's type to SystemVerilog in Vivado.
- Renaming the source to `.sv` did not fix the compile in this project because Vivado retained the file's explicit `Verilog` source-type metadata. In this case, set the file type to **SystemVerilog** in the Vivado Sources pane (or remove and re-add the `.sv` file so Vivado detects its type again), then rerun Behavioral Simulation. Confirm the compile log identifies it as SystemVerilog.
- One expected value was written as a binary literal containing digit 4 (`32'b4`). Binary literals can contain only binary digits 0 and 1 (plus unknown/high-impedance symbols); for decimal four use a decimal literal, or write its binary digits as `100`.

There was also a test-intent issue that did not cause the compile failure: before the edge that should capture 8, the test should fail if `pc` is not still 4. Comparing only whether it equals 8 does not detect every incorrect value (and can miss unknown values). Compare against the value that is expected at that point, using case inequality so an X value also fails the check.
