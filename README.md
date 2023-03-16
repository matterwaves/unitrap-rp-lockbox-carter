# unitrap-rp-lockbox-carter

FPGA gateware for Red Pitaya implementing a PI lockbox, forked from Carter Turnbaugh's [`Red Pitaya Lockbox`](https://gitlab.com/carterturn/red_pitaya_lockbox) project.

The corresponding server software is found at [`unitrap-rp-lockbox-carter-server`](https://github.com/matterwaves/unitrap-rp-lockbox-carter-server).

Last tested with Vivado ML Standard 2021.2 on Ubuntu 20.04.05 LTS.

Maintained by Lothar Maisenbacher/UC Berkeley.

## Original documentation from Carter

Work in progress.

## Installation on Red Pitaya

```
sudo -i
cd <repository_directory>
./scripts/<install_script>
exit
```

`<repository_directory>` is the root directory of this repository. For Red Pitayas based on Xilinx Zynq 7010 SoCs (including STEMlab 125-14), `<install_script>` is 'install.sh', while for Red Pitayas based on Xilinx Zynq 7020 SoCs (including STEMlab 125-14-Z7020), it is 'install_z20.sh'.

This will copy the correct bit file to '/opt/redpitaya/fpga', but not load it onto the FPGA. This is done by [unitrap-rp-lockbox-carter-server](https://github.com/matterwaves/unitrap-rp-lockbox-carter-server) at run time. 

## Compile FPGA gateware

### Installing Vivado

Work in progress.

### Generating Vivado project

This repository does not contain the actual Vivado project (with a '.xpr' project file), as this consists of many files that clog up the repository. However, Tcl scripts are included that generates the project file structure.

On Linux, this can be accomplished by running the script file `<tcl_script_file>` with (from the command line)

```
source <vivado_dir>/settings64.sh
vivado -source <tcl_script_file>
```

`<vivado_dir>` is the installation directory of Vivado where `settings64.sh` is located. This script sets environmental variables needed by Vivado and so on. For Vivado 2021.1, the default installation directory is '/tools/Xilinx/Vivado/2021.2'. The last command will open the Vivado GUI and generate the project.

There are two Tcl scripts included here:

- 'red_pitaya_lockbox.tcl': for Red Pitaya STEMlab 125-14 (standard or low-noise version), which uses a Xilink Zynq 7010 SoC (Xilinx part number 'xc7z010clg400-1'); generates project 'red_pitaya_lockbox'.

- 'red_pitaya_lockbox_z20.tcl': for Red Pitaya STEMlab 125-14-Z7020, which uses a Xilink Zynq 7020 SoC (Xilinx part number 'xc7z020clg400-1'); generates project 'red_pitaya_lockbox_z20'.

Note that the generated projects and bitstream files are not compatible between different SoCs.

Once the project is generated, the bitstream files can be generated by clicking on 'Generate Bitstream'. Once finished, the bit file is found in '<project_name>/<project_name>.runs/impl_1/system_wrapper.bit'.

### Transfering bit file to FPGA

Work in progress.
