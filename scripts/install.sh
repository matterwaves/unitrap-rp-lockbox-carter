#!/bin/bash
# This script might needs to be run as root (`sudo -i` or `su root`), not only with `sudo`,
# in order for the `rw` and `ro` commands to be available.
# Make '/opt/redpitaya' writeable
rw
cp ../build/rp_lockbox_carter.bit /opt/redpitaya/fpga/rp_lockbox_carter.bit
# Make '/opt/readpitaya' read-only
ro
