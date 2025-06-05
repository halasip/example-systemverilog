// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2003 by Wilson Snyder.
// SPDX-License-Identifier: CC0-1.0
// ======================================================================
`timescale 1ns/10ps
module top();

    logic clk;
    logic reset;
    logic fast_clk;  // Fast clock for simulation
    // Create a clock
    initial begin
        $display("Starting simulation...");
        fast_clk = 0;
        clk = 0;
        reset = 1;  // Start with reset high
        #2ns reset = 0;
        #30ns reset = 1; 
    end

    always #5ns fast_clk = ~fast_clk;  // Toggle clock every 5 time units
    always #15ns clk = ~clk;  // Toggle clock every 5 time units

    logic [7:0]               denominator;
    logic [7:0]               numerator;
    logic [7:0]               remainder;
    logic [7:0]               quotient;
    logic                     control;
    logic [2:0]               status;

    initial begin
        $display("Starting divider simulation...");
        #300ns;  // Wait for reset to complete
        repeat(10) begin
            @(posedge clk); denominator = $urandom_range(127,0);  // Example denominator
            @(posedge clk); numerator = $urandom_range(255,128);    // Example numerator
            @(posedge clk); control = 1'b1;       // Start the division
            @(posedge clk);  // Wait for the next clock edge;
            wait(status[0] == 1'b1);  
            control = 1'b0;  // Stop the division
            wait(status[0] == 1'b0);  // Wait for finished status
            @(posedge clk);  // Wait for the next clock edge;
            $display("Remainder: %h, Quotient: %h, Status: %b", remainder, quotient, status);
        end
        #300ns;  // Wait for reset to complete
            @(posedge clk); denominator = 8'h00;  // Example denominator
            @(posedge clk); numerator = 8'h64;    // Example numerator
            @(posedge clk); control = 1'b1;       // Start the division
            @(posedge clk);  // Wait for the next clock edge;
            $display("Remainder: %h, Quotient: %h, Status: %b", remainder, quotient, status);
            assert(status[1]) else $fatal("Division by zero should set status[1] to 1");
            @(posedge clk);  // Wait for the next clock edge;
        #300ns;  // Wait for reset to complete
        $finish;
    end


    divider i_divider (
        .calculation_clk  (fast_clk     ),
        .rst_n            (reset        ),
        .slow_clk         (clk          ),
        .denominator_i    (denominator  ),
        .numerator_i      (numerator    ),
        .remainder_o      (remainder    ),
        .quotient_o       (quotient     ),
        .control_i        (control      ),
        .status_o         (status       )
    );

    initial begin
        $dumpfile("top.fst");
        $dumpvars();
    end

endmodule
