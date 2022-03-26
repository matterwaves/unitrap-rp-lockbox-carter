
`timescale 1 ns / 1 ps

	module axi_scope #
	(
		// Users to add parameters here
		parameter integer ANALOG_INPUT_WIDTH = 14,
		parameter integer DATA_OUTPUT_DEPTH = 13,
		// User parameters ends
		// Do not modify the parameters beyond this line

		parameter integer C_S_AXI_DATA_WIDTH	= 32, // Width of S_AXI data bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 7 // Width of S_AXI address bus
	)
	(
		// Users to add ports here
		input wire[ANALOG_INPUT_WIDTH-1:0] channel_0_input,
		input wire[ANALOG_INPUT_WIDTH-1:0] channel_1_input,

		input wire trigger0,
		input wire trigger1,

		output wire[31:0] channel_0_data,
		output wire[31:0] channel_1_data,

		output wire[DATA_OUTPUT_DEPTH-1:0] write_addr,
		output wire data_write_enable,
		// User ports ends
		// Do not modify the ports beyond this line

		
		input wire S_AXI_ACLK, // Global Clock Signal
		input wire S_AXI_ARESETN, // Global Reset Signal. This Signal is Active LOW
		input wire[C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR, // Write address (issued by master, acceped by Slave)
		input wire[2:0] S_AXI_AWPROT, // Write channel Protection type.
		input wire S_AXI_AWVALID, // Write address valid.
		output wire S_AXI_AWREADY, // Write address ready.
		input wire[C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA, // Write data (issued by master)
		input wire[(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB, // Write strobes.
		input wire S_AXI_WVALID, // Write valid.
		output wire S_AXI_WREADY, // Write ready.
		output wire[1:0] S_AXI_BRESP, // Write response.
		output wire S_AXI_BVALID, // Write response valid.
		input wire S_AXI_BREADY, // Response ready.
		input wire[C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR, // Read address (issued by master).
		input wire[2 : 0] S_AXI_ARPROT, // Protection type.
		input wire S_AXI_ARVALID, // Read address valid.
		output wire S_AXI_ARREADY, // Read address ready.
		output wire[C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA, // Read data (issued by slave).
		output wire[1 : 0] S_AXI_RRESP, // Read response.
		output wire S_AXI_RVALID, // Read valid.
		input wire S_AXI_RREADY // Read ready.
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 4;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 32
	// 0: enable, 1: trigger enable
	reg [C_S_AXI_DATA_WIDTH-1:0]	control_reg; // 0x00, R
	reg [C_S_AXI_DATA_WIDTH-1:0]	length_reg; // 0x01, R
	reg [C_S_AXI_DATA_WIDTH-1:0]	status_reg; // 0x02 W
	reg [C_S_AXI_DATA_WIDTH-1:0]	channel_0_acc_reg; // 0x06, W
	reg [C_S_AXI_DATA_WIDTH-1:0]	channel_1_acc_reg; // 0x07, W
	reg [C_S_AXI_DATA_WIDTH-1:0]	timebase_reg; // 0x10, R
	reg [C_S_AXI_DATA_WIDTH-1:0]	scale_reg; // 0x11, R
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

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
	      length_reg <= 0;
	      timebase_reg <= 0;
	      scale_reg <= 0;
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
	          5'h01:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes
	                length_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          5'h10:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes
	                timebase_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          5'h11:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes
	                scale_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          default : begin
	                      control_reg <= control_reg;
	                      length_reg <= length_reg;
	                      timebase_reg <= timebase_reg;
	                      scale_reg <= scale_reg;
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
	        5'h01   : reg_data_out <= length_reg;
	        5'h02   : reg_data_out <= status_reg;
	        5'h06   : reg_data_out <= channel_0_acc_reg;
	        5'h07   : reg_data_out <= channel_1_acc_reg;
	        5'h10   : reg_data_out <= timebase_reg;
	        5'h11   : reg_data_out <= scale_reg;
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
	reg[31:0] time_counter_reg;

	reg[31:0] channel_0_data_reg, channel_1_data_reg;
	reg[DATA_OUTPUT_DEPTH-3:0] data_addr_reg, data_write_addr_reg;
	reg data_write_enable_reg;
	
	wire[31:0] channel_0_input_wide, channel_1_input_wide;
	assign channel_0_input_wide = {{(32-ANALOG_INPUT_WIDTH+1){channel_0_input[ANALOG_INPUT_WIDTH-1]}}, channel_0_input[ANALOG_INPUT_WIDTH-2:0]} << scale_reg;
	assign channel_1_input_wide = {{(32-ANALOG_INPUT_WIDTH+1){channel_1_input[ANALOG_INPUT_WIDTH-1]}}, channel_1_input[ANALOG_INPUT_WIDTH-2:0]} << scale_reg;
	
	assign data_write_enable = data_write_enable_reg;
	assign write_addr = {data_write_addr_reg, 2'b00};
	assign channel_0_data = channel_0_data_reg;
	assign channel_1_data = channel_1_data_reg;
	
	wire wait_trigger;
	assign wait_trigger = ((~trigger0) & control_reg[8]) | ((~trigger1) & control_reg[9]) | control_reg[1];
	
	always @(posedge S_AXI_ACLK) begin
	   if ( S_AXI_ARESETN == 1'b0 | ~control_reg[0]) begin
	       channel_0_data_reg <= 32'b0;
	       channel_1_data_reg <= 32'b0;
	       channel_0_acc_reg <= 32'b0;
	       channel_1_acc_reg <= 32'b0;

	       time_counter_reg <= 32'b0;

	       data_addr_reg <= length_reg;
	       data_write_addr_reg <= length_reg;
	       data_write_enable_reg <= 1'b0;
	       
	       status_reg <= 32'hFFFF0000;
	   end
	   else begin
	       status_reg[0] <= control_reg[0];
	       status_reg[1] <= control_reg[1];
	       status_reg[2] <= wait_trigger;
	       status_reg[3] <= 0;
	       status_reg[7:5] <= 0;
	       status_reg[8] <= control_reg[8];
	       status_reg[9] <= control_reg[9];
	       status_reg[10] <= trigger0;
	       status_reg[11] <= trigger1;
	       status_reg[31:12] <= 0;
	       if(data_addr_reg >= length_reg) begin
	           channel_0_acc_reg <= channel_0_input_wide;
	           channel_1_acc_reg <= channel_1_input_wide;

	           time_counter_reg <= 0;
	           status_reg[4] <= 1'b0;

	           channel_0_data_reg <= 32'b0;
	           channel_1_data_reg <= 32'b0;
	           if (wait_trigger) begin
	               data_addr_reg <= length_reg;
	           end
	           else begin
	               data_addr_reg <= 0;
	           end
	           data_write_addr_reg <= data_write_addr_reg;
	           data_write_enable_reg <= 1'b0;
	       end
	       else begin
	           status_reg[4] <= 1'b1;

	           if (time_counter_reg >= timebase_reg) begin
	               time_counter_reg <= 0;
	               channel_0_acc_reg <= channel_0_input_wide;
	               channel_1_acc_reg <= channel_1_input_wide;

	               channel_0_data_reg <= channel_0_acc_reg;
	               channel_1_data_reg <= channel_1_acc_reg;
	               data_write_enable_reg <= 1'b1;
	               data_write_addr_reg <= data_addr_reg;
	               data_addr_reg <= data_addr_reg + 1;
	           end
	           else begin
	               time_counter_reg <= time_counter_reg + 1;
	               channel_0_acc_reg <= channel_0_acc_reg + channel_0_input_wide;
	               channel_1_acc_reg <= channel_1_acc_reg + channel_1_input_wide;

	               channel_0_data_reg <= channel_0_data_reg;
	               channel_1_data_reg <= channel_1_data_reg;
	               data_addr_reg <= data_addr_reg;
	               data_write_addr_reg <= data_write_addr_reg;
	               data_write_enable_reg <= 1'b0;
	           end
	       end
	   end
	end
	// User logic ends

endmodule
