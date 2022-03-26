`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2019 08:56:09 PM
// Design Name: 
// Module Name: ramp_module
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


module ramp_module # (
	parameter integer RAMP_OUTPUT_WIDTH = 14,
	parameter integer RAMP_INTERNAL_WIDTH = 32
    )
    (
    input clk,
    input rst,
    input[RAMP_INTERNAL_WIDTH-1:0] ramplitude,
    input[RAMP_INTERNAL_WIDTH-1:0] ramp_step,
    input[RAMP_INTERNAL_WIDTH-1:0] ramp_start_offset,
    input[RAMP_INTERNAL_WIDTH-1:0] ramplitude_step,
    output[RAMP_OUTPUT_WIDTH-1:0] ramp_output,
    output ramp_corner,
    output ramp_start
    );

    reg[RAMP_INTERNAL_WIDTH-1:0] ramp_reg, ramp_step_reg, ramplitude_step_reg, ramplitude_lim_reg, ramplitude_max_reg, ramplitude_min_reg;
    reg ramp_up, ramp_corner_reg, ramp_start_reg;

    assign ramp_output = ramp_reg[(RAMP_INTERNAL_WIDTH-1):(RAMP_INTERNAL_WIDTH-RAMP_OUTPUT_WIDTH)];
    assign ramp_corner = ramp_corner_reg;
    assign ramp_start = ramp_start_reg;

    wire[RAMP_INTERNAL_WIDTH-1:0] ramplitude_lim_neg;
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
