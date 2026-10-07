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

*(Detailed technical logs for each day are documented in the subsequent sections)*