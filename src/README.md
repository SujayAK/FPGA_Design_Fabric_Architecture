# RTL Source and Verification Files

This directory contains the source Verilog HDL code, testbench, and constraint files developed during the **FPGA - Fabric, Design and Architecture** workshop.

## Directory Structure

```text
src/
├── rtl/
│   └── counter_clk_div.v       # 4-bit synchronous up-counter with 100MHz clock divider
├── tb/
│   └── tb_counter_clk_div.v    # Behavioral testbench for simulation verification
└── constraints/
    └── basys3_master.xdc       # Pin mapping and timing constraints for Digilent Basys 3
```

## Module Summary: `counter_clk_div.v`

- **Parameters**:
  - `DELAY_MAX` (Default: `212` for board implementation; set to `10` for fast waveform simulation).
- **Inputs**:
  - `clk`: Primary system clock (100 MHz onboard oscillator).
  - `rst`: Synchronous active-high reset.
- **Outputs**:
  - `counter_out [3:0]`: 4-bit binary counter output registered to `div_clk`.

## Verification in Vivado / Icarus Verilog

To run simulation via Icarus Verilog:
```bash
iverilog -o sim.out rtl/counter_clk_div.v tb/tb_counter_clk_div.v
vvp sim.out
```

In Xilinx Vivado:
1. Create a RTL Project and add `src/rtl/counter_clk_div.v` to Design Sources.
2. Add `src/tb/tb_counter_clk_div.v` to Simulation Sources.
3. Add `src/constraints/basys3_master.xdc` to Constraints.
4. Run Behavioral Simulation to view waveform transitions.
