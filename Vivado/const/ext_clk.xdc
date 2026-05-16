###############################################################################
########################## External Clk 24.576MHz #############################
###############################################################################
set_property PACKAGE_PIN E12 [get_ports ext_clk_in]
set_property IOSTANDARD LVCMOS33 [get_ports ext_clk_in]

# Creacion del objeto de reloj (Periodo = 1 / 24.576 MHz ? 40.690 ns)
create_clock -period 40.690 -name ext_clk_audio -waveform {0.000 20.345} [get_ports ext_clk_in]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ext_clk_in_IBUF_inst/O]

