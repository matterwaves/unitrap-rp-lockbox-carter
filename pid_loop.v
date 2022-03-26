`timescale 1ns / 1ps

module pid_loop # (
	parameter integer PID_LOOP_INPUT_WIDTH = 14,
	parameter integer PID_LOOP_OUTPUT_WIDTH = 14,
	parameter integer PID_LOOP_INTERNAL_WIDTH = 32
    )
    (
    input clk,
    input rst,
    
    input[PID_LOOP_INPUT_WIDTH-1:0] setpoint,
    input[PID_LOOP_INPUT_WIDTH-1:0] loop_input,
    
    input[PID_LOOP_INTERNAL_WIDTH-1:0] P,
    input[PID_LOOP_INTERNAL_WIDTH-1:0] I,
    
    output[PID_LOOP_INPUT_WIDTH-1:0] error,
    
    output[PID_LOOP_OUTPUT_WIDTH-1:0] loop_output,
    input[PID_LOOP_OUTPUT_WIDTH-1:0] I_term_reset,

    output[PID_LOOP_INTERNAL_WIDTH-1:0] P_term_mon,
    output[PID_LOOP_INTERNAL_WIDTH-1:0] I_term_mon
    );
    
    // Buffer inputs to registers
    reg[PID_LOOP_INPUT_WIDTH-1:0] loop_input_reg, setpoint_reg;

    reg[PID_LOOP_INPUT_WIDTH-1:0] error_reg;
    
    // Hold output in register
    reg[PID_LOOP_INTERNAL_WIDTH-1:0] loop_output_reg;
    
    // Buffer P,I to registers
    reg[PID_LOOP_INTERNAL_WIDTH-1:0] P_reg, I_reg;

    // Intermediate stages
    reg signed[PID_LOOP_INTERNAL_WIDTH+PID_LOOP_INPUT_WIDTH-1:0] P_error_unshifted_reg, I_error_unshifted_reg;
    wire[PID_LOOP_INTERNAL_WIDTH-1:0] P_error, I_error;
    wire[PID_LOOP_INTERNAL_WIDTH:0] I_term_d;
    reg[PID_LOOP_INTERNAL_WIDTH-1:0] I_term_q;
    wire[PID_LOOP_INTERNAL_WIDTH-1:0] error_term;
    
    assign error = error_reg;
    assign loop_output = loop_output_reg[PID_LOOP_INTERNAL_WIDTH-1:PID_LOOP_INTERNAL_WIDTH-PID_LOOP_OUTPUT_WIDTH];

    assign P_error = P_error_unshifted_reg[PID_LOOP_INTERNAL_WIDTH-1:0];
    assign I_error = I_error_unshifted_reg[PID_LOOP_INTERNAL_WIDTH+PID_LOOP_INPUT_WIDTH-1:PID_LOOP_INPUT_WIDTH];
    
    assign I_term_d = $signed(I_term_q) + $signed(I_error);

    assign P_term_mon = P_error;
    assign I_term_mon = I_term_d;

    always @(posedge clk) begin
        if(rst) begin
            error_reg <= 0;
            I_term_q <= {I_term_reset, 18'b0};

            loop_output_reg <= 0;

            P_error_unshifted_reg <= 0;
            I_error_unshifted_reg <= 0;
        end
        else begin
            error_reg <= $signed(setpoint_reg) - $signed(loop_input_reg);
            
            if(I_term_d[PID_LOOP_INTERNAL_WIDTH:PID_LOOP_INTERNAL_WIDTH-1] == 2'b01) begin
                I_term_q <= 32'h7FFFFFFF;
            end
            else if(I_term_d[PID_LOOP_INTERNAL_WIDTH:PID_LOOP_INTERNAL_WIDTH-1] == 2'b10) begin
                I_term_q <= 32'h80000000;
            end
            else begin
                I_term_q <= I_term_d[PID_LOOP_INTERNAL_WIDTH-1:0];
            end

            loop_output_reg <= $signed(P_error) + $signed(I_term_d[PID_LOOP_INTERNAL_WIDTH-1:0]);

            P_error_unshifted_reg <= $signed(P_reg) * $signed(error_reg);
            I_error_unshifted_reg <= $signed(I_reg) * $signed(error_reg);
        end

        loop_input_reg <= loop_input;
        setpoint_reg <= setpoint;
        
        P_reg <= P;
        I_reg <= I;
    end
endmodule
