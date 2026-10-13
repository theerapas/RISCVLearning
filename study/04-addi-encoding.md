# Encoding the first instruction: `addi x5, x0, 7`

## Goal

The testbench supplies a 32-bit instruction word to the CPU. Before writing RTL, learn how the assembly instruction `addi x5, x0, 7` is represented in those 32 bits, and what the CPU must extract from them.

## RISC-V I-type format

`ADDI` uses the RISC-V I-type instruction format:

| Bits | Field | Meaning for this instruction |
|---|---|---|
| `[31:20]` | `imm[11:0]` | 12-bit signed immediate: 7 |
| `[19:15]` | `rs1` | Source register 1: x0 |
| `[14:12]` | `funct3` | ADDI operation code within this format: `000` |
| `[11:7]` | `rd` | Destination register: x5 |
| `[6:0]` | `opcode` | Integer immediate operation: `0010011` (`0x13`) |

The instruction can be pictured as:

```text
31             20 19   15 14  12 11    7 6       0
+----------------+-------+------+-------+---------+
| imm[11:0]      | rs1   |funct3| rd    | opcode  |
+----------------+-------+------+-------+---------+
| 000000000111   | 00000 | 000  | 00101 | 0010011 |
+----------------+-------+------+-------+---------+
```

The 32-bit hexadecimal word is:

```text
0x00700293
```

The field values are placed at their bit positions and combined:

```text
(7      << 20)  = 0x00700000   immediate
(0      << 15)  = 0x00000000   rs1 = x0
(0      << 12)  = 0x00000000   funct3 = 000
(5      <<  7)  = 0x00000280   rd = x5
 0x13           = 0x00000013   opcode
                 ----------
                 0x00700293
```

This is the numeric 32-bit instruction value. If we later store this instruction as four bytes in little-endian memory, the byte order is `93 02 70 00`; the testbench's 32-bit instruction signal still carries `32'h00700293`.

## What the CPU extracts

The CPU decodes the `opcode` and `funct3` fields to recognize `ADDI`. It takes `rs1` to select x0, `rd` to select x5, and extracts `[31:20]` to form the immediate.

An I-type immediate is **sign-extended** from 12 bits to the CPU's 32-bit datapath: copy the immediate's sign bit (bit 11) into the new upper bits. For the positive value 7, bit 11 is 0, so the 32-bit result is `0x00000007`. Sign extension also lets a 12-bit immediate represent negative values, such as -1 (`12'hFFF` becomes `32'hFFFFFFFF`).

For this instruction, the ALU inputs are x0's value (`0`) and the sign-extended immediate (`7`). The ALU adds them, producing `7`. On the rising edge, the register file writes 7 to x5 and the PC advances from 0 to 4, assuming reset has already established PC=0.

## Why learn the encoding before coding

This lets us define a precise test stimulus and check each piece of decode logic against known fields. If the CPU produces a wrong result, we can inspect whether the testbench supplied the right instruction, whether the decoder extracted the intended fields, or whether the datapath computed incorrectly.

## Learning check before RTL

The learner identified `[11:7]` as the destination-register field. They correctly observed that the immediate must be widened because the calculation is 32 bits. More precisely, sign extension copies the immediate's sign bit into the new upper bits so its signed two's-complement value is preserved. For positive 7, the upper bits are zero. For `12'hFFF` (which means -1), the upper bits are all ones, producing `32'hFFFFFFFF`; zero extension would instead produce `32'h00000FFF` (4095).

This completes the instruction-encoding checkpoint.
