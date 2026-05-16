##################### PMOD 2 Upper ###################################
# set_property PACKAGE_PIN J11 [get_ports {adbus[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {adbus[0]}]

set_property PACKAGE_PIN J10 [get_ports {adbus[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adbus[1]}]

set_property PACKAGE_PIN K13 [get_ports txe]
set_property IOSTANDARD LVCMOS33 [get_ports txe]

set_property PACKAGE_PIN K12 [get_ports wr_n]
set_property IOSTANDARD LVCMOS33 [get_ports wr_n]

##################### PMOD 2 Lower ###################################
# set_property PACKAGE_PIN H11 [get_ports {adbus[4]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {adbus[4]}]

set_property PACKAGE_PIN G10 [get_ports {adbus[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adbus[0]}]

set_property PACKAGE_PIN F12 [get_ports rxf]
set_property IOSTANDARD LVCMOS33 [get_ports rxf]

set_property PACKAGE_PIN F11 [get_ports rd_n]
set_property IOSTANDARD LVCMOS33 [get_ports rd_n]


##################### PMOD 3 Upper ###################################
# set_property PACKAGE_PIN AE12 [get_ports {adbus[0]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {adbus[0]}]

set_property PACKAGE_PIN AF12 [get_ports {adbus[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adbus[7]}]

set_property PACKAGE_PIN AG10 [get_ports {adbus[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adbus[5]}]

set_property PACKAGE_PIN AH10 [get_ports {adbus[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adbus[3]}]

##################### PMOD 3 Lower ###################################
# set_property PACKAGE_PIN AF11 [get_ports {adbus[4]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {adbus[4]}]

set_property PACKAGE_PIN AG11 [get_ports {adbus[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adbus[6]}]

set_property PACKAGE_PIN AH12 [get_ports {adbus[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adbus[4]}]

set_property PACKAGE_PIN AH11 [get_ports {adbus[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {adbus[2]}]