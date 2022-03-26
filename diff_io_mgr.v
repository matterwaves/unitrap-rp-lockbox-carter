`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2019 12:11:14 PM
// Design Name: 
// Module Name: diff_io_mgr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module diff_io_mgr #(
    parameter integer OUTPUT_WIDTH = 1,
    parameter integer INOUT_WIDTH = 8
    )
    (
    input [OUTPUT_WIDTH-1:0] din,
    inout [INOUT_WIDTH-1:0] dout_p,
    inout [INOUT_WIDTH-1:0] dout_n
    );
    
    assign dout_p = {{INOUT_WIDTH-OUTPUT_WIDTH{1'b0}}, din};
    assign dout_n = ~{{INOUT_WIDTH-OUTPUT_WIDTH{1'b0}}, din};
endmodule
