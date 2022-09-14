/*
 Copyright 2022 Carter Turnbaugh

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

`timescale 1ns / 1ps

module dac_splitter #
  (
   parameter integer DATA_WIDTH = 14
   )
   (
	input					clk,
	input					rst,
	input					dac_clk_i,
	input					dac_wrt_i,
    input [DATA_WIDTH-1:0]	din_a,
    input [DATA_WIDTH-1:0]	din_b,
    output					dac_clk_o,
    output					dac_wrt_o,
    output					dac_sel_o,
    output					dac_rst_o,
	output [DATA_WIDTH-1:0]	dout
    );

   reg [DATA_WIDTH-1:0]		din_a_reg, din_b_reg;
   always @(posedge clk) begin
	  din_a_reg <= din_a;
	  din_b_reg <= din_b;
   end

   ODDR ODDR_dac_clk ( .Q(dac_clk_o), .D1(1'b0), .D2(1'b1), .C(dac_clk_i),  .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_wrt ( .Q(dac_wrt_o), .D1(1'b0), .D2(1'b1), .C(dac_wrt_i), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_sel ( .Q(dac_sel_o), .D1(1'b1), .D2(1'b0), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_rst ( .Q(dac_rst_o), .D1(rst), .D2(rst), .C(clk), .CE(1'b1), .R(1'b0), .S(1'b0) );

   ODDR ODDR_dac_0  ( .Q(dout[ 0]), .D1(din_b_reg[ 0]), .D2(din_a_reg[ 0]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_1  ( .Q(dout[ 1]), .D1(din_b_reg[ 1]), .D2(din_a_reg[ 1]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_2  ( .Q(dout[ 2]), .D1(din_b_reg[ 2]), .D2(din_a_reg[ 2]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_3  ( .Q(dout[ 3]), .D1(din_b_reg[ 3]), .D2(din_a_reg[ 3]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_4  ( .Q(dout[ 4]), .D1(din_b_reg[ 4]), .D2(din_a_reg[ 4]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_5  ( .Q(dout[ 5]), .D1(din_b_reg[ 5]), .D2(din_a_reg[ 5]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_6  ( .Q(dout[ 6]), .D1(din_b_reg[ 6]), .D2(din_a_reg[ 6]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_7  ( .Q(dout[ 7]), .D1(din_b_reg[ 7]), .D2(din_a_reg[ 7]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_8  ( .Q(dout[ 8]), .D1(din_b_reg[ 8]), .D2(din_a_reg[ 8]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_9  ( .Q(dout[ 9]), .D1(din_b_reg[ 9]), .D2(din_a_reg[ 9]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_10 ( .Q(dout[10]), .D1(din_b_reg[10]), .D2(din_a_reg[10]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_11 ( .Q(dout[11]), .D1(din_b_reg[11]), .D2(din_a_reg[11]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_12 ( .Q(dout[12]), .D1(din_b_reg[12]), .D2(din_a_reg[12]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
   ODDR ODDR_dac_13 ( .Q(dout[13]), .D1(din_b_reg[13]), .D2(din_a_reg[13]), .C(clk), .CE(1'b1), .R(rst), .S(1'b0) );
endmodule
