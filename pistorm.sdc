## Generated SDC file "pistorm.sdc"

## Copyright (C) 2020  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 20.1.1 Build 720 11/11/2020 SJ Lite Edition"

## DATE    "Sun Dec 20 15:18:48 2020"

##
## DEVICE  "EPM240T100C5"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {PI_CLK} -period 5.000 [get_ports {PI_CLK}]
create_clock -name {M68K_CLK} -period 141.000 [get_ports {M68K_CLK}]
create_clock -name {M68K_C1} -period 282.000 [get_ports {M68K_C1}]
create_clock -name {M68K_C3} -period 282.000 [get_ports {M68K_C3}]

#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

# Only the first stage of each explicit synchronizer is exempt from setup/hold
# analysis.  Paths from synchronizer stage 1 onward remain in the PI_CLK domain
# and are analyzed.  Do not blanket-false-path all external inputs/outputs: that
# would hide the bus-control paths this design must prove.
set_false_path -from [get_ports {M68K_CLK M68K_C1 M68K_C3}] \
  -to [get_registers {c7m_sync[0]}]
set_false_path -from [get_ports {M68K_DTACK_n M68K_BERR_n M68K_VPA_n}] \
  -to [get_registers {dtack_sync[0] berr_sync[0] vpa_sync[0]}]
set_false_path -from [get_ports {M68K_BR_n M68K_BGACK_n}] \
  -to [get_registers {br_sync[0] bgack_sync[0]}]
set_false_path -from [get_ports {M68K_IPL_n[*]}] \
  -to [get_registers {ipl_1[0] ipl_1[1] ipl_1[2]}]

#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

