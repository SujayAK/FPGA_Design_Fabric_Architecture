# FPGA Architecture, Fabric Exploration & Implementation Flow

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![FPGA Target](https://img.shields.io/badge/FPGA-Artix--7%20Basys%203-orange.svg)]()
[![Process Node](https://img.shields.io/badge/PDK-SkyWater%20130nm-green.svg)]()
[![EDA Tools](https://img.shields.io/badge/EDA-Vivado%20%7C%20VTR%20%7C%20OpenFPGA-purple.svg)]()
[![Author](https://img.shields.io/badge/Author-Sujay%20Kandalkar-informational.svg)]()

> A comprehensive technical investigation into FPGA fabric architecture, design methodologies, and implementation toolchains. This work documents complete flows from RTL to Bitstream using both industry-standard commercial tools (Xilinx Vivado for Artix-7) and cutting-edge open-source EDA platforms (OpenFPGA, VTR/VPR, and SkyWater 130nm SOFA fabric), culminating in the deployment of a 4-stage pipelined RISC-V RV32I processor core (`RVMYTH`).

---

## Table of Contents

- [Architectural Overview](#architectural-overview)
  - [FPGA vs. ASIC Architectural Trade-offs](#fpga-vs-asic-architectural-trade-offs)
  - [Island-Style FPGA Architecture](#island-style-fpga-architecture)
- [Workshop Roadmap & Methodology](#workshop-roadmap--methodology)
  - [Day 1 - FPGA Architectural Foundations & Xilinx Vivado Flow](#day-1---fpga-architectural-foundations--xilinx-vivado-flow)
  - [Day 2 - Open-Source CAD Toolchains: OpenFPGA, VPR & VTR Flow](#day-2---open-source-cad-toolchains-openfpga-vpr--vtr-flow)
  - [Day 3 - RISC-V RV32I Core (RVMYTH) Implementation in Vivado](#day-3---risc-v-rv32i-core-rvmyth-implementation-in-vivado)
  - [Day 4 - SkyWater 130nm SOFA Open-Source FPGA Fabric Exploration](#day-4---skywater-130nm-sofa-open-source-fpga-fabric-exploration)
  - [Day 5 - Full-Flow RVMYTH RISC-V Mapping on Custom SOFA Fabric](#day-5---full-flow-rvmyth-risc-v-mapping-on-custom-sofa-fabric)
- [Repository Structure](#repository-structure)
- [References](#references)
- [Acknowledgements](#acknowledgements)

---

## Architectural Overview

Field-Programmable Gate Arrays (FPGAs) are semiconductor devices based on a matrix of Configurable Logic Blocks (CLBs) connected via programmable interconnects. Unlike Application-Specific Integrated Circuits (ASICs), where circuits are permanently etched into silicon during fabrication, FPGAs offer reconfigurability after manufacturing, making them indispensable for prototyping, high-throughput DSP, software-defined networking, and agile hardware acceleration.

### FPGA vs. ASIC Architectural Trade-offs

| Engineering Metric | Field-Programmable Gate Array (FPGA) | Application-Specific Integrated Circuit (ASIC) |
| :--- | :--- | :--- |
| **Circuit Implementation** | SRAM-programmed lookup tables (LUTs) & routing switches | Custom silicon masks (standard cells & full custom) |
| **Development Turnaround** | Minutes to hours (RTL to Bitstream) | Months to years (RTL to GDSII to Fab) |
| **Non-Recurring Engineering (NRE)** | Minimal; standard off-the-shelf silicon | Extremely high ($100k - $10M+ for masks) |
| **Unit Cost at Scale** | Higher per chip for massive production volumes | Very low at high volumes ($1 - $10M units) |
| **Silicon Efficiency** | Overhead due to configuration SRAM & routing switches | Maximum logic density per mm² silicon area |
| **Operating Frequency ($f_{MAX}$)** | Typically 50 MHz – 500 MHz | Can exceed 1 GHz – 3+ GHz |
| **Power Efficiency** | Higher static and dynamic power per operation | Highly optimized for ultra-low power consumption |
| **Post-Silicon Flexibility** | Full remote in-field reconfigurability & feature updates | Hardware is fixed; requires new silicon spin |

### Island-Style FPGA Architecture

Modern commercial and open-source FPGAs adhere to an **island-style (mesh-based)** topology. In this architecture, logic clusters are organized as a 2D regular grid surrounded by vertical and horizontal routing channels.

```
       +-------+      +-------+      +-------+
       |  IOB  |      |  IOB  |      |  IOB  |
       +---v---+      +---v---+      +---v---+
           |              |              |
+-----+----+--------------+--------------+----+-----+
| IOB |--[ SB ]--------- [ SB ]--------- [ SB ]--| IOB |
+-----+    |              |              |    +-----+
           |   +------+   |   +------+   |
         [ CB ]|  CLB | [ CB ]|  CLB | [ CB ]
           |   +------+   |   +------+   |
+-----+----+--------------+--------------+----+-----+
| IOB |--[ SB ]--------- [ SB ]--------- [ SB ]--| IOB |
+-----+    |              |              |    +-----+
           |              |              |
       +---^---+      +---^---+      +---^---+
       |  IOB  |      |  IOB  |      |  IOB  |
       +-------+      +-------+      +-------+
```

An island-style architecture primarily consists of:
1. **Configurable Logic Blocks (CLBs)**: The fundamental computational element, containing Look-Up Tables (LUTs) for arbitrary boolean logic, dedicated carry chains (`CARRY4`) for arithmetic, multiplexers, and flip-flops/latches.
2. **Connection Blocks (CB)**: Connect logic block inputs/outputs to adjacent routing channels.
3. **Switch Blocks (SB)**: Programmable switch matrices positioned at channel intersections to route nets across orthogonal tracks.
4. **Input/Output Blocks (IOBs)**: Configurable I/O pads supporting diverse voltage standards (LVCMOS, LVDS, etc.).

<p align="center">
  <img src="images/fpga_arch_1.png" alt="FPGA Interconnect and Grid Architecture" width="700"/>
  <br>
  <em>Figure 1: Island-style FPGA grid showing logic clusters, routing channels, and switch matrices.</em>
</p>

### Configurable Logic Block (CLB) Sub-Architecture

Inside each CLB:
- **$K$-input Look-Up Tables ($K$-LUTs)**: Implement any $K$-variable boolean function as a truth table stored in SRAM cells.
- **Dedicated Carry Logic**: Fast lookahead carry generators enabling low-latency adders and counters.
- **Sequential Elements**: Configurable D flip-flops with synchronous/asynchronous set, reset, and clock enable controls.

<p align="center">
  <img src="images/fpga_arch_2.png" alt="CLB Internal Microarchitecture" width="600"/>
  <br>
  <em>Figure 2: Microarchitecture of a Configurable Logic Block (LUTs, MUXes, Flip-Flops).</em>
</p>

---

## Workshop Roadmap & Methodology

This project presents a multi-stage exploration of modern FPGA flows:
- **Day 1**: Commercial FPGA exploration on Digilent Basys 3 using Xilinx Vivado.
- **Day 2**: Open-source EDA tools (OpenFPGA, VPR, and VTR flow) with timing and power analysis.
- **Day 3**: RTL-to-Bitstream compilation of a 4-stage pipelined RISC-V processor (`RVMYTH`).
- **Day 4**: Open-source SkyWater 130nm SOFA fabric exploration.
- **Day 5**: End-to-end mapping of the RISC-V processor onto custom SOFA silicon.

---

## Day 1 - FPGA Architectural Foundations & Xilinx Vivado Flow

The primary goal of Day 1 is to master the commercial FPGA design cycle using the **Digilent Basys 3** development platform powered by the **Xilinx Artix-7 (XC7A35T-1CPG236C)** FPGA.

### Target Hardware: Digilent Basys 3

The Basys 3 is an entry-level development board designed specifically around the Artix-7 architecture:
- **Logic Cells**: 33,280 (in 5,200 slices; each slice containing four 6-input LUTs and eight flip-flops)
- **Fast Block RAM**: 1,800 Kbits
- **Clock Management Tiles (CMT)**: 5 (each containing a PLL and Mixed-Mode Clock Manager - MMCM)
- **DSP Slices**: 90 (18 x 25 multiplier blocks)
- **Internal Clock Speed**: Exceeding 450 MHz

<p align="center">
  <img src="images/basys3_board.png" alt="Basys 3 Development Board Hardware Overview" width="750"/>
  <br>
  <em>Figure 3: Digilent Basys 3 Artix-7 Board Hardware Peripherals and Pin Assignment Map.</em>
</p>

#### Hardware Peripheral Map

| Callout | Peripheral Component | Callout | Peripheral Component |
| :---: | :--- | :---: | :--- |
| **01** | Power Good Indicator LED | **09** | FPGA System Reset Button |
| **02** | Pmod Header Group A | **10** | Programming Mode Jumper |
| **03** | Pmod Header Group B | **11** | FTDI USB-JTAG / UART Interface |
| **12** | 12-bit VGA Display Port | **04** | Four-Digit 7-Segment Display |
| **13** | USB Host Interface (HID) | **05** | 16 Slide Switches (SW0 - SW15) |
| **14** | External 5V Power Connector | **06** | 16 User LEDs (LD0 - LD15) |
| **15** | Main Power Switch | **07** | 5 Pushbuttons (Center, U, D, L, R) |
| **16** | Power Source Select Jumper | **08** | FPGA Configuration Done LED |

---

### RTL Design: 4-Bit Synchronous Counter with Clock Division

Because the onboard oscillator generates a high-frequency **100 MHz clock** ($T = 10 \text{ ns}$), driving an LED counter directly would cause state transitions faster than human visual persistence. A clock division module is implemented in Verilog to generate an observable low-frequency clock.

```verilog
`timescale 1ns / 1ps

module counter_clk_div #(
    parameter integer DELAY_MAX = 212
)(
    input  wire       clk,
    input  wire       rst,
    output reg  [3:0] counter_out
);
    reg        div_clk;
    reg [25:0] delay_count;

    // Clock division logic
    always @(posedge clk) begin
        if (rst) begin
            delay_count <= 26'd0;
            div_clk     <= 1'b0;
        end else begin
            if (delay_count == DELAY_MAX) begin
                delay_count <= 26'd0;
                div_clk     <= ~div_clk;
            end else begin
                delay_count <= delay_count + 1'b1;
            end
        end
    end

    // 4-bit synchronous up-counter
    always @(posedge div_clk) begin
        if (rst) begin
            counter_out <= 4'b0000;
        end else begin
            counter_out <= counter_out + 1'b1;
        end
    end
endmodule
```

The mathematical relationship governing the divided frequency is:
$$f_{\text{div}} = \frac{f_{\text{in}}}{2 \times (\text{DELAY\_MAX} + 1)}$$

---

### Behavioral Simulation & RTL Elaboration

1. **Behavioral Simulation**: Verifies the functional correctness of the RTL before physical synthesis. The counter increments predictably on rising edges of `div_clk`, and resets synchronously when `rst` is asserted.

<p align="center">
  <img src="images/d1_counter_div_sim.png" alt="Behavioral Simulation Waveform" width="750"/>
  <br>
  <em>Figure 4: Vivado Behavioral Simulation verifying clock division and sequential counter counting.</em>
</p>

2. **RTL Elaboration**: Resolves Verilog hierarchies, instantiates primitives, checks connectivity, and builds the generic logical structure without technology-specific mapping.

<p align="center">
  <img src="images/d1_counter_div_elaborate_schematic.png" alt="Elaborated RTL Schematic" width="750"/>
  <br>
  <em>Figure 5: Elaborated Gate-Level Schematic of the counter and clock divider module.</em>
</p>

3. **I/O Planning**: Maps top-level module ports (`clk`, `rst`, `counter_out[3:0]`) to physical FPGA pins on the CPG236 package with appropriate I/O standards (`LVCMOS33`).

<p align="center">
  <img src="images/d1_counter_div_elaborate_io_planning.png" alt="Vivado I/O Planning and Pin Assignment" width="750"/>
  <br>
  <em>Figure 6: Vivado I/O Planning assigning ports to Artix-7 package pads.</em>
</p>

---

### Logic Synthesis & Constraints

Logic synthesis transforms the elaborated generic logic into an optimal gate-level netlist using target Artix-7 primitives (`LUT6`, `FDRE`, `CARRY4`, `IBUF`, `OBUF`).

<p align="center">
  <img src="images/d1_counter_div_synthesis_schematic.png" alt="Synthesized Gate-Level Schematic" width="750"/>
  <br>
  <em>Figure 7: Synthesized netlist mapped to Xilinx Artix-7 technology primitives.</em>
</p>

#### Timing Constraints (`basys3_master.xdc`)
Constraints specify the physical and timing boundaries of the design, ensuring proper setup and hold slack closure:
```tcl
## 100 MHz Master System Clock Constraint (10 ns period)
set_property PACKAGE_PIN W5 [get_ports clk]							
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset Pin Mapping
set_property PACKAGE_PIN V17 [get_ports rst]					
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## 4-bit Counter Output Pin Mapping (LEDs LD0 - LD3)
set_property PACKAGE_PIN U16 [get_ports {counter_out[0]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {counter_out[0]}]
set_property PACKAGE_PIN E19 [get_ports {counter_out[1]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {counter_out[1]}]
set_property PACKAGE_PIN U19 [get_ports {counter_out[2]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {counter_out[2]}]
set_property PACKAGE_PIN V19 [get_ports {counter_out[3]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {counter_out[3]}]
```

---

### Implementation, Timing Closure & Power Analysis

Physical implementation translates the synthesized netlist into the target FPGA fabric across three major phases:
1. **Logic Optimization (`opt_design`)**: Prunes unused logic and optimizes constant nets.
2. **Placement (`place_design`)**: Assigns logic primitives to specific CLB slices in the silicon floorplan.
3. **Routing (`route_design`)**: Allocates routing tracks and programmable interconnect switches.

#### Post-Implementation Timing Summary
The design comfortably satisfies all timing requirements:
- **Worst Negative Slack (WNS)**: Positive slack ($\gg 0\text{ ns}$), indicating zero setup violations.
- **Worst Hold Slack (WHS)**: Positive slack, confirming zero hold-time violations.

<p align="center">
  <img src="images/d1_counter_div_implementation_timing_summary.png" alt="Implementation Timing Summary" width="750"/>
  <br>
  <em>Figure 8: Post-Implementation Timing Summary showing positive timing margins.</em>
</p>

#### Resource Utilization
Device utilization shows minimal hardware consumption, leaving over 99% of Artix-7 resources available for additional logic:

<p align="center">
  <img src="images/d1_counter_div_implementation_utilization.png" alt="Device Utilization Summary" width="750"/>
  <br>
  <em>Figure 9: Artix-7 Device Utilization Summary (LUTs, FFs, I/O Buffers).</em>
</p>

#### On-Chip Power Dissipation
Total on-chip power is partitioned into:
- **Static Power**: Leakage power inherent to biased silicon transistors.
- **Dynamic Power**: Power consumed due to capacitive charging/discharging during signal transitions:
  $$P_{\text{dynamic}} = \alpha \cdot C_L \cdot V_{DD}^2 \cdot f$$

<p align="center">
  <img src="images/d1_counter_div_implementation_power.png" alt="On-Chip Power Analysis Report" width="750"/>
  <br>
  <em>Figure 10: On-chip power breakdown generated by Vivado Power Analyzer.</em>
</p>

---

### In-System Debugging: Virtual Input/Output (VIO)

In complex FPGA designs without sufficient physical switches or LEDs, the **Virtual Input/Output (VIO)** core provides an on-chip debugging interface. The VIO core runs directly in FPGA logic and communicates over the JTAG boundary scan chain, allowing designers to dynamically drive input signals and monitor internal registers via Vivado Hardware Manager in real time without recompilation.

---

## Day 2 - Open-Source CAD Toolchains: OpenFPGA, VPR & VTR Flow

Day 2 transitions from proprietary commercial environments to the open-source EDA ecosystem. Open-source flows provide unprecedented transparency into physical silicon mapping, enable academic research into novel architectures, and dramatically reduce the design cycle for customized FPGA IP cores.

### The OpenFPGA Framework

**OpenFPGA** is the world's first open-source FPGA IP generator supporting highly customizable homogeneous and heterogeneous FPGA architectures. Key features include:
- **Architectural Scalability**: Enables chip designers to specify custom logic blocks, routing channels, and memory tiles using XML-based architectures.
- **Rapid Prototyping Cycle**: Shrinks custom FPGA development cycles from months down to a few days.
- **Full EDA Support**: Generates synthesizable Verilog for the fabric, SPICE netlists for circuit-level characterization, and bitstream generation toolchains.

<p align="center">
  <img src="images/openfpga_framework.png" alt="OpenFPGA Framework Architecture Flow" width="700"/>
  <br>
  <em>Figure 11: The OpenFPGA Framework architecture from HDL to silicon implementation.</em>
</p>

---

### Versatile Place and Route (VPR)

**VPR** is the academic standard CAD engine for exploring FPGA architectures and physical algorithms:
1. **Inputs**:
   - Architectural Description (`EArch.xml`): Defines routing channel widths, switch box topologies, and CLB cluster parameters.
   - Technology-Mapped User Circuit (`.blif`): Generated by upstream synthesis tools.
2. **CAD Pipeline**:
   - **Packing (T-VPack)**: Clusters LUTs and registers into logic blocks based on affinity and timing criticality.
   - **Placement (Simulated Annealing)**: Finds global optimal positions for clusters on the 2D FPGA grid to minimize total bounding-box wirelength.
   - **Routing (Pathfinder Negotiated Congestion)**: Iteratively routes nets over available tracks; shared tracks accrue congestion costs until all overlaps resolve.
3. **Outputs**:
   - Bitstream configuration data, critical path delay ($t_{clk}$), setup/hold slack, and channel routing utilization.

<p align="center">
  <img src="images/vpr_1.png" alt="VPR CAD Engine Execution" width="650"/>
  <br>
  <em>Figure 12: VPR CAD Flow: Architecture description and circuit netlist to placed & routed FPGA fabric.</em>
</p>

#### Invoking VPR via Command Line
```bash
$VTR_ROOT/vpr/vpr \
  $VTR_ROOT/vtr_flow/arch/timing/EArch.xml \
  <path_to_circuit>.blif \
  --route_chan_width 100 \
  --disp on
```

---

### Verilog-to-Routing (VTR) Flow

The **VTR Project** integrates front-end synthesis, optimization, and physical design into an end-to-end open-source pipeline:

```
  +-------------------------+
  |  Verilog RTL (.v)       |
  +------------+------------+
               |
               v
  +-------------------------+
  |  Odin II (Elaboration)  |
  +------------+------------+
               |
               v
  +-------------------------+
  |  ABC (Logic & LUT Map)  |
  +------------+------------+
               |
               v
  +-------------------------+
  |  VPR (Pack, Place, Route|
  |       STA & Power)      |
  +-------------------------+
```

1. **Odin II**: Synthesizes synthesizable Verilog HDL into a flat Berkeley Logic Interchange Format (`.blif`) netlist.
2. **ABC**: Optimizes combinational logic using AIGs (And-Inverter Graphs) and maps boolean networks to target $K$-input LUTs.
3. **VPR**: Performs cluster packing, simulated annealing placement, negotiated congestion routing, and static timing analysis.

#### Running the Unified VTR Flow
```bash
$VTR_ROOT/vtr_flow/scripts/run_vtr_flow.py \
  $VTR_ROOT/doc/src/<circuit>.v \
  $VTR_ROOT/vtr_flow/arch/timing/EArch.xml \
  -temp_dir . \
  --route_chan_width 100 \
  --gen_post_synthesis_netlist on \
  -power \
  -cmos_tech $VTR_ROOT/vtr_flow/tech/PTM_45nm/45nm.xml
```

---

### VTR Floorplan & Interconnect Visualizations

VPR provides interactive graphical inspection of physical implementation metrics:

| Critical Paths | Physical Signal Nets |
| :---: | :---: |
| <img src="images/vtr_flow__toggle_critical_paths.png" width="380"/> | <img src="images/vtr_flow__toggle_nets__nets.png" width="380"/> |
| **Logical Interconnect Connections** | **Channel Routing Utilization Heatmap** |
| <img src="images/vtr_flow__toggle_nets__logical_connections.png" width="380"/> | <img src="images/vtr_flow__routing_utilization.png" width="380"/> |

*Figure 13: VPR graphical floorplan views: Critical timing paths, net topology, logical connections, and routing channel density.*

---

### Static Timing Analysis in VTR Flow

Timing analysis requires a Synopsys Design Constraint (`.sdc`) file specifying clock targets and I/O delays:
```tcl
create_clock -period 10.000 -name clk [get_ports {clk}]
set_input_delay -clock clk -max 0.5 [get_ports {rst}]
```

Running timing analysis generates detailed reports for setup and hold timing:
- **Setup Timing**: Confirms data arrives before the latching clock edge ($t_{\text{arrival}} \le t_{\text{required}}$).
- **Hold Timing**: Confirms data remains stable after the active clock edge ($t_{\text{hold\_arrival}} \ge t_{\text{hold\_required}}$).

| Setup Timing Analysis | Hold Timing Analysis |
| :---: | :---: |
| <img src="images/vtr_flow_counter_setup_timing.png" width="380"/> | <img src="images/vtr_flow_counter_hold_timing.png" width="380"/> |

*Figure 14: VTR Flow Setup and Hold Timing Analysis reports confirming non-negative timing slacks.*

---

### Post-Synthesis Netlist Generation & Verification

VTR can generate a post-synthesis Verilog netlist containing technology-mapped primitives and delay annotations:
```bash
--gen_post_synthesis_netlist on
```

The resulting netlist is back-annotated and simulated within Vivado Simulator to guarantee cycle-accurate behavioral equivalence with the original RTL.

| Post-Synthesis Netlist Snippet 1 | Post-Synthesis Netlist Snippet 2 |
| :---: | :---: |
| <img src="images/vtr_flow_post_synthesis_netlist_1.png" width="380"/> | <img src="images/vtr_flow_post_synthesis_netlist_2.png" width="380"/> |

<p align="center">
  <img src="images/d2_counter_post_synthesis_simulation.png" alt="Post-Synthesis Simulation Waveform" width="750"/>
  <br>
  <em>Figure 15: Post-synthesis behavioral simulation verifying functional integrity of the VTR netlist.</em>
</p>

---

### Power Analysis in VTR

Using the **45nm Predictive Technology Model (PTM)**, VTR models:
- **Routing Power**: Dynamic power consumed by routing switches, buffers, and interconnect wire capacitance.
- **Logic Power**: Dynamic switching power in LUTs, DFFs, and local multiplexers.
- **Static Leakage Power**: Subthreshold and gate-oxide leakage currents across unconfigured and configured tiles.

<p align="center">
  <img src="images/vtr_flow_counter_power.png" alt="VTR Power Analysis Summary" width="700"/>
  <br>
  <em>Figure 16: VTR detailed power estimation breakdown across routing fabric and logic elements.</em>
</p>

---

## Day 3 - RISC-V RV32I Core (RVMYTH) Implementation in Vivado

Day 3 scales design complexity from a simple counter to a full **32-bit RISC-V microprocessor core**, named **RVMYTH**. RVMYTH is a 4-stage pipelined processor implementing the standard RV32I base integer instruction set.

### Processor Microarchitecture

The RVMYTH core features a classic 4-stage pipeline:
1. **Instruction Fetch (IF)**: Computes next PC and retrieves 32-bit instruction words from instruction memory.
2. **Instruction Decode (ID)**: Decodes opcode, funct3, and funct7 fields; reads source operands from the 32-register integer register file (`x0` - `x31`).
3. **Execute (EX)**: Executes arithmetic, logical, shift, and branch comparisons via the ALU; computes memory addresses.
4. **Writeback (WB)**: Writes ALU results or load data back into the destination register `rd`.

The core was originally specified in **Transaction-Level Verilog (TL-Verilog)**—an emerging high-level hardware description language that eliminates explicit pipeline staging registers and reduces pipeline hazards—and subsequently transpiled into standard synthesizable Verilog HDL.

---

### Behavioral Simulation: Summation Benchmark

The processor is pre-loaded with an instruction routine that calculates the cumulative sum of integers from $1$ to $9$:
$$\sum_{i=1}^{9} i = \frac{9 \times 10}{2} = 45 \quad (\text{0x0000002D})$$

Simulating the core in Vivado demonstrates sequential instruction execution, branch evaluation, and register updates until the output register converges to `45`.

<p align="center">
  <img src="images/d3_rvmyth_sim.png" alt="RVMYTH Behavioral Simulation" width="750"/>
  <br>
  <em>Figure 17: Vivado Behavioral Simulation of RVMYTH executing the 1-to-9 summation program.</em>
</p>

---

### RTL Elaboration & Hardware Telemetry (ILA)

During elaboration, top-level clock, reset, and probe nets are bound to package pins. To enable real-time hardware telemetry without physical oscilloscope probes, an **Integrated Logic Analyzer (ILA)** core is instantiated alongside the processor:

| Standard Elaborated Core | Elaborated Core with Integrated Logic Analyzer (ILA) |
| :---: | :---: |
| <img src="images/d3_elaborate_rvmyth.png" width="380"/> | <img src="images/d3_elaborate_rvmyth_with_ila.png" width="380"/> |

*Figure 18: Elaborated RTL schematics: Standard processor core (left) and core instrumented with Xilinx ILA IP (right).*

---

### Logic Synthesis on Artix-7

The design is synthesized using the Vivado Synthesis tool targeting the Artix-7 `xc7a35tcpg236-1` device. Combinational functions map to 6-input LUTs (`LUT6`), and pipelined registers map to flip-flop primitives (`FDRE`).

| Synthesized Processor Schematic | Synthesis Configuration & Timing Metrics |
| :---: | :---: |
| <img src="images/d3_rvmyth_synth_sch.png" width="380"/> | <img src="images/d3_rvmyth_synth.png" width="380"/> |

*Figure 19: Technology-mapped gate-level schematic and synthesis constraints for the RVMYTH RISC-V core.*

---

### Physical Implementation: Placement, Routing & Timing Closure

During implementation, the synthesized netlist is placed onto the physical die and interconnect tracks are routed through switch matrices.

| Placed & Routed Die Layout | Detailed Slice & Interconnect Routing |
| :---: | :---: |
| <img src="images/d3_rvmyth_impl_design.png" width="380"/> | <img src="images/d3_rvmyth_impl_design2.png" width="380"/> |

*Figure 20: Physical die implementation in Vivado Device View showing placement of ALU, registers, and interconnect routing.*

#### Post-Implementation Timing Summary
All setup and hold timing paths meet the required specifications with zero setup or hold violations:

<p align="center">
  <img src="images/d3_rvmyth_impl_design_timing.png" alt="RVMYTH Implementation Timing Summary" width="750"/>
  <br>
  <em>Figure 21: Post-Implementation Timing Summary verifying positive slack across the processor core.</em>
</p>

#### Device Resource Utilization
The processor consumes modest resources on the XC7A35T die, leaving abundant room for coprocessors or hardware accelerators:

<p align="center">
  <img src="images/d3_rvmyth_impl_design_utilization.png" alt="RVMYTH Resource Utilization" width="750"/>
  <br>
  <em>Figure 22: Hardware utilization report (LUTs, Slice Registers, F7/F8 MUXes) on Artix-7.</em>
</p>

#### Power Dissipation Analysis
Dynamic power dissipation accounts for pipeline activity, while static leakage is minimal on the 28nm Artix-7 process:

<p align="center">
  <img src="images/d3_rvmyth_impl_design_power.png" alt="RVMYTH Power Analysis" width="750"/>
  <br>
  <em>Figure 23: On-chip power analysis report for the implemented RVMYTH RISC-V processor.</em>
</p>

---

## Day 4 - SkyWater 130nm SOFA Open-Source FPGA Fabric Exploration

Day 4 introduces **SOFA (Skywater Opensource FPGAs)**—a family of open-source FPGA IP cores designed using the open-source **SkyWater 130nm PDK** and the **OpenFPGA** IP generation framework.

### SOFA Architecture: `FPGA1212_QLSOFA_HD_PNR`

The specific fabric used is the `FPGA1212_QLSOFA_HD_PNR` IP core, tailored for low-cost IoT, embedded control, and academic research:
- **Semiconductor Process**: SkyWater 130nm CMOS High-Density (`sky130_fd_sc_hd`) standard cell library.
- **Maximum Operating Frequency**: $50 \text{ MHz}$.
- **Logic Elements**: 1,152 Look-Up Tables (LUTs).
- **Sequential Storage**: 2,304 D Flip-Flops (DFFs).
- **Arithmetic Blocks**: 1,152 Soft Adders.
- **Configuration Mechanism**: Shift-register based configuration chain allowing bitstream loading without external flash controllers.

<p align="center">
  <img src="images/d4_sofa_intro.png" alt="SOFA OpenFPGA Architecture Introduction" width="700"/>
  <br>
  <em>Figure 24: High-level architectural floorplan and tile topology of the SOFA 130nm FPGA IP.</em>
</p>

---

### Counter Implementation on SOFA Fabric

The 4-bit clock-divided counter is synthesized, packed, placed, and routed targeting the `FPGA1212_QLSOFA_HD_PNR` fabric using OpenFPGA and VTR.

#### 1. Area & Silicon Utilization
The report below quantifies total silicon area, cell count, and logic block occupancy within the SOFA fabric:

<p align="center">
  <img src="images/d4_sofa_area.png" alt="SOFA Counter Area Utilization" width="700"/>
  <br>
  <em>Figure 25: Logic utilization and silicon area report for the counter on the SOFA SkyWater 130nm fabric.</em>
</p>

#### 2. Setup & Hold Timing Analysis
Timing analysis verifies that both setup and hold constraints are met at the target operating frequency:
- **Setup Timing**: Confirms data arrival meets the setup threshold across all clock domains.
- **Hold Timing**: Confirms internal register transfers maintain positive hold slack, preventing race conditions.

| SOFA Setup Timing Slack | SOFA Hold Timing Slack |
| :---: | :---: |
| <img src="images/d4_sofa_timing_setup.png" width="380"/> | <img src="images/d4_sofa_timing_hold.png" width="380"/> |

*Figure 26: Setup and Hold slack reports for the counter implemented on SOFA 130nm fabric.*

#### 3. Post-Implementation Simulation Verification
A post-implementation Verilog simulation model generated by OpenFPGA (including interconnect parasitic RC delays) is simulated in Vivado to confirm that hardware timing delays do not induce functional glitches:

<p align="center">
  <img src="images/d4_sofa_post_impl_sim.png" alt="SOFA Counter Post-Implementation Simulation" width="750"/>
  <br>
  <em>Figure 27: Post-implementation simulation waveform confirming glitch-free counter operation on SOFA.</em>
</p>

#### 4. Power Dissipation on 130nm Fabric
Power analysis models total static and dynamic power for the counter running on the SkyWater 130nm process:

<p align="center">
  <img src="images/d4_sofa_power.png" alt="SOFA Counter Power Dissipation" width="700"/>
  <br>
  <em>Figure 28: Power dissipation breakdown for the counter implemented on SOFA SkyWater 130nm silicon.</em>
</p>

---