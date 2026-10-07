`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:   tb_counter_clk_div
// Project:       FPGA Design Fabric & Architecture
// Author:        Sujay Kandalkar
// Description:   Behavioral testbench for the 4-bit clock-divided counter.
//                Generates 100 MHz clock stimulus (10ns period) and verifies
//                reset assertion, counter increment, and rollover.
//////////////////////////////////////////////////////////////////////////////////

module tb_counter_clk_div;

    // Testbench Stimulus Signals
    reg        clk;
    reg        rst;
    wire [3:0] counter_out;

    // Instantiate Unit Under Test (UUT) with smaller DELAY_MAX for rapid testbench execution
    counter_clk_div #(
        .DELAY_MAX(10) // Fast division for simulation waveform verification
    ) uut (
        .clk(clk),
        .rst(rst),
        .counter_out(counter_out)
    );

    // 100 MHz Clock Generation (Period = 10 ns)
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;

        // Apply synchronous reset for 50 ns
        #50;
        rst = 0;

        // Monitor outputs
        $monitor("Time = %0t ns | rst = %b | counter_out = %b (%0d)", 
                 $time, rst, counter_out, counter_out);

        // Allow counter to run through multiple counts
        #2500;

        // Apply reset again to verify synchronous reset behavior
        rst = 1;
        #50;
        rst = 0;
        #1000;

        $display("Simulation successfully completed.");
        $finish;
    end

endmodule
