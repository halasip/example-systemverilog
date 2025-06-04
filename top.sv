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
   always #50ns clk = ~clk;  // Toggle clock every 5 time units

   
      // Create 100 cycles of example stimulus
   logic [31:0] count_byte;
   always_ff @ (posedge clk or negedge reset) begin
      $display("[%0t] clk=%b reset=%b", $realtime, clk, reset);
      if (!reset) begin
	      count_byte <= 0;
      end else begin
	      count_byte <= count_byte + 1;
      end
   end

   // Create 100 cycles of example stimulus
   logic [31:0] count_c;
   always_ff @ (posedge fast_clk or negedge reset) begin
      $display("[%0t] fast_clk=%b reset=%b", $realtime, fast_clk, reset);
      if (!reset) begin
	      count_c <= 0;
      end
      else begin
	      count_c <= count_c + 1;
         if (count_c >= 99) begin
            $write("*-* All Finished *-*\n");
            $finish;
	      end
      end
   end

   // Example coverage analysis
   cover property (@(posedge clk) count_byte == 30);  // Hit
   cover property (@(posedge clk) count_byte == 300);  // Not covered

   // Example toggle analysis
   wire count_hit_50;  // Hit
   wire count_hit_500;  // Not covered

   assign count_hit_50 = (count_byte == 50);
   assign count_hit_500 = (count_byte == 500);

   // Example line and block coverage
   always_comb begin
      if (count_hit_50) begin  // Hit	
         $write("[%0t] got 50\n", $time);  // Hit
      end
      if (count_hit_500) begin  // Not covered
         $write("[%0t] got 600\n", $time);  // Not covered
      end
   end

   initial begin
      $dumpfile("top.fst");
      $dumpvars();
   end

endmodule
