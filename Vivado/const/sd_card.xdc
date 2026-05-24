###################### PMOD 4 - Conexi�n SD Externa ###################

# Reloj (SD_CLK)
set_property PACKAGE_PIN AA11 [get_ports sd_clk_out]
set_property IOSTANDARD LVCMOS33 [get_ports sd_clk_out]

# Reloj (SD_CLK_FB)
set_property PACKAGE_PIN E10 [get_ports sd_clk_fb]
set_property IOSTANDARD LVCMOS33 [get_ports sd_clk_fb]

# Comando (SD_CMD)
set_property PACKAGE_PIN AE10 [get_ports sd_cmd_io]
set_property IOSTANDARD LVCMOS33 [get_ports sd_cmd_io]
# set_property PULLUP true [get_ports sd_cmd_io]

# Datos 0
set_property PACKAGE_PIN AF10 [get_ports {sd_data_io[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_data_io[0]}]
# set_property PULLUP true [get_ports {sd_data_io[0]}]

# Datos 1
set_property PACKAGE_PIN AA10 [get_ports {sd_data_io[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_data_io[1]}]
# set_property PULLUP true [get_ports {sd_data_io[1]}]

# Datos 2
set_property PACKAGE_PIN AD12 [get_ports {sd_data_io[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_data_io[2]}]
# set_property PULLUP true [get_ports {sd_data_io[2]}]

# Datos 3
set_property PACKAGE_PIN AD10 [get_ports {sd_data_io[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sd_data_io[3]}]
# set_property PULLUP true [get_ports {sd_data_io[3]}]