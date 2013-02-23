#!/bin/bash

# Create temporary work directory
mkdir -p xst/projnav.tmp

# Create project file
cat > top_level.prj <<EOF
vhdl work "top_level.vhdl"
EOF

# Create xst file
cat > top_level.xst <<EOF
set -tmpdir "xst/projnav.tmp"
set -xsthdpdir "xst"
run
-ifn top_level.prj
-ifmt mixed
-ofn top_level
-ofmt NGC
-p xc9500xl
-top top_level
-opt_mode Speed
-opt_level 1
-iuc NO
-keep_hierarchy Yes
-netlist_hierarchy As_Optimized
-rtlview Yes
-hierarchy_separator /
-bus_delimiter <>
-case Maintain
-verilog2001 YES
-fsm_extract YES -fsm_encoding Auto
-safe_implementation No
-mux_extract Yes
-resource_sharing YES
-iobuf YES
-pld_mp YES
-pld_xp YES
-pld_ce YES
-wysiwyg NO
-equivalent_register_removal YES
EOF

# Create iMPACT batch file
cat > impact.batch <<EOF
setPreference -pref AutoSignature:FALSE
setPreference -pref KeepSVF:TRUE
setPreference -pref ConcurrentMode:FALSE
setPreference -pref UseHighz:FALSE
setPreference -pref svfUseTime:FALSE
setPreference -pref SpiByteSwap:AUTO_CORRECTION
setMode -bs
setMode -bs
setMode -bs
setMode -bs
setCable -port xsvf -file top_level.xsvf
addDevice -p 1 -file top_level.jed
erase -p 1
program -p 1
deleteDevice -position 1
quit
EOF

# Run synthesis
xst -intstyle ise -ifn top_level.xst -ofn top_level.syr

# Run ngdbuild
ngdbuild -intstyle ise -dd _ngo -uc top_level.ucf -p xc9572xl-VQ44-10 top_level.ngc top_level.ngd

# Run fitter
cpldfit -intstyle ise -p xc9572xl-10-VQ44 -ofmt vhdl -optimize speed -htmlrpt -loc on -slew fast -init low -inputs 54 -pterms 25 -unused float -power std -terminate keeper top_level.ngd

# Generate .jed file
hprep6 -s IEEE1149 -n top_level -i top_level 

# Generate xsvf & svf files
impact -batch impact.batch
