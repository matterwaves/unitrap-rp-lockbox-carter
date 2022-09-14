/*
 Copyright 2022 Carter Turnbaugh

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

`timescale 1ns / 1ps

module ramp_module # (
					  parameter integer	RAMP_OUTPUT_WIDTH = 14,
					  parameter integer	RAMP_INTERNAL_WIDTH = 32
					  )
   (
    input							clk,
    input							rst,
    input [RAMP_INTERNAL_WIDTH-1:0]	ramplitude,
    input [RAMP_INTERNAL_WIDTH-1:0]	ramp_step,
    input [RAMP_INTERNAL_WIDTH-1:0]	ramp_start_offset,
    input [RAMP_INTERNAL_WIDTH-1:0]	ramplitude_step,
    output [RAMP_OUTPUT_WIDTH-1:0]	ramp_output,
    output							ramp_corner,
    output							ramp_start
    );

   reg [RAMP_INTERNAL_WIDTH-1:0]	ramp_reg, ramp_step_reg, ramplitude_step_reg, ramplitude_lim_reg, ramplitude_max_reg, ramplitude_min_reg;
   reg								ramp_up, ramp_corner_reg, ramp_start_reg;

   assign ramp_output = ramp_reg[(RAMP_INTERNAL_WIDTH-1):(RAMP_INTERNAL_WIDTH-RAMP_OUTPUT_WIDTH)];
   assign ramp_corner = ramp_corner_reg;
   assign ramp_start = ramp_start_reg;

   wire [RAMP_INTERNAL_WIDTH-1:0]	ramplitude_lim_neg;
   assign ramplitude_lim_neg = (~ramplitude_lim_reg) + 1'b1;

   always @(posedge clk) begin
      if(rst) begin
         ramp_reg <= ramp_start_offset;
         ramp_up <= 1'b1;
         ramp_corner_reg <= 1'b0;
         ramp_start_reg <= 1'b0;

         if(ramplitude_step_reg == 0) begin
            ramplitude_max_reg <= ramplitude_lim_reg;
            ramplitude_min_reg <= ramplitude_lim_neg;
         end
         else begin
            ramplitude_max_reg <= 1;
            ramplitude_min_reg <= -1;
         end
      end
      else begin
         if($signed(ramp_reg) >= $signed(ramplitude_max_reg + ramp_start_offset)) begin
            ramp_reg <= ramp_reg - ramp_step_reg;
            ramp_up <= 1'b0;
            ramp_corner_reg <= 1'b1;
            ramp_start_reg <= 1'b1;

            if(ramplitude_step_reg == 0) begin
               ramplitude_max_reg <= ramplitude_lim_reg;
            end
            else if($signed(ramplitude_max_reg) < $signed(ramplitude_lim_reg)) begin
               ramplitude_max_reg <= ramplitude_max_reg + ramplitude_step_reg;
            end
            else begin
               ramplitude_max_reg <= ramplitude_lim_reg;
            end
            ramplitude_min_reg <= ramplitude_min_reg;
         end
         else if($signed(ramp_reg) <= $signed(ramplitude_min_reg + ramp_start_offset)) begin
            ramp_reg <= ramp_reg + ramp_step_reg;
            ramp_up <= 1'b1;
            ramp_corner_reg <= 1'b1;
            ramp_start_reg <= 1'b0;

            if(ramplitude_step_reg == 0) begin
               ramplitude_min_reg <= ramplitude_lim_neg;
            end
            else if($signed(ramplitude_min_reg) > $signed(ramplitude_lim_neg)) begin
               ramplitude_min_reg <= ramplitude_min_reg - ramplitude_step_reg;
            end
            else begin
               ramplitude_min_reg <= ramplitude_lim_neg;
            end
            ramplitude_max_reg <= ramplitude_max_reg;
         end
         else if(ramp_up) begin
            ramp_up <= 1'b1;
            ramp_corner_reg <= 1'b0;
            ramp_start_reg <= 1'b0;

            ramp_reg <= ramp_reg + ramp_step_reg;
            ramplitude_max_reg <= ramplitude_max_reg;
            ramplitude_min_reg <= ramplitude_min_reg;
         end
         else begin
            ramp_up <= 1'b0;
            ramp_corner_reg <= 1'b0;
            ramp_start_reg <= 1'b0;

            ramp_reg <= ramp_reg - ramp_step_reg;
            ramplitude_max_reg <= ramplitude_max_reg;
            ramplitude_min_reg <= ramplitude_min_reg;
         end
      end

      ramplitude_lim_reg <= ramplitude;
      ramplitude_step_reg <= ramplitude_step;
      ramp_step_reg <= ramp_step;
   end
endmodule
