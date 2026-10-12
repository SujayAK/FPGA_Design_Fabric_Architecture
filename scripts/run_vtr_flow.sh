#!/bin/bash
# ==============================================================================
# Script: run_vtr_flow.sh
# Project: FPGA Design Fabric & Architecture
# Author: Sujay Kandalkar
# Description: Automated execution script for the Verilog-to-Routing (VTR) flow.
# ==============================================================================

set -e

if [ -z "$VTR_ROOT" ]; then
    echo "ERROR: VTR_ROOT environment variable is not set."
    echo "Please source your VTR environment: export VTR_ROOT=/path/to/vtr"
    exit 1
fi

CIRCUIT_VERILOG=${1:-"../src/rtl/counter_clk_div.v"}
ARCH_XML=${2:-"$VTR_ROOT/vtr_flow/arch/timing/EArch.xml"}
ROUTE_CHAN_WIDTH=${3:-100}
OUTPUT_DIR="./vtr_run_output"

mkdir -p $OUTPUT_DIR

echo "=== Running VTR Flow for circuit: $CIRCUIT_VERILOG ==="
echo "=== Architecture: $ARCH_XML ==="

python3 $VTR_ROOT/vtr_flow/scripts/run_vtr_flow.py \
    $CIRCUIT_VERILOG \
    $ARCH_XML \
    -temp_dir $OUTPUT_DIR \
    --route_chan_width $ROUTE_CHAN_WIDTH \
    --gen_post_synthesis_netlist on \
    -power \
    -cmos_tech $VTR_ROOT/vtr_flow/tech/PTM_45nm/45nm.xml

echo "=== VTR Flow Execution Completed Successfully ==="
