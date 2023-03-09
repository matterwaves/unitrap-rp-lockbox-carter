# unitrap-rp-lockbox-carter

FPGA gateware for Red Pitaya implementing a PI lockbox, forked from Carter Turnbaugh's [Red Pitaya Lockbox](https://gitlab.com/carterturn/red_pitaya_lockbox) project.

Last tested with Vivado ML Standard 2021.2 on Ubuntu 20.04.05 LTS.

Maintained by Lothar Maisenbacher/UC Berkeley.

## Generating Vivado project

This repository does not contain the actual Vivado project (with a '.xpr' project file), as this consists of many files that clog up the repository. However, Tcl scripts are included that generates the project file structure. This can be accomplished by running the script file `<tcl_script_file>` with (from the command line)

```
source <vivado_dir>/settings64.sh
vivado -source <tcl_script_file>
```

`<vivado_dir>` is the installation directory of Vivado where `settings64.sh` is located. This script sets environmental variables needed by Vivado and so on. For Vivado 2021.1, the default installation directory is `/tools/Xilinx/Vivado/2021.2`.

There are two Tcl scripts included here:

- 'red_pitaya_lockbox.tcl': for Red Pitaya STEMlab 125-14 (standard or low-noise version), which uses a Xilink Zynq 7010 SoC (Xilinx part number 'xc7z010clg400-1')

- 'red_pitaya_lockbox_z20.tcl': for Red Pitaya STEMlab 125-14-Z7020, which uses a Xilink Zynq 7020 SoC (Xilinx part number 'xc7z020clg400-1')

Note that the generated projects and bitstream files are not compatible between different SoCs.
