########################## UF User LEDs #############################
set_property PACKAGE_PIN F8 [get_ports {pulso_ext}]
set_property IOSTANDARD LVCMOS18 [get_ports {pulso_ext}]

set_property PACKAGE_PIN E8 [get_ports {pulso_led}]
set_property IOSTANDARD LVCMOS18 [get_ports {pulso_led}]

#####################################################################
## Information for external clock ###################################
#####################################################################
#set_property PACKAGE_PIN [TU_PIN] [get_ports ext_audio_clk]
#set_property IOSTANDARD LVCMOS33 [get_ports ext_audio_clk]

## Crear un reloj virtual para el cristal externo
#create_clock -period 10416.67 -name ext_audio_clk [get_ports ext_audio_clk]
## Indicar que no hay relación de fase con el reloj de 100MHz
#set_clock_groups -asynchronous -group [get_clocks clk_out1_v_main_clk_wiz_0_0] -group [get_clocks ext_audio_clk]