`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:   counter_clk_div
// Project:       FPGA Design Fabric & Architecture
// Author:        Sujay Kandalkar
// Description:   4-bit synchronous up-counter driven by a clock division block.
//                Divides an onboard 100 MHz oscillator down to a visible / measurable
//                frequency for Basys 3 FPGA hardware verification and simulation.
//////////////////////////////////////////////////////////////////////////////////

module counter_clk_div #(
    parameter integer DELAY_MAX = 212 // Threshold for slow clock generation
)(
    input  wire       clk,          // Onboard 100 MHz primary clock
    input  wire       rst,          // Synchronous active-high reset
    output reg  [3:0] counter_out   // 4-bit synchronous counter output
);

    // Internal clock division registers
    reg        div_clk;
    reg [25:0] delay_count;

    // --------------------------------------------------------------------------
    // Clock Division Block:
    // Toggles div_clk when delay_count reaches the programmed DELAY_MAX threshold.
    // --------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            delay_count <= 26'd0;
            div_clk     <= 1'b0;
        end else begin
            if (delay_count == DELAY_MAX) begin
                delay_count <= 26'd0;
                div_clk     <= ~div_clk; // Toggle generated divided clock
            end else begin
                delay_count <= delay_count + 1'b1;
            end
        end
    end

    // --------------------------------------------------------------------------
    // 4-Bit Synchronous Up-Counter Block:
    // Increments sequentially on every rising edge of div_clk.
    // --------------------------------------------------------------------------
    always @(posedge div_clk) begin
        if (rst) begin
            counter_out <= 4'b0000;
        end else begin
            counter_out <= counter_out + 1'b1;
        end
    end

endmodule
