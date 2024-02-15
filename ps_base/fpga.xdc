#tri-color leds
set_property IOSTANDARD LVCMOS18 [get_ports {led0[*]}]
set_property SLEW SLOW [get_ports {led0[*]}]
set_property DRIVE 8 [get_ports {led0[*]}]
set_property PACKAGE_PIN A7 [ get_ports {led0[0]}]  ;#R
set_property PACKAGE_PIN B6 [ get_ports {led0[1]}]  ;#G
set_property PACKAGE_PIN B5 [ get_ports {led0[2]}]  ;#B

set_property IOSTANDARD LVCMOS18 [get_ports {led1[*]}]
set_property SLEW SLOW [get_ports {led1[*]}]
set_property DRIVE 8 [get_ports {led1[*]}]
set_property PACKAGE_PIN B4 [ get_ports {led1[0]}]  ;#R
set_property PACKAGE_PIN A2 [ get_ports {led1[1]}]  ;#G
set_property PACKAGE_PIN F4 [ get_ports {led1[2]}]  ;#B

#push button
set_property IOSTANDARD LVCMOS18 [get_ports button0]
set_property PACKAGE_PIN F12 [ get_ports button0]  

set_property IOSTANDARD LVCMOS18 [get_ports button1]
set_property PACKAGE_PIN A8 [ get_ports button1]


#syzygy 

#J2

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

