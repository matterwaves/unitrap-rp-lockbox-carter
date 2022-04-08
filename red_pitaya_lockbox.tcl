# Set the project name
set _xil_proj_name_ "red_pitaya_lockbox"

variable script_file
set script_file "red_pitaya_lockbox.tcl"

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "."]"

# Create project
create_project ${_xil_proj_name_} ./${_xil_proj_name_} -part xc7z010clg400-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "0" -objects $obj
set_property -name "part" -value "xc7z010clg400-1" -objects $obj
set_property -name "platform.board_id" -value "redpitaya" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Verilog" -objects $obj
set_property -name "webtalk.activehdl_export_sim" -value "97" -objects $obj
set_property -name "webtalk.ies_export_sim" -value "91" -objects $obj
set_property -name "webtalk.modelsim_export_sim" -value "97" -objects $obj
set_property -name "webtalk.questa_export_sim" -value "97" -objects $obj
set_property -name "webtalk.riviera_export_sim" -value "97" -objects $obj
set_property -name "webtalk.vcs_export_sim" -value "97" -objects $obj
set_property -name "webtalk.xsim_export_sim" -value "97" -objects $obj
set_property -name "webtalk.xsim_launch_sim" -value "6" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_MEMORY" -objects $obj

# Import local files from the original project
set files [list \
			   [file normalize "axi_lockbox.v" ]\
			   [file normalize "diff_io_mgr.v" ]\
			   [file normalize "dac_splitter.v" ]\
			   [file normalize "axi_scope.v" ]\
			   [file normalize "pid_loop.v" ]\
			   [file normalize "ramp_module.v" ]\
			  ]
set imported_files [import_files -fileset sources_1 $files]

# Set 'sources_1' fileset properties
set_property -name "top" -value "system_wrapper" -objects [get_filesets sources_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "clocks.xdc"]"
set file_imported [import_files -fileset constrs_1 [list $file]]
set file "clocks.xdc"
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Add/Import constrs file and set constrs file properties
set file "[file normalize "ports.xdc"]"
set file_imported [import_files -fileset constrs_1 [list $file]]
set file "ports.xdc"
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set_property -name "target_part" -value "xc7z010clg400-1" -objects [get_filesets constrs_1]

# Proc to create BD system
proc cr_bd_system {} {
	set design_name system

	create_bd_design $design_name

	variable script_folder

	set parentCell [get_bd_cells /]

	# Get object for parentCell
	set parentObj [get_bd_cells $parentCell]

	# Make sure parentObj is hier blk
	set parentType [get_property TYPE $parentObj]

	# Save current instance; Restore later
	set oldCurInst [current_bd_instance .]

	# Set parent object as current
	current_bd_instance $parentObj

	# Create interface ports
	set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
	set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]
	set Vaux0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux0 ]
	set Vaux1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux1 ]
	set Vaux8 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux8 ]
	set Vaux9 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux9 ]
	set Vp_Vn [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vp_Vn ]

	# Create ports
	set adc_clk_n_i [ create_bd_port -dir I adc_clk_n_i ]
	set adc_clk_p_i [ create_bd_port -dir I adc_clk_p_i ]
	set adc_csn_o [ create_bd_port -dir O adc_csn_o ]
	set adc_dat_a_i [ create_bd_port -dir I -from 13 -to 0 adc_dat_a_i ]
	set adc_dat_b_i [ create_bd_port -dir I -from 13 -to 0 adc_dat_b_i ]
	set adc_enc_n_o [ create_bd_port -dir O adc_enc_n_o ]
	set adc_enc_p_o [ create_bd_port -dir O adc_enc_p_o ]
	set dac_clk_o [ create_bd_port -dir O dac_clk_o ]
	set dac_dat_o [ create_bd_port -dir O -from 13 -to 0 dac_dat_o ]
	set dac_pwm_o [ create_bd_port -dir O -from 3 -to 0 dac_pwm_o ]
	set dac_rst_o [ create_bd_port -dir O -from 0 -to 0 dac_rst_o ]
	set dac_sel_o [ create_bd_port -dir O dac_sel_o ]
	set dac_wrt_o [ create_bd_port -dir O dac_wrt_o ]
	set exp_n_tri_io [ create_bd_port -dir IO -from 7 -to 0 exp_n_tri_io ]
	set exp_p_tri_io [ create_bd_port -dir IO -from 7 -to 0 exp_p_tri_io ]
	set led_o [ create_bd_port -dir O -from 7 -to 0 led_o ]

	# Create instance: axi_lockbox_0, and set properties
	set axi_lockbox_0 [create_bd_cell -type module -reference axi_lockbox axi_lockbox_0]

	# Create instance: axi_bram_ctrl_0, and set properties
	set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
	set_property -dict [ list \
							 CONFIG.SINGLE_PORT_BRAM {1} \
							] $axi_bram_ctrl_0

	# Create instance: axi_bram_ctrl_1, and set properties
	set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_1 ]
	set_property -dict [ list \
							 CONFIG.SINGLE_PORT_BRAM {1} \
							] $axi_bram_ctrl_1

	# Create instance: axi_scope_0, and set properties
	set block_name axi_scope
	set block_cell_name axi_scope_0
	set axi_scope_0 [create_bd_cell -type module -reference axi_scope axi_scope_0]

	# Create instance: blk_mem_gen_0, and set properties
	set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
	set_property -dict [ list \
							 CONFIG.Assume_Synchronous_Clk {true} \
							 CONFIG.Byte_Size {9} \
							 CONFIG.EN_SAFETY_CKT {false} \
							 CONFIG.Enable_32bit_Address {false} \
							 CONFIG.Enable_A {Use_ENA_Pin} \
							 CONFIG.Enable_B {Always_Enabled} \
							 CONFIG.Fill_Remaining_Memory_Locations {true} \
							 CONFIG.Remaining_Memory_Locations {0} \
							 CONFIG.Memory_Type {True_Dual_Port_RAM} \
							 CONFIG.Operating_Mode_A {WRITE_FIRST} \
							 CONFIG.Operating_Mode_B {WRITE_FIRST} \
							 CONFIG.Port_B_Clock {100} \
							 CONFIG.Port_B_Enable_Rate {100} \
							 CONFIG.Port_B_Write_Rate {50} \
							 CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
							 CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
							 CONFIG.Use_Byte_Write_Enable {false} \
							 CONFIG.Use_RSTA_Pin {false} \
							 CONFIG.Use_RSTB_Pin {false} \
							 CONFIG.Write_Depth_A {8192} \
							 CONFIG.use_bram_block {Stand_Alone} \
							] $blk_mem_gen_0

	# Create instance: blk_mem_gen_1, and set properties
	set blk_mem_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_1 ]
	set_property -dict [ list \
							 CONFIG.Assume_Synchronous_Clk {true} \
							 CONFIG.Byte_Size {9} \
							 CONFIG.EN_SAFETY_CKT {false} \
							 CONFIG.Enable_32bit_Address {false} \
							 CONFIG.Enable_A {Use_ENA_Pin} \
							 CONFIG.Enable_B {Always_Enabled} \
							 CONFIG.Fill_Remaining_Memory_Locations {true} \
							 CONFIG.Remaining_Memory_Locations {0} \
							 CONFIG.Memory_Type {True_Dual_Port_RAM} \
							 CONFIG.Operating_Mode_A {WRITE_FIRST} \
							 CONFIG.Operating_Mode_B {WRITE_FIRST} \
							 CONFIG.Port_B_Clock {100} \
							 CONFIG.Port_B_Enable_Rate {100} \
							 CONFIG.Port_B_Write_Rate {50} \
							 CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
							 CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
							 CONFIG.Use_Byte_Write_Enable {false} \
							 CONFIG.Use_RSTA_Pin {false} \
							 CONFIG.Use_RSTB_Pin {false} \
							 CONFIG.Write_Depth_A {8192} \
							 CONFIG.use_bram_block {Stand_Alone} \
							] $blk_mem_gen_1

	# Create instance: clk_wiz_0, and set properties
	set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
	set_property -dict [ list \
							 CONFIG.CLKIN1_JITTER_PS {80.0} \
							 CONFIG.CLKOUT1_DRIVES {BUFG} \
							 CONFIG.CLKOUT1_JITTER {119.348} \
							 CONFIG.CLKOUT1_PHASE_ERROR {96.948} \
							 CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {125} \
							 CONFIG.CLKOUT2_DRIVES {BUFG} \
							 CONFIG.CLKOUT2_JITTER {104.759} \
							 CONFIG.CLKOUT2_PHASE_ERROR {96.948} \
							 CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {250} \
							 CONFIG.CLKOUT2_REQUESTED_PHASE {-45} \
							 CONFIG.CLKOUT2_USED {true} \
							 CONFIG.CLKOUT3_DRIVES {BUFG} \
							 CONFIG.CLKOUT3_JITTER {124.615} \
							 CONFIG.CLKOUT3_PHASE_ERROR {96.948} \
							 CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {125} \
							 CONFIG.CLKOUT3_REQUESTED_PHASE {90} \
							 CONFIG.CLKOUT3_USED {false} \
							 CONFIG.CLKOUT4_DRIVES {BUFG} \
							 CONFIG.CLKOUT4_JITTER {124.615} \
							 CONFIG.CLKOUT4_PHASE_ERROR {96.948} \
							 CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {62.5} \
							 CONFIG.CLKOUT4_REQUESTED_PHASE {0} \
							 CONFIG.CLKOUT4_USED {false} \
							 CONFIG.CLKOUT5_DRIVES {BUFG} \
							 CONFIG.CLKOUT6_DRIVES {BUFG} \
							 CONFIG.CLKOUT7_DRIVES {BUFG} \
							 CONFIG.CLK_OUT2_PORT {dac_clk} \
							 CONFIG.CLK_OUT3_PORT {clk_out3} \
							 CONFIG.CLK_OUT4_PORT {dac_sel} \
							 CONFIG.MMCM_CLKFBOUT_MULT_F {8} \
							 CONFIG.MMCM_CLKIN1_PERIOD {8.000} \
							 CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
							 CONFIG.MMCM_CLKOUT0_DIVIDE_F {8} \
							 CONFIG.MMCM_CLKOUT1_DIVIDE {4} \
							 CONFIG.MMCM_CLKOUT1_PHASE {-45.000} \
							 CONFIG.MMCM_CLKOUT2_DIVIDE {1} \
							 CONFIG.MMCM_CLKOUT2_PHASE {90.000} \
							 CONFIG.MMCM_CLKOUT3_DIVIDE {1} \
							 CONFIG.MMCM_CLKOUT3_PHASE {0.000} \
							 CONFIG.MMCM_COMPENSATION {ZHOLD} \
							 CONFIG.MMCM_DIVCLK_DIVIDE {1} \
							 CONFIG.NUM_OUT_CLKS {2} \
							 CONFIG.PRIMITIVE {PLL} \
							 CONFIG.PRIM_IN_FREQ {125.000} \
							 CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
							 CONFIG.USE_RESET {false} \
							] $clk_wiz_0

	# Create instance: dac_splitter_0, and set properties
	set dac_splitter_0 [create_bd_cell -type module -reference dac_splitter dac_splitter_0]

	# Create instance: diff_io_mgr_0, and set properties
	set diff_io_mgr_0 [create_bd_cell -type module -reference diff_io_mgr diff_io_mgr_0]
    set_property -dict [ list \
							 CONFIG.OUTPUT_WIDTH {2} \
							] $diff_io_mgr_0

	# Create instance: ps_0, and set properties
	set ps_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps_0 ]
	set_property -dict [ list \
							 CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {666.666687} \
							 CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {10.000000} \
							 CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.158730} \
							 CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {125.000000} \
							 CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
							 CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {50.000000} \
							 CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {10.000000} \
							 CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {10.000000} \
							 CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
							 CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
							 CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {10.000000} \
							 CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {100.000000} \
							 CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
							 CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {166.666672} \
							 CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
							 CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
							 CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
							 CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
							 CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
							 CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
							 CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
							 CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {100.000000} \
							 CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {111.111115} \
							 CONFIG.PCW_ARMPLL_CTRL_FBDIV {40} \
							 CONFIG.PCW_CAN_PERIPHERAL_DIVISOR0 {1} \
							 CONFIG.PCW_CAN_PERIPHERAL_DIVISOR1 {1} \
							 CONFIG.PCW_CLK0_FREQ {50000000} \
							 CONFIG.PCW_CLK1_FREQ {10000000} \
							 CONFIG.PCW_CLK2_FREQ {10000000} \
							 CONFIG.PCW_CLK3_FREQ {10000000} \
							 CONFIG.PCW_CPU_CPU_PLL_FREQMHZ {1333.333} \
							 CONFIG.PCW_CPU_PERIPHERAL_DIVISOR0 {2} \
							 CONFIG.PCW_DCI_PERIPHERAL_DIVISOR0 {15} \
							 CONFIG.PCW_DCI_PERIPHERAL_DIVISOR1 {7} \
							 CONFIG.PCW_DDRPLL_CTRL_FBDIV {32} \
							 CONFIG.PCW_DDR_DDR_PLL_FREQMHZ {1066.667} \
							 CONFIG.PCW_DDR_PERIPHERAL_DIVISOR0 {2} \
							 CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
							 CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {0} \
							 CONFIG.PCW_ENET0_PERIPHERAL_CLKSRC {IO PLL} \
							 CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR0 {8} \
							 CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR1 {1} \
							 CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
							 CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {1000 Mbps} \
							 CONFIG.PCW_ENET0_RESET_ENABLE {0} \
							 CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR0 {1} \
							 CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR1 {1} \
							 CONFIG.PCW_ENET1_RESET_ENABLE {0} \
							 CONFIG.PCW_ENET_RESET_ENABLE {1} \
							 CONFIG.PCW_ENET_RESET_SELECT {Share reset pin} \
							 CONFIG.PCW_EN_EMIO_ENET0 {0} \
							 CONFIG.PCW_EN_EMIO_GPIO {1} \
							 CONFIG.PCW_EN_EMIO_SPI0 {1} \
							 CONFIG.PCW_EN_EMIO_SPI1 {0} \
							 CONFIG.PCW_EN_EMIO_UART0 {0} \
							 CONFIG.PCW_EN_ENET0 {1} \
							 CONFIG.PCW_EN_GPIO {1} \
							 CONFIG.PCW_EN_SDIO0 {1} \
							 CONFIG.PCW_EN_SPI0 {1} \
							 CONFIG.PCW_EN_SPI1 {1} \
							 CONFIG.PCW_EN_UART0 {1} \
							 CONFIG.PCW_EN_UART1 {1} \
							 CONFIG.PCW_EN_USB0 {1} \
							 CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR0 {5} \
							 CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR1 {4} \
							 CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR0 {1} \
							 CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR1 {1} \
							 CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR0 {1} \
							 CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR1 {1} \
							 CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR0 {1} \
							 CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR1 {1} \
							 CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
							 CONFIG.PCW_FPGA_FCLK1_ENABLE {0} \
							 CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
							 CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
							 CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} \
							 CONFIG.PCW_GPIO_EMIO_GPIO_IO {64} \
							 CONFIG.PCW_GPIO_EMIO_GPIO_WIDTH {64} \
							 CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
							 CONFIG.PCW_GPIO_MIO_GPIO_IO {MIO} \
							 CONFIG.PCW_I2C0_RESET_ENABLE {0} \
							 CONFIG.PCW_I2C1_RESET_ENABLE {0} \
							 CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {25} \
							 CONFIG.PCW_I2C_RESET_ENABLE {1} \
							 CONFIG.PCW_IOPLL_CTRL_FBDIV {30} \
							 CONFIG.PCW_IO_IO_PLL_FREQMHZ {1000.000} \
							 CONFIG.PCW_MIO_0_DIRECTION {inout} \
							 CONFIG.PCW_MIO_0_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_0_PULLUP {enabled} \
							 CONFIG.PCW_MIO_0_SLEW {slow} \
							 CONFIG.PCW_MIO_10_DIRECTION {inout} \
							 CONFIG.PCW_MIO_10_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_10_PULLUP {enabled} \
							 CONFIG.PCW_MIO_10_SLEW {slow} \
							 CONFIG.PCW_MIO_11_DIRECTION {inout} \
							 CONFIG.PCW_MIO_11_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_11_PULLUP {enabled} \
							 CONFIG.PCW_MIO_11_SLEW {slow} \
							 CONFIG.PCW_MIO_12_DIRECTION {inout} \
							 CONFIG.PCW_MIO_12_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_12_PULLUP {enabled} \
							 CONFIG.PCW_MIO_12_SLEW {slow} \
							 CONFIG.PCW_MIO_13_DIRECTION {inout} \
							 CONFIG.PCW_MIO_13_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_13_PULLUP {enabled} \
							 CONFIG.PCW_MIO_13_SLEW {slow} \
							 CONFIG.PCW_MIO_14_DIRECTION {in} \
							 CONFIG.PCW_MIO_14_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_14_PULLUP {enabled} \
							 CONFIG.PCW_MIO_14_SLEW {slow} \
							 CONFIG.PCW_MIO_15_DIRECTION {out} \
							 CONFIG.PCW_MIO_15_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_15_PULLUP {enabled} \
							 CONFIG.PCW_MIO_15_SLEW {slow} \
							 CONFIG.PCW_MIO_16_DIRECTION {out} \
							 CONFIG.PCW_MIO_16_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_16_PULLUP {enabled} \
							 CONFIG.PCW_MIO_16_SLEW {slow} \
							 CONFIG.PCW_MIO_17_DIRECTION {out} \
							 CONFIG.PCW_MIO_17_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_17_PULLUP {enabled} \
							 CONFIG.PCW_MIO_17_SLEW {slow} \
							 CONFIG.PCW_MIO_18_DIRECTION {out} \
							 CONFIG.PCW_MIO_18_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_18_PULLUP {enabled} \
							 CONFIG.PCW_MIO_18_SLEW {slow} \
							 CONFIG.PCW_MIO_19_DIRECTION {out} \
							 CONFIG.PCW_MIO_19_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_19_PULLUP {enabled} \
							 CONFIG.PCW_MIO_19_SLEW {slow} \
							 CONFIG.PCW_MIO_1_DIRECTION {inout} \
							 CONFIG.PCW_MIO_1_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_1_PULLUP {enabled} \
							 CONFIG.PCW_MIO_1_SLEW {slow} \
							 CONFIG.PCW_MIO_20_DIRECTION {out} \
							 CONFIG.PCW_MIO_20_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_20_PULLUP {enabled} \
							 CONFIG.PCW_MIO_20_SLEW {slow} \
							 CONFIG.PCW_MIO_21_DIRECTION {out} \
							 CONFIG.PCW_MIO_21_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_21_PULLUP {enabled} \
							 CONFIG.PCW_MIO_21_SLEW {slow} \
							 CONFIG.PCW_MIO_22_DIRECTION {in} \
							 CONFIG.PCW_MIO_22_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_22_PULLUP {enabled} \
							 CONFIG.PCW_MIO_22_SLEW {slow} \
							 CONFIG.PCW_MIO_23_DIRECTION {in} \
							 CONFIG.PCW_MIO_23_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_23_PULLUP {enabled} \
							 CONFIG.PCW_MIO_23_SLEW {slow} \
							 CONFIG.PCW_MIO_24_DIRECTION {in} \
							 CONFIG.PCW_MIO_24_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_24_PULLUP {enabled} \
							 CONFIG.PCW_MIO_24_SLEW {slow} \
							 CONFIG.PCW_MIO_25_DIRECTION {in} \
							 CONFIG.PCW_MIO_25_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_25_PULLUP {enabled} \
							 CONFIG.PCW_MIO_25_SLEW {slow} \
							 CONFIG.PCW_MIO_26_DIRECTION {in} \
							 CONFIG.PCW_MIO_26_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_26_PULLUP {enabled} \
							 CONFIG.PCW_MIO_26_SLEW {slow} \
							 CONFIG.PCW_MIO_27_DIRECTION {in} \
							 CONFIG.PCW_MIO_27_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_27_PULLUP {enabled} \
							 CONFIG.PCW_MIO_27_SLEW {slow} \
							 CONFIG.PCW_MIO_28_DIRECTION {inout} \
							 CONFIG.PCW_MIO_28_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_28_PULLUP {enabled} \
							 CONFIG.PCW_MIO_28_SLEW {slow} \
							 CONFIG.PCW_MIO_29_DIRECTION {in} \
							 CONFIG.PCW_MIO_29_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_29_PULLUP {enabled} \
							 CONFIG.PCW_MIO_29_SLEW {slow} \
							 CONFIG.PCW_MIO_2_DIRECTION {inout} \
							 CONFIG.PCW_MIO_2_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_2_PULLUP {disabled} \
							 CONFIG.PCW_MIO_2_SLEW {slow} \
							 CONFIG.PCW_MIO_30_DIRECTION {out} \
							 CONFIG.PCW_MIO_30_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_30_PULLUP {enabled} \
							 CONFIG.PCW_MIO_30_SLEW {slow} \
							 CONFIG.PCW_MIO_31_DIRECTION {in} \
							 CONFIG.PCW_MIO_31_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_31_PULLUP {enabled} \
							 CONFIG.PCW_MIO_31_SLEW {slow} \
							 CONFIG.PCW_MIO_32_DIRECTION {inout} \
							 CONFIG.PCW_MIO_32_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_32_PULLUP {enabled} \
							 CONFIG.PCW_MIO_32_SLEW {slow} \
							 CONFIG.PCW_MIO_33_DIRECTION {inout} \
							 CONFIG.PCW_MIO_33_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_33_PULLUP {enabled} \
							 CONFIG.PCW_MIO_33_SLEW {slow} \
							 CONFIG.PCW_MIO_34_DIRECTION {inout} \
							 CONFIG.PCW_MIO_34_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_34_PULLUP {enabled} \
							 CONFIG.PCW_MIO_34_SLEW {slow} \
							 CONFIG.PCW_MIO_35_DIRECTION {inout} \
							 CONFIG.PCW_MIO_35_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_35_PULLUP {enabled} \
							 CONFIG.PCW_MIO_35_SLEW {slow} \
							 CONFIG.PCW_MIO_36_DIRECTION {in} \
							 CONFIG.PCW_MIO_36_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_36_PULLUP {enabled} \
							 CONFIG.PCW_MIO_36_SLEW {slow} \
							 CONFIG.PCW_MIO_37_DIRECTION {inout} \
							 CONFIG.PCW_MIO_37_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_37_PULLUP {enabled} \
							 CONFIG.PCW_MIO_37_SLEW {slow} \
							 CONFIG.PCW_MIO_38_DIRECTION {inout} \
							 CONFIG.PCW_MIO_38_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_38_PULLUP {enabled} \
							 CONFIG.PCW_MIO_38_SLEW {slow} \
							 CONFIG.PCW_MIO_39_DIRECTION {inout} \
							 CONFIG.PCW_MIO_39_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_39_PULLUP {enabled} \
							 CONFIG.PCW_MIO_39_SLEW {slow} \
							 CONFIG.PCW_MIO_3_DIRECTION {inout} \
							 CONFIG.PCW_MIO_3_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_3_PULLUP {disabled} \
							 CONFIG.PCW_MIO_3_SLEW {slow} \
							 CONFIG.PCW_MIO_40_DIRECTION {inout} \
							 CONFIG.PCW_MIO_40_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_40_PULLUP {enabled} \
							 CONFIG.PCW_MIO_40_SLEW {slow} \
							 CONFIG.PCW_MIO_41_DIRECTION {inout} \
							 CONFIG.PCW_MIO_41_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_41_PULLUP {enabled} \
							 CONFIG.PCW_MIO_41_SLEW {slow} \
							 CONFIG.PCW_MIO_42_DIRECTION {inout} \
							 CONFIG.PCW_MIO_42_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_42_PULLUP {enabled} \
							 CONFIG.PCW_MIO_42_SLEW {slow} \
							 CONFIG.PCW_MIO_43_DIRECTION {inout} \
							 CONFIG.PCW_MIO_43_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_43_PULLUP {enabled} \
							 CONFIG.PCW_MIO_43_SLEW {slow} \
							 CONFIG.PCW_MIO_44_DIRECTION {inout} \
							 CONFIG.PCW_MIO_44_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_44_PULLUP {enabled} \
							 CONFIG.PCW_MIO_44_SLEW {slow} \
							 CONFIG.PCW_MIO_45_DIRECTION {inout} \
							 CONFIG.PCW_MIO_45_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_45_PULLUP {enabled} \
							 CONFIG.PCW_MIO_45_SLEW {slow} \
							 CONFIG.PCW_MIO_46_DIRECTION {inout} \
							 CONFIG.PCW_MIO_46_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_46_PULLUP {enabled} \
							 CONFIG.PCW_MIO_46_SLEW {slow} \
							 CONFIG.PCW_MIO_47_DIRECTION {inout} \
							 CONFIG.PCW_MIO_47_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_47_PULLUP {enabled} \
							 CONFIG.PCW_MIO_47_SLEW {slow} \
							 CONFIG.PCW_MIO_48_DIRECTION {inout} \
							 CONFIG.PCW_MIO_48_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_48_PULLUP {enabled} \
							 CONFIG.PCW_MIO_48_SLEW {slow} \
							 CONFIG.PCW_MIO_49_DIRECTION {inout} \
							 CONFIG.PCW_MIO_49_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_49_PULLUP {enabled} \
							 CONFIG.PCW_MIO_49_SLEW {slow} \
							 CONFIG.PCW_MIO_4_DIRECTION {inout} \
							 CONFIG.PCW_MIO_4_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_4_PULLUP {disabled} \
							 CONFIG.PCW_MIO_4_SLEW {slow} \
							 CONFIG.PCW_MIO_50_DIRECTION {inout} \
							 CONFIG.PCW_MIO_50_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_50_PULLUP {enabled} \
							 CONFIG.PCW_MIO_50_SLEW {slow} \
							 CONFIG.PCW_MIO_51_DIRECTION {inout} \
							 CONFIG.PCW_MIO_51_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_51_PULLUP {enabled} \
							 CONFIG.PCW_MIO_51_SLEW {slow} \
							 CONFIG.PCW_MIO_52_DIRECTION {inout} \
							 CONFIG.PCW_MIO_52_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_52_PULLUP {enabled} \
							 CONFIG.PCW_MIO_52_SLEW {slow} \
							 CONFIG.PCW_MIO_53_DIRECTION {inout} \
							 CONFIG.PCW_MIO_53_IOTYPE {LVCMOS 2.5V} \
							 CONFIG.PCW_MIO_53_PULLUP {enabled} \
							 CONFIG.PCW_MIO_53_SLEW {slow} \
							 CONFIG.PCW_MIO_5_DIRECTION {inout} \
							 CONFIG.PCW_MIO_5_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_5_PULLUP {disabled} \
							 CONFIG.PCW_MIO_5_SLEW {slow} \
							 CONFIG.PCW_MIO_6_DIRECTION {inout} \
							 CONFIG.PCW_MIO_6_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_6_PULLUP {disabled} \
							 CONFIG.PCW_MIO_6_SLEW {slow} \
							 CONFIG.PCW_MIO_7_DIRECTION {out} \
							 CONFIG.PCW_MIO_7_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_7_PULLUP {disabled} \
							 CONFIG.PCW_MIO_7_SLEW {slow} \
							 CONFIG.PCW_MIO_8_DIRECTION {out} \
							 CONFIG.PCW_MIO_8_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_8_PULLUP {disabled} \
							 CONFIG.PCW_MIO_8_SLEW {slow} \
							 CONFIG.PCW_MIO_9_DIRECTION {in} \
							 CONFIG.PCW_MIO_9_IOTYPE {LVCMOS 3.3V} \
							 CONFIG.PCW_MIO_9_PULLUP {enabled} \
							 CONFIG.PCW_MIO_9_SLEW {slow} \
							 CONFIG.PCW_MIO_TREE_PERIPHERALS {\
																  GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#UART 1#UART 1#SPI 1#SPI 1#SPI 1#SPI\
																  1#UART 0#UART 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet\
																  0#Enet 0#Enet 0#Enet 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB\
																  0#USB 0#USB 0#USB 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD\
																  0#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO} \
							 CONFIG.PCW_MIO_TREE_SIGNALS {\
															  gpio[0]#gpio[1]#gpio[2]#gpio[3]#gpio[4]#gpio[5]#gpio[6]#gpio[7]#tx#rx#mosi#miso#sclk#ss[0]#rx#tx#tx_clk#txd[0]#txd[1]#txd[2]#txd[3]#tx_ctl#rx_clk#rxd[0]#rxd[1]#rxd[2]#rxd[3]#rx_ctl#data[4]#dir#stp#nxt#data[0]#data[1]#data[2]#data[3]#clk#data[5]#data[6]#data[7]#clk#cmd#data[0]#data[1]#data[2]#data[3]#gpio[46]#gpio[47]#gpio[48]#gpio[49]#gpio[50]#gpio[51]#gpio[52]#gpio[53]} \
							 CONFIG.PCW_PCAP_PERIPHERAL_DIVISOR0 {5} \
							 CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 2.5V} \
							 CONFIG.PCW_QSPI_PERIPHERAL_DIVISOR0 {1} \
							 CONFIG.PCW_SD0_GRP_CD_ENABLE {0} \
							 CONFIG.PCW_SD0_GRP_POW_ENABLE {0} \
							 CONFIG.PCW_SD0_GRP_WP_ENABLE {0} \
							 CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
							 CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
							 CONFIG.PCW_SDIO_PERIPHERAL_DIVISOR0 {10} \
							 CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {100} \
							 CONFIG.PCW_SDIO_PERIPHERAL_VALID {1} \
							 CONFIG.PCW_SMC_PERIPHERAL_DIVISOR0 {1} \
							 CONFIG.PCW_SPI0_GRP_SS0_ENABLE {1} \
							 CONFIG.PCW_SPI0_GRP_SS0_IO {EMIO} \
							 CONFIG.PCW_SPI0_GRP_SS1_ENABLE {1} \
							 CONFIG.PCW_SPI0_GRP_SS1_IO {EMIO} \
							 CONFIG.PCW_SPI0_GRP_SS2_ENABLE {1} \
							 CONFIG.PCW_SPI0_GRP_SS2_IO {EMIO} \
							 CONFIG.PCW_SPI0_PERIPHERAL_ENABLE {1} \
							 CONFIG.PCW_SPI0_SPI0_IO {EMIO} \
							 CONFIG.PCW_SPI1_GRP_SS0_ENABLE {1} \
							 CONFIG.PCW_SPI1_GRP_SS0_IO {MIO 13} \
							 CONFIG.PCW_SPI1_GRP_SS1_ENABLE {0} \
							 CONFIG.PCW_SPI1_GRP_SS2_ENABLE {0} \
							 CONFIG.PCW_SPI1_PERIPHERAL_ENABLE {1} \
							 CONFIG.PCW_SPI1_SPI1_IO {MIO 10 .. 15} \
							 CONFIG.PCW_SPI_PERIPHERAL_DIVISOR0 {6} \
							 CONFIG.PCW_SPI_PERIPHERAL_FREQMHZ {166.666666} \
							 CONFIG.PCW_SPI_PERIPHERAL_VALID {1} \
							 CONFIG.PCW_TPIU_PERIPHERAL_DIVISOR0 {1} \
							 CONFIG.PCW_UART0_GRP_FULL_ENABLE {0} \
							 CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
							 CONFIG.PCW_UART0_UART0_IO {MIO 14 .. 15} \
							 CONFIG.PCW_UART1_GRP_FULL_ENABLE {0} \
							 CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
							 CONFIG.PCW_UART1_UART1_IO {MIO 8 .. 9} \
							 CONFIG.PCW_UART_PERIPHERAL_DIVISOR0 {10} \
							 CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {100} \
							 CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
							 CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333374} \
							 CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
							 CONFIG.PCW_USB0_PERIPHERAL_FREQMHZ {60} \
							 CONFIG.PCW_USB0_RESET_ENABLE {0} \
							 CONFIG.PCW_USB0_USB0_IO {MIO 28 .. 39} \
							 CONFIG.PCW_USB1_RESET_ENABLE {0} \
							 CONFIG.PCW_USB_RESET_ENABLE {1} \
							 CONFIG.PCW_USB_RESET_SELECT {Share reset pin} \
							 CONFIG.PCW_USE_S_AXI_HP0 {1} \
							] $ps_0

	# Create instance: ps_0_axi_periph, and set properties
	set ps_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps_0_axi_periph ]
	set_property -dict [ list \
							 CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
							 CONFIG.NUM_MI {4} \
							] $ps_0_axi_periph

	# Create instance: rst_0, and set properties
	set rst_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_0 ]
	set_property -dict [ list \
							 CONFIG.C_AUX_RESET_HIGH {0} \
							] $rst_0

	# Create instance: xlconcat_0, and set properties
	set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]

	# Create instance: xlconstant_0, and set properties
	set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

	# Create instance: xlconstant_2, and set properties
	set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_2 ]
	set_property -dict [ list \
							 CONFIG.CONST_VAL {8191} \
							 CONFIG.CONST_WIDTH {14} \
							] $xlconstant_2

	# Create interface connections
	connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins ps_0/M_AXI_GP0] [get_bd_intf_pins ps_0_axi_periph/S00_AXI]
	connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
	connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTA]
	connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins ps_0/DDR]
	connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins ps_0/FIXED_IO]
	connect_bd_intf_net -intf_net ps_0_axi_periph_M00_AXI [get_bd_intf_pins axi_lockbox_0/S_AXI] [get_bd_intf_pins ps_0_axi_periph/M00_AXI]
	connect_bd_intf_net -intf_net ps_0_axi_periph_M01_AXI [get_bd_intf_pins axi_scope_0/S_AXI] [get_bd_intf_pins ps_0_axi_periph/M01_AXI]
	connect_bd_intf_net -intf_net ps_0_axi_periph_M02_AXI [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_pins ps_0_axi_periph/M02_AXI]
	connect_bd_intf_net -intf_net ps_0_axi_periph_M03_AXI [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins ps_0_axi_periph/M03_AXI]

	# Create port connections
	connect_bd_net -net axi_lockbox_0_autolock_input_cpy [get_bd_pins axi_lockbox_0/autolock_input_cpy] [get_bd_pins axi_scope_0/channel_1_input]
	connect_bd_net -net axi_lockbox_0_axi_pi_output [get_bd_pins axi_lockbox_0/axi_pi_output] [get_bd_pins dac_splitter_0/din_a]
	connect_bd_net -net axi_lockbox_0_input_reset [get_bd_pins axi_lockbox_0/input_reset] [get_bd_pins xlconcat_0/In0]
	connect_bd_net -net axi_lockbox_0_loop_locked [get_bd_pins axi_lockbox_0/loop_locked] [get_bd_pins axi_scope_0/trigger1] [get_bd_pins xlconcat_0/In1]
	connect_bd_net -net axi_lockbox_0_pid_loop_input_cpy [get_bd_pins axi_lockbox_0/pid_loop_input_cpy] [get_bd_pins axi_scope_0/channel_0_input]
	connect_bd_net -net axi_lockbox_0_ramp_start [get_bd_pins axi_lockbox_0/ramp_start] [get_bd_pins axi_scope_0/trigger0]
	connect_bd_net -net Net [get_bd_ports exp_n_tri_io] [get_bd_pins diff_io_mgr_0/dout_n]
	connect_bd_net -net Net1 [get_bd_ports exp_p_tri_io] [get_bd_pins diff_io_mgr_0/dout_p]
	connect_bd_net -net adc_clk_n_i_1 [get_bd_ports adc_clk_n_i] [get_bd_pins clk_wiz_0/clk_in1_n]
	connect_bd_net -net adc_clk_p_i_1 [get_bd_ports adc_clk_p_i] [get_bd_pins clk_wiz_0/clk_in1_p]
	connect_bd_net -net adc_dat_a_i_1 [get_bd_ports adc_dat_a_i] [get_bd_pins axi_lockbox_0/pid_loop_input]
	connect_bd_net -net adc_dat_b_i_1 [get_bd_ports adc_dat_b_i] [get_bd_pins axi_lockbox_0/autolock_input]
	connect_bd_net -net axi_scope_0_channel_0_data [get_bd_pins axi_scope_0/channel_0_data] [get_bd_pins blk_mem_gen_0/dinb]
	connect_bd_net -net axi_scope_0_channel_1_data [get_bd_pins axi_scope_0/channel_1_data] [get_bd_pins blk_mem_gen_1/dinb]
	connect_bd_net -net axi_scope_0_data_write_enable [get_bd_pins axi_scope_0/data_write_enable] [get_bd_pins blk_mem_gen_0/web] [get_bd_pins blk_mem_gen_1/web]
	connect_bd_net -net axi_scope_0_write_addr [get_bd_pins axi_scope_0/write_addr] [get_bd_pins blk_mem_gen_0/addrb] [get_bd_pins blk_mem_gen_1/addrb]
	connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins axi_lockbox_0/S_AXI_ACLK] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins axi_scope_0/S_AXI_ACLK] [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins blk_mem_gen_1/clkb] [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins dac_splitter_0/clk] [get_bd_pins ps_0/M_AXI_GP0_ACLK] [get_bd_pins ps_0/S_AXI_HP0_ACLK] [get_bd_pins ps_0_axi_periph/ACLK] [get_bd_pins ps_0_axi_periph/M00_ACLK] [get_bd_pins ps_0_axi_periph/M01_ACLK] [get_bd_pins ps_0_axi_periph/M02_ACLK] [get_bd_pins ps_0_axi_periph/M03_ACLK] [get_bd_pins ps_0_axi_periph/S00_ACLK] [get_bd_pins rst_0/slowest_sync_clk]
	connect_bd_net -net clk_wiz_0_dac_clk [get_bd_pins clk_wiz_0/dac_clk] [get_bd_pins dac_splitter_0/dac_clk_i] [get_bd_pins dac_splitter_0/dac_wrt_i]
	connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins rst_0/dcm_locked]
	connect_bd_net -net dac_splitter_0_dac_clk_o [get_bd_ports dac_clk_o] [get_bd_pins dac_splitter_0/dac_clk_o]
	connect_bd_net -net dac_splitter_0_dac_rst_o [get_bd_ports dac_rst_o] [get_bd_pins dac_splitter_0/dac_rst_o]
	connect_bd_net -net dac_splitter_0_dac_sel_o [get_bd_ports dac_sel_o] [get_bd_pins dac_splitter_0/dac_sel_o]
	connect_bd_net -net dac_splitter_0_dac_wrt_o [get_bd_ports dac_wrt_o] [get_bd_pins dac_splitter_0/dac_wrt_o]
	connect_bd_net -net dac_splitter_0_dout [get_bd_ports dac_dat_o] [get_bd_pins dac_splitter_0/dout]
	connect_bd_net -net rst_0_peripheral_aresetn [get_bd_pins axi_lockbox_0/S_AXI_ARESETN] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins axi_scope_0/S_AXI_ARESETN] [get_bd_pins ps_0_axi_periph/ARESETN] [get_bd_pins ps_0_axi_periph/M00_ARESETN] [get_bd_pins ps_0_axi_periph/M01_ARESETN] [get_bd_pins ps_0_axi_periph/M02_ARESETN] [get_bd_pins ps_0_axi_periph/M03_ARESETN] [get_bd_pins ps_0_axi_periph/S00_ARESETN] [get_bd_pins rst_0/peripheral_aresetn]
	connect_bd_net -net rst_0_peripheral_reset [get_bd_pins dac_splitter_0/rst] [get_bd_pins rst_0/peripheral_reset]
	connect_bd_net -net xlconcat_0_dout [get_bd_pins diff_io_mgr_0/din] [get_bd_pins xlconcat_0/dout]
	connect_bd_net -net xlconstant_0_dout [get_bd_pins rst_0/ext_reset_in] [get_bd_pins xlconstant_0/dout]
	connect_bd_net -net xlconstant_2_dout [get_bd_pins dac_splitter_0/din_b] [get_bd_pins xlconstant_2/dout]

	# Create address segments
	assign_bd_address -offset 0x40000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_0/Data] [get_bd_addr_segs axi_lockbox_0/S_AXI/reg0] -force
	assign_bd_address -offset 0x40004000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_0/Data] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
	assign_bd_address -offset 0x40008000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_0/Data] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
	assign_bd_address -offset 0x40002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_0/Data] [get_bd_addr_segs axi_scope_0/S_AXI/reg0] -force

	# Restore current instance
	current_bd_instance $oldCurInst

	validate_bd_design
	save_bd_design
	close_bd_design $design_name 
}
# End of cr_bd_system()
cr_bd_system
set_property REGISTERED_WITH_MANAGER "1" [get_files system.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files system.bd ] 

#call make_wrapper to create wrapper files
set wrapper_path [make_wrapper -fileset sources_1 -files [ get_files -norecurse system.bd] -top]
add_files -norecurse -fileset sources_1 $wrapper_path

set idrFlowPropertiesConstraints ""
catch {
	set idrFlowPropertiesConstraints [get_param runs.disableIDRFlowPropertyConstraints]
	set_param runs.disableIDRFlowPropertyConstraints 1
}
