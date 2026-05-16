# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\GitHub\Kria_Arch_A_prj\Vitis\kria_arch_a_platform\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\GitHub\Kria_Arch_A_prj\Vitis\kria_arch_a_platform\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {kria_arch_a_platform}\
-hw {../Vivado/Products/kria_bd_wrapper.xsa}\
-proc {psu_cortexa53_0} -os {freertos10_xilinx} -arch {64-bit} -fsbl-target {psu_cortexa53_0} -out {./}

platform write
platform generate -domains 
platform active {kria_arch_a_platform}

# The following commands are used to create three domains for the three Cortex-A53 cores in the Zynq UltraScale+ MPSoC, set their properties, and generate the platform for each domain.
domain create -name {psu_cortexa53_1} -os {freertos} -proc {psu_cortexa53_1} -arch {64-bit} -display-name {psu_cortexa53_1} -desc {} -runtime {cpp}
platform generate -domains 
platform write
domain -report -json
domain create -name {psu_cortexa53_2} -os {freertos} -proc {psu_cortexa53_2} -arch {64-bit} -display-name {psu_cortexa53_2} -desc {} -runtime {cpp}
platform generate -domains 
platform write
domain -report -json
domain create -name {psu_Cortexa53_3} -os {freertos} -proc {psu_cortexa53_3} -arch {64-bit} -display-name {psu_Cortexa53_3} -desc {} -runtime {cpp}
platform generate -domains 
domain -report -json
platform write

# The following commands are used to set the heap size for the FreeRTOS BSP and regenerate the BSP.
platform active {kria_arch_a_platform}
domain active {freertos10_xilinx_domain}
bsp config total_heap_size "131072"
bsp config tick_rate "1000"
bsp write
bsp reload
catch {bsp regenerate}
domain active {psu_cortexa53_1}
bsp config total_heap_size "131072"
bsp config tick_rate "1000"
bsp write
bsp reload
catch {bsp regenerate}
domain active {psu_cortexa53_2}
bsp config total_heap_size "131072"
bsp config tick_rate "1000"
bsp write
bsp reload
catch {bsp regenerate}
domain active {psu_Cortexa53_3} 
bsp config total_heap_size "131072"
bsp config tick_rate "1000"
bsp write
bsp reload
catch {bsp regenerate}

# The following command is used to generate the platform for all the domains.
platform generate -domains freertos10_xilinx_domain,psu_cortexa53_1,psu_cortexa53_2,psu_Cortexa53_3 