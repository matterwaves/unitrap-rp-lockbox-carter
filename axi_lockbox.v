/*
 Copyright 2022 Carter Turnbaugh

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

`timescale 1 ns / 1 ps

module axi_lockbox #
  (
   // Users to add parameters here
   parameter integer ANALOG_INPUT_WIDTH = 14,
   parameter integer ANALOG_OUTPUT_WIDTH = 14,
   // User parameters ends
   // Do not modify the parameters beyond this line

   parameter integer C_S_AXI_DATA_WIDTH = 32, // Width of S_AXI data bus
   parameter integer C_S_AXI_ADDR_WIDTH = 7 // Width of S_AXI address bus
   )
   (
	// Users to add ports here
	input wire [ANALOG_INPUT_WIDTH-1:0]		pid_loop_input,
	output wire [ANALOG_OUTPUT_WIDTH-1:0]	axi_pi_output,

	input wire [ANALOG_INPUT_WIDTH-1:0]		autolock_input,

	output wire								input_reset,
	output wire								loop_locked,
	output wire								ramp_start,

	output wire [ANALOG_INPUT_WIDTH-1:0]	pid_loop_input_cpy,
	output wire [ANALOG_INPUT_WIDTH-1:0]	autolock_input_cpy,
	// User ports ends
	// Do not modify the ports beyond this line

   
	input wire								S_AXI_ACLK, // Global Clock Signal
	input wire								S_AXI_ARESETN, // Global Reset Signal. This Signal is Active LOW
	input wire [C_S_AXI_ADDR_WIDTH-1:0]		S_AXI_AWADDR, // Write address (issued by master, acceped by Slave)
	input wire [2:0]						S_AXI_AWPROT, // Write channel Protection type.
	input wire								S_AXI_AWVALID, // Write address valid.
	output wire								S_AXI_AWREADY, // Write address ready.
	input wire [C_S_AXI_DATA_WIDTH-1:0]		S_AXI_WDATA, // Write data (issued by master)
	input wire [(C_S_AXI_DATA_WIDTH/8)-1:0]	S_AXI_WSTRB, // Write strobes.
	input wire								S_AXI_WVALID, // Write valid.
	output wire								S_AXI_WREADY, // Write ready.
	output wire [1:0]						S_AXI_BRESP, // Write response.
	output wire								S_AXI_BVALID, // Write response valid.
	input wire								S_AXI_BREADY, // Response ready.
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0]	S_AXI_ARADDR, // Read address (issued by master).
	input wire [2 : 0]						S_AXI_ARPROT, // Protection type.
	input wire								S_AXI_ARVALID, // Read address valid.
	output wire								S_AXI_ARREADY, // Read address ready.
	output wire [C_S_AXI_DATA_WIDTH-1 : 0]	S_AXI_RDATA, // Read data (issued by slave).
	output wire [1 : 0]						S_AXI_RRESP, // Read response.
	output wire								S_AXI_RVALID, // Read valid.
	input wire								S_AXI_RREADY // Read ready.
	);

   // AXI4LITE signals
   reg [C_S_AXI_ADDR_WIDTH-1 : 0]			axi_awaddr;
   reg										axi_awready;
   reg										axi_wready;
   reg [1 : 0]								axi_bresp;
   reg										axi_bvalid;
   reg [C_S_AXI_ADDR_WIDTH-1 : 0]			axi_araddr;
   reg										axi_arready;
   reg [C_S_AXI_DATA_WIDTH-1 : 0]			axi_rdata;
   reg [1 : 0]								axi_rresp;
   reg										axi_rvalid;

   // Example-specific design signals
   // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
   // ADDR_LSB is used for addressing 32/64 bit registers/memories
   // ADDR_LSB = 2 for 32 bits (n downto 2)
   // ADDR_LSB = 3 for 64 bits (n downto 3)
   localparam integer						ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
   localparam integer						OPT_MEM_ADDR_BITS = 4;
   //----------------------------------------------
   //-- Signals for user logic register space example
   //------------------------------------------------
   //-- Number of Slave Registers 32
   // 0: enable, 1: PID reset, 4: force ramp, 8: autolock enable, 9: ramp reset
   reg [C_S_AXI_DATA_WIDTH-1:0]				control_reg; // 0x00, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				status_reg; // 0x02 W
   reg [C_S_AXI_DATA_WIDTH-1:0]				setpoint_reg; // 0x03, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				P_reg; // P value reg, 2's complement, 0x04, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				P_mon_reg; // P error monitor reg, 2's complement, 0x05, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				I_reg; // I value reg, 2' complement, 0x06, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				I_mon_reg; // I error monitor reg, 2's complement, 0x07, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				error_reg; // 0x08, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				loop_output_reg; // 0x0A, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				loop_input_reg; // 0x0B, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				autolock_mindex_reg; // 0x0C, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				autolock_maxdex_reg; // 0x0D, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				pid_mindex_reg; // 0x0E, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				pid_maxdex_reg; // 0x0F, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				ramplitude_reg; // 0x11, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				ramp_step_reg; // 0x12, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				autolock_thresh_min_reg; // 0x13, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				autolock_thresh_max_reg; // 0x14, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				loop_locked_min_reg; // 0x15, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				loop_locked_max_reg; // 0x16, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				loop_locked_delay_reg; // 0x17, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				ramp_output_reg; // 0x18, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				autolock_input_reg; // 0x19, W
   reg [C_S_AXI_DATA_WIDTH-1:0]				ramplitude_step_reg; // 0x1A, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				ramp_offset_reg; // 0x1B, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				input_railed_min_reg; // 0x1C, R
   reg [C_S_AXI_DATA_WIDTH-1:0]				input_railed_max_reg; // 0x1D, R
   wire										slv_reg_rden;
   wire										slv_reg_wren;
   reg [C_S_AXI_DATA_WIDTH-1:0]				reg_data_out;
   integer									byte_index;
   reg										aw_en;

   // I/O Connections assignments

   assign S_AXI_AWREADY	= axi_awready;
   assign S_AXI_WREADY	= axi_wready;
   assign S_AXI_BRESP	= axi_bresp;
   assign S_AXI_BVALID	= axi_bvalid;
   assign S_AXI_ARREADY	= axi_arready;
   assign S_AXI_RDATA	= axi_rdata;
   assign S_AXI_RRESP	= axi_rresp;
   assign S_AXI_RVALID	= axi_rvalid;
   // Implement axi_awready generation
   // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
   // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
   // de-asserted when reset is low.

   always @( posedge S_AXI_ACLK )
	 begin
		if ( S_AXI_ARESETN == 1'b0 )
	      begin
			 axi_awready <= 1'b0;
			 aw_en <= 1'b1;
	      end 
		else
	      begin    
			 if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	           begin
				  // slave is ready to accept write address when 
				  // there is a valid write address and write data
				  // on the write address and data bus. This design 
				  // expects no outstanding transactions. 
				  axi_awready <= 1'b1;
				  aw_en <= 1'b0;
	           end
	         else if (S_AXI_BREADY && axi_bvalid)
	           begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	           end
			 else           
	           begin
				  axi_awready <= 1'b0;
	           end
	      end 
	 end       

   // Implement axi_awaddr latching
   // This process is used to latch the address when both 
   // S_AXI_AWVALID and S_AXI_WVALID are valid. 

   always @( posedge S_AXI_ACLK )
	 begin
		if ( S_AXI_ARESETN == 1'b0 )
	      begin
			 axi_awaddr <= 0;
	      end 
		else
	      begin    
			 if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	           begin
				  // Write Address latching 
				  axi_awaddr <= S_AXI_AWADDR;
	           end
	      end 
	 end       

   // Implement axi_wready generation
   // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
   // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
   // de-asserted when reset is low. 

   always @( posedge S_AXI_ACLK )
	 begin
		if ( S_AXI_ARESETN == 1'b0 )
	      begin
			 axi_wready <= 1'b0;
	      end 
		else
	      begin    
			 if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	           begin
				  // slave is ready to accept write data when 
				  // there is a valid write address and write data
				  // on the write address and data bus. This design 
				  // expects no outstanding transactions. 
				  axi_wready <= 1'b1;
	           end
			 else
	           begin
				  axi_wready <= 1'b0;
	           end
	      end 
	 end       

   // Implement memory mapped register select and write logic generation
   // The write data is accepted and written to memory mapped registers when
   // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
   // select byte enables of slave registers while writing.
   // These registers are cleared when reset (active low) is applied.
   // Slave register write enable is asserted when valid address and data are available
   // and the slave is ready to accept the write address and write data.
   assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

   always @( posedge S_AXI_ACLK )
	 begin
		if ( S_AXI_ARESETN == 1'b0 )
	      begin
			 control_reg <= 0;
			 setpoint_reg <= 0;
			 P_reg <= 0;
			 I_reg <= 0;
			 ramplitude_reg <= 0;
			 ramp_step_reg <= 0;
			 autolock_thresh_min_reg <= 0;
			 autolock_thresh_max_reg <= 0;
			 loop_locked_min_reg <= 0;
			 loop_locked_max_reg <= 0;
			 loop_locked_delay_reg <= 0;
			 ramplitude_step_reg <= 0;
			 ramp_offset_reg <= 0;
			 input_railed_min_reg <= 0;
			 input_railed_max_reg <= 0;
	      end 
		else begin
	       if (slv_reg_wren)
			 begin
				case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
				  5'h00:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 control_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end  
				  5'h03:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 setpoint_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end  
				  5'h04:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 P_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end  
				  5'h06:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 I_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end  
				  5'h11:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 ramplitude_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  5'h12:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 ramp_step_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  5'h13:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 autolock_thresh_min_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  5'h14:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 autolock_thresh_max_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  5'h15:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 loop_locked_min_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  5'h16:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 loop_locked_max_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  5'h17:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 loop_locked_delay_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  5'h1A:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 ramplitude_step_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  5'h1B:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 ramp_offset_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  5'h1C:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 input_railed_min_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  5'h1D:
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
					  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						 // Respective byte enables are asserted as per write strobes
						 input_railed_max_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
					  end
				  default : begin
	                 control_reg <= control_reg;
	                 setpoint_reg <= setpoint_reg;
	                 P_reg <= P_reg;
	                 I_reg <= I_reg;
	                 ramplitude_reg <= ramplitude_reg;
	                 ramp_step_reg <= ramp_step_reg;
	                 autolock_thresh_min_reg <= autolock_thresh_min_reg;
	                 autolock_thresh_max_reg <= autolock_thresh_max_reg;
	                 loop_locked_min_reg <= loop_locked_min_reg;
	                 loop_locked_max_reg <= loop_locked_max_reg;
	                 loop_locked_delay_reg <= loop_locked_delay_reg;
	                 ramplitude_step_reg <= ramplitude_step_reg;
	                 ramp_offset_reg <= ramp_offset_reg;
	                 input_railed_min_reg <= input_railed_min_reg;
	                 input_railed_max_reg <= input_railed_max_reg;
	              end
				endcase
			 end
		end
	 end    

   // Implement write response logic generation
   // The write response and response valid signals are asserted by the slave 
   // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
   // This marks the acceptance of address and indicates the status of 
   // write transaction.

   always @( posedge S_AXI_ACLK )
	 begin
		if ( S_AXI_ARESETN == 1'b0 )
	      begin
			 axi_bvalid  <= 0;
			 axi_bresp   <= 2'b0;
	      end 
		else
	      begin    
			 if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	           begin
				  // indicates a valid write response is available
				  axi_bvalid <= 1'b1;
				  axi_bresp  <= 2'b0; // 'OKAY' response 
	           end                   // work error responses in future
			 else
	           begin
				  if (S_AXI_BREADY && axi_bvalid) 
					//check if bready is asserted while bvalid is high) 
					//(there is a possibility that bready is always asserted high)   
					begin
					   axi_bvalid <= 1'b0; 
					end  
	           end
	      end
	 end   

   // Implement axi_arready generation
   // axi_arready is asserted for one S_AXI_ACLK clock cycle when
   // S_AXI_ARVALID is asserted. axi_awready is 
   // de-asserted when reset (active low) is asserted. 
   // The read address is also latched when S_AXI_ARVALID is 
   // asserted. axi_araddr is reset to zero on reset assertion.

   always @( posedge S_AXI_ACLK )
	 begin
		if ( S_AXI_ARESETN == 1'b0 )
	      begin
			 axi_arready <= 1'b0;
			 axi_araddr  <= 32'b0;
	      end 
		else
	      begin    
			 if (~axi_arready && S_AXI_ARVALID)
	           begin
				  // indicates that the slave has acceped the valid read address
				  axi_arready <= 1'b1;
				  // Read address latching
				  axi_araddr  <= S_AXI_ARADDR;
	           end
			 else
	           begin
				  axi_arready <= 1'b0;
	           end
	      end 
	 end       

   // Implement axi_arvalid generation
   // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
   // S_AXI_ARVALID and axi_arready are asserted. The slave registers 
   // data are available on the axi_rdata bus at this instance. The 
   // assertion of axi_rvalid marks the validity of read data on the 
   // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
   // is deasserted on reset (active low). axi_rresp and axi_rdata are 
   // cleared to zero on reset (active low).  
   always @( posedge S_AXI_ACLK )
	 begin
		if ( S_AXI_ARESETN == 1'b0 )
	      begin
			 axi_rvalid <= 0;
			 axi_rresp  <= 0;
	      end 
		else
	      begin    
			 if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	           begin
				  // Valid read data is available at the read data bus
				  axi_rvalid <= 1'b1;
				  axi_rresp  <= 2'b0; // 'OKAY' response
	           end   
			 else if (axi_rvalid && S_AXI_RREADY)
	           begin
				  // Read data is accepted by the master
				  axi_rvalid <= 1'b0;
	           end                
	      end
	 end    

   // Implement memory mapped register select and read logic generation
   // Slave register read enable is asserted when valid address is available
   // and the slave is ready to accept the read address.
   assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
   always @(*)
	 begin
	    // Address decoding for reading registers
	    case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	      5'h00   : reg_data_out <= control_reg;
	      5'h02   : reg_data_out <= status_reg;
	      5'h03   : reg_data_out <= setpoint_reg;
	      5'h04   : reg_data_out <= P_reg;
	      5'h05   : reg_data_out <= P_mon_reg;
	      5'h06   : reg_data_out <= I_reg;
	      5'h07   : reg_data_out <= I_mon_reg;
	      5'h08   : reg_data_out <= error_reg;
	      5'h0A   : reg_data_out <= loop_output_reg;
	      5'h0B   : reg_data_out <= loop_input_reg;
	      5'h0C   : reg_data_out <= autolock_mindex_reg;
	      5'h0D   : reg_data_out <= autolock_maxdex_reg;
	      5'h0E   : reg_data_out <= pid_mindex_reg;
	      5'h0F   : reg_data_out <= pid_maxdex_reg;
	      5'h11   : reg_data_out <= ramplitude_reg;
	      5'h12   : reg_data_out <= ramp_step_reg;
	      5'h13   : reg_data_out <= autolock_thresh_min_reg;
	      5'h14   : reg_data_out <= autolock_thresh_max_reg;
	      5'h15   : reg_data_out <= loop_locked_min_reg;
	      5'h16   : reg_data_out <= loop_locked_max_reg;
	      5'h17   : reg_data_out <= loop_locked_delay_reg;
	      5'h18   : reg_data_out <= ramp_output_reg;
	      5'h19   : reg_data_out <= autolock_input_reg;
	      5'h1A   : reg_data_out <= ramplitude_step_reg;
	      5'h1B   : reg_data_out <= ramp_offset_reg;
	      5'h1C   : reg_data_out <= input_railed_min_reg;
	      5'h1D   : reg_data_out <= input_railed_max_reg;
	      default : reg_data_out <= 0;
	    endcase
	 end

   // Output register or memory read data
   always @( posedge S_AXI_ACLK )
	 begin
		if ( S_AXI_ARESETN == 1'b0 )
	      begin
			 axi_rdata  <= 0;
	      end 
		else
	      begin    
			 // When there is a valid read address (S_AXI_ARVALID) with 
			 // acceptance of read address by the slave (axi_arready), 
			 // output the read dada 
			 if (slv_reg_rden)
	           begin
				  axi_rdata <= reg_data_out;     // register read data
	           end   
	      end
	 end    

   // Add user logic here

   wire[ANALOG_INPUT_WIDTH-1:0] pid_loop_0_input, autolock_input_tc;
   reg [ANALOG_INPUT_WIDTH-1:0]	autolock_0_input;
   wire [ANALOG_OUTPUT_WIDTH-1:0] pid_loop_0_output;

   reg [ANALOG_OUTPUT_WIDTH-1:0]  axi_pi_output_reg;

   // Convert from offset (DAC and ADC) to 2's complement
   assign pid_loop_0_input = {pid_loop_input[ANALOG_INPUT_WIDTH-1], ~pid_loop_input[ANALOG_INPUT_WIDTH-2:0]};
   assign autolock_input_tc = {autolock_input[ANALOG_INPUT_WIDTH-1], ~autolock_input[ANALOG_INPUT_WIDTH-2:0]};
   assign axi_pi_output = {axi_pi_output_reg[ANALOG_OUTPUT_WIDTH-1], ~axi_pi_output_reg[ANALOG_OUTPUT_WIDTH-2:0]};

   wire							  pid_loop_0_rst;

   wire [ANALOG_INPUT_WIDTH-1:0]  pid_loop_0_error;

   wire [C_S_AXI_DATA_WIDTH-1:0]  P_term_mon, I_term_mon;

   wire							  ramp_module_0_rst, ramp_module_0_corner;
   wire [ANALOG_OUTPUT_WIDTH-1:0] ramp_module_0_output;
   wire [C_S_AXI_DATA_WIDTH-1:0]  ramp_module_0_reset;

   pid_loop # (
			   .PID_LOOP_INPUT_WIDTH(ANALOG_INPUT_WIDTH),
			   .PID_LOOP_OUTPUT_WIDTH(ANALOG_OUTPUT_WIDTH)
			   ) pid_loop_0 (
							 .clk(S_AXI_ACLK),
							 .rst(pid_loop_0_rst),
							 .setpoint(setpoint_reg[ANALOG_INPUT_WIDTH-1:0]),
							 .loop_input(pid_loop_0_input),
							 .P(P_reg),
							 .P_term_mon(P_term_mon),
							 .I(I_reg),
							 .I_term_mon(I_term_mon),
							 .error(pid_loop_0_error),
							 .loop_output(pid_loop_0_output),
							 .I_term_reset(ramp_module_0_output)
							 );

   ramp_module # (
				  .RAMP_OUTPUT_WIDTH(ANALOG_OUTPUT_WIDTH)
				  ) ramp_module_0 (
								   .clk(S_AXI_ACLK),
								   .rst(ramp_module_0_rst),
								   .ramplitude(ramplitude_reg),
								   .ramp_step(ramp_step_reg),
								   .ramp_start_offset(ramp_module_0_reset),
								   .ramplitude_step(ramplitude_step_reg),
								   .ramp_output(ramp_module_0_output),
								   .ramp_corner(ramp_module_0_corner),
								   .ramp_start(ramp_start)
								   );

   reg [C_S_AXI_DATA_WIDTH-1:0]	  loop_locked_counter_reg;
   reg [ANALOG_INPUT_WIDTH-1:0]	  pid_loop_0_input_reg;

   reg [ANALOG_INPUT_WIDTH-1:0]	  autolock_input_min, autolock_input_max;
   reg [ANALOG_OUTPUT_WIDTH-1:0]  autolock_input_mindex, autolock_input_maxdex;
   reg [ANALOG_INPUT_WIDTH-1:0]	  pid_input_min, pid_input_max;
   reg [ANALOG_OUTPUT_WIDTH-1:0]  pid_input_mindex, pid_input_maxdex;

   wire							  engage_pid_loop = ($signed(autolock_0_input) > $signed(autolock_thresh_min_reg)) & ($signed(autolock_0_input) < $signed(autolock_thresh_max_reg));
   wire							  input_stable = ($signed(pid_loop_0_input_reg) > $signed(loop_locked_min_reg)) & ($signed(pid_loop_0_input_reg) < $signed(loop_locked_max_reg));
   wire							  input_railed = ($signed(pid_loop_0_input_reg) > $signed(input_railed_max_reg)) | ($signed(pid_loop_0_input_reg) < $signed(input_railed_min_reg));
   assign loop_locked = loop_locked_counter_reg > loop_locked_delay_reg;

   reg							  input_reset_reg;
   assign input_reset = input_reset_reg;

   wire							  enable = control_reg[0];
   wire							  autolock = control_reg[8];
   wire							  ramp_enable = control_reg[4];

   wire							  autolock_enable = autolock & ~ramp_enable;
   assign ramp_module_0_rst = ~S_AXI_ARESETN | control_reg[9] | ~enable | (autolock_enable & loop_locked);
   assign pid_loop_0_rst = ~S_AXI_ARESETN | control_reg[1] | (autolock_enable & ~engage_pid_loop);

   assign ramp_module_0_reset = ramp_offset_reg + {pid_loop_0_output, {C_S_AXI_DATA_WIDTH-ANALOG_OUTPUT_WIDTH+1{1'b0}}};

   wire							  ramping = ramp_enable | (autolock & ~engage_pid_loop);
   
   assign autolock_input_cpy = autolock_0_input;
   assign pid_loop_input_cpy = pid_loop_0_input_reg;

   always @(posedge S_AXI_ACLK) begin
      autolock_0_input <= autolock_input_tc;
      pid_loop_0_input_reg <= pid_loop_0_input;

	  loop_output_reg <= {{C_S_AXI_DATA_WIDTH-ANALOG_OUTPUT_WIDTH+1{pid_loop_0_output[ANALOG_OUTPUT_WIDTH-1]}}, pid_loop_0_output[ANALOG_OUTPUT_WIDTH-2:0]};
	  loop_input_reg <= {{C_S_AXI_DATA_WIDTH-ANALOG_INPUT_WIDTH+1{pid_loop_0_input[ANALOG_INPUT_WIDTH-1]}}, pid_loop_0_input[ANALOG_INPUT_WIDTH-2:0]};
	  ramp_output_reg <= {{C_S_AXI_DATA_WIDTH-ANALOG_OUTPUT_WIDTH+1{ramp_module_0_output[ANALOG_OUTPUT_WIDTH-1]}}, ramp_module_0_output[ANALOG_OUTPUT_WIDTH-2:0]};
	  autolock_input_reg <= {{C_S_AXI_DATA_WIDTH-ANALOG_INPUT_WIDTH+1{autolock_0_input[ANALOG_INPUT_WIDTH-1]}}, autolock_0_input[ANALOG_INPUT_WIDTH-2:0]};
	  
	  P_mon_reg <= P_term_mon;
	  I_mon_reg <= I_term_mon;

	  status_reg[0] <= enable;
	  status_reg[1] <= pid_loop_0_rst;
	  status_reg[3:2] <= 2'b0;
	  status_reg[4] <= ramp_enable;
	  status_reg[7:5] <= 3'b0;
	  status_reg[8] <= autolock;
	  status_reg[9] <= ramp_module_0_rst;
	  status_reg[10] <= loop_locked;
	  status_reg[11] <= autolock_enable;
	  status_reg[C_S_AXI_DATA_WIDTH-1:12] = 0;

	  error_reg <= {{C_S_AXI_DATA_WIDTH-ANALOG_INPUT_WIDTH+1{pid_loop_0_error[ANALOG_INPUT_WIDTH-1]}}, pid_loop_0_error[ANALOG_INPUT_WIDTH-2:0]};

	  // Output routing logic
	  if(~enable) begin
	     axi_pi_output_reg <= 0;
	  end
	  else if(ramping) begin
	     axi_pi_output_reg <= ramp_module_0_output;
	  end
	  else begin
	     axi_pi_output_reg <= pid_loop_0_output;
	  end

	  // Mindex/Maxdex logic
	  if(loop_locked) begin
	     autolock_mindex_reg[31:16] <= {{16-ANALOG_INPUT_WIDTH+1{autolock_input_min[ANALOG_INPUT_WIDTH-1]}}, autolock_input_min[ANALOG_INPUT_WIDTH-2:0]};
	     autolock_mindex_reg[15:0] <= {{16-ANALOG_INPUT_WIDTH+1{autolock_input_mindex[ANALOG_INPUT_WIDTH-1]}}, autolock_input_mindex[ANALOG_INPUT_WIDTH-2:0]};
	     autolock_maxdex_reg[31:16] <= {{16-ANALOG_INPUT_WIDTH+1{autolock_input_max[ANALOG_INPUT_WIDTH-1]}}, autolock_input_max[ANALOG_INPUT_WIDTH-2:0]};
	     autolock_maxdex_reg[15:0] <= {{16-ANALOG_INPUT_WIDTH+1{autolock_input_maxdex[ANALOG_INPUT_WIDTH-1]}}, autolock_input_maxdex[ANALOG_INPUT_WIDTH-2:0]};

	     autolock_input_min <= autolock_0_input;
	     autolock_input_mindex <= pid_loop_0_output;
	     autolock_input_max <= autolock_0_input;
	     autolock_input_maxdex <= pid_loop_0_output;

	     pid_mindex_reg[31:16] <= {{16-ANALOG_INPUT_WIDTH+1{pid_input_min[ANALOG_INPUT_WIDTH-1]}}, pid_input_min[ANALOG_INPUT_WIDTH-2:0]};
	     pid_mindex_reg[15:0] <= {{16-ANALOG_INPUT_WIDTH+1{pid_input_mindex[ANALOG_INPUT_WIDTH-1]}}, pid_input_mindex[ANALOG_INPUT_WIDTH-2:0]};
	     pid_maxdex_reg[31:16] <= {{16-ANALOG_INPUT_WIDTH+1{pid_input_max[ANALOG_INPUT_WIDTH-1]}}, pid_input_max[ANALOG_INPUT_WIDTH-2:0]};
	     pid_maxdex_reg[15:0] <= {{16-ANALOG_INPUT_WIDTH+1{pid_input_maxdex[ANALOG_INPUT_WIDTH-1]}}, pid_input_maxdex[ANALOG_INPUT_WIDTH-2:0]};

	     pid_input_min <= pid_loop_0_input_reg;
	     pid_input_mindex <= pid_loop_0_output;
	     pid_input_max <= pid_loop_0_input_reg;
	     pid_input_maxdex <= pid_loop_0_output;
	  end
	  else if(ramp_module_0_corner) begin
	     autolock_mindex_reg[31:16] <= {{16-ANALOG_INPUT_WIDTH+1{autolock_input_min[ANALOG_INPUT_WIDTH-1]}}, autolock_input_min[ANALOG_INPUT_WIDTH-2:0]};
	     autolock_mindex_reg[15:0] <= {{16-ANALOG_INPUT_WIDTH+1{autolock_input_mindex[ANALOG_INPUT_WIDTH-1]}}, autolock_input_mindex[ANALOG_INPUT_WIDTH-2:0]};
	     autolock_maxdex_reg[31:16] <= {{16-ANALOG_INPUT_WIDTH+1{autolock_input_max[ANALOG_INPUT_WIDTH-1]}}, autolock_input_max[ANALOG_INPUT_WIDTH-2:0]};
	     autolock_maxdex_reg[15:0] <= {{16-ANALOG_INPUT_WIDTH+1{autolock_input_maxdex[ANALOG_INPUT_WIDTH-1]}}, autolock_input_maxdex[ANALOG_INPUT_WIDTH-2:0]};

	     autolock_input_min <= autolock_0_input;
	     autolock_input_mindex <= ramp_module_0_output;
	     autolock_input_max <= autolock_0_input;
	     autolock_input_maxdex <= ramp_module_0_output;

	     pid_mindex_reg[31:16] <= {{16-ANALOG_INPUT_WIDTH+1{pid_input_min[ANALOG_INPUT_WIDTH-1]}}, pid_input_min[ANALOG_INPUT_WIDTH-2:0]};
	     pid_mindex_reg[15:0] <= {{16-ANALOG_INPUT_WIDTH+1{pid_input_mindex[ANALOG_INPUT_WIDTH-1]}}, pid_input_mindex[ANALOG_INPUT_WIDTH-2:0]};
	     pid_maxdex_reg[31:16] <= {{16-ANALOG_INPUT_WIDTH+1{pid_input_max[ANALOG_INPUT_WIDTH-1]}}, pid_input_max[ANALOG_INPUT_WIDTH-2:0]};
	     pid_maxdex_reg[15:0] <= {{16-ANALOG_INPUT_WIDTH+1{pid_input_maxdex[ANALOG_INPUT_WIDTH-1]}}, pid_input_maxdex[ANALOG_INPUT_WIDTH-2:0]};

	     pid_input_min <= pid_loop_0_input_reg;
	     pid_input_mindex <= ramp_module_0_output;
	     pid_input_max <= pid_loop_0_input_reg;
	     pid_input_maxdex <= ramp_module_0_output;
	  end
	  else begin
	     if($signed(autolock_0_input) < $signed(autolock_input_min)) begin
	        autolock_input_min <= autolock_0_input;
	        autolock_input_mindex <= ramp_module_0_output;
	     end
	     else begin
	        autolock_input_min <= autolock_input_min;
	        autolock_input_mindex <= autolock_input_mindex;
	     end

	     if($signed(autolock_0_input) > $signed(autolock_input_max)) begin
	        autolock_input_max <= autolock_0_input;
	        autolock_input_maxdex <= ramp_module_0_output;
	     end
	     else begin
	        autolock_input_max <= autolock_input_max;
	        autolock_input_maxdex <= autolock_input_maxdex;
	     end
	     if($signed(pid_loop_0_input_reg) < $signed(pid_input_min)) begin
	        pid_input_min <= pid_loop_0_input_reg;
	        pid_input_mindex <= ramp_module_0_output;
	     end
	     else begin
	        pid_input_min <= pid_input_min;
	        pid_input_mindex <= pid_input_mindex;
	     end

	     if($signed(pid_loop_0_input_reg) > $signed(pid_input_max)) begin
	        pid_input_max <= pid_loop_0_input_reg;
	        pid_input_maxdex <= ramp_module_0_output;
	     end
	     else begin
	        pid_input_max <= pid_input_max;
	        pid_input_maxdex <= pid_input_maxdex;
	     end

	     autolock_mindex_reg <= autolock_mindex_reg;
	     autolock_maxdex_reg <= autolock_maxdex_reg;
	     pid_mindex_reg <= pid_mindex_reg;
	     pid_maxdex_reg <= pid_maxdex_reg;
	  end

	  // Loop locked logic
	  if(enable & engage_pid_loop & input_stable) begin
	     if(loop_locked) begin
	        loop_locked_counter_reg <= loop_locked_counter_reg;
	     end
	     else begin
	        loop_locked_counter_reg <= loop_locked_counter_reg + 1'b1;
	     end
	  end
	  else begin
	     loop_locked_counter_reg <= 0;
	  end

	  // Input reset logic
	  if(~enable | ~autolock_enable | input_stable) begin
	     input_reset_reg <= 1'b0;
	  end
	  else if(input_railed) begin
	     input_reset_reg <= 1'b1;
	  end
	  else begin
	     input_reset_reg <= input_reset_reg;
	  end
   end
   // User logic ends

endmodule
