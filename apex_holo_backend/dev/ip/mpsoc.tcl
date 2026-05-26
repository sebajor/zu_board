set cur_dir [pwd]
puts $cur_dir
set bd_dir $cur_dir/fpga.srcs/sources_1/bd/system
exec mkdir -p $cur_dir/rev

create_bd_design system
#instantiate ps
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:* mpsoc
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:* proc_sys_reset
#source the standard configuration
source ../ip/zub1cg_mpsoc.tcl


#mpsoc clocks generation
#creating clock 0 
set_property -dict [list CONFIG.PSU__FPGA_PL0_ENABLE {1}] [get_bd_cells mpsoc]
set_property -dict [list CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100.000000}] [get_bd_cells mpsoc]
create_bd_net mpsoc_clk0
connect_bd_net -net mpsoc_clk0 [get_bd_pins mpsoc/pl_clk0]
create_bd_port -dir O -type clk mpsoc_clk_100
connect_bd_net -net mpsoc_clk0 [get_bd_ports mpsoc_clk_100]
set freq0_mhz [get_property CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ [get_bd_cells mpsoc]]
set freq0_hz [expr $freq0_mhz*1e6]
set_property -dict [list CONFIG.FREQ_HZ $freq0_hz] [get_bd_ports mpsoc_clk_100]


##reseting systemcreate_bd_net pl_resetn
connect_bd_net -net pl_resetn [get_bd_pins mpsoc/pl_resetn0]
create_bd_net axil_rst
create_bd_net axil_arst_n
connect_bd_net -net mpsoc_clk0 [get_bd_pins proc_sys_reset/slowest_sync_clk]
connect_bd_net -net pl_resetn [get_bd_pins proc_sys_reset/ext_reset_in]
connect_bd_net -net axil_rst [get_bd_pins proc_sys_reset/peripheral_reset]
connect_bd_net -net axil_arst_n [get_bd_pins proc_sys_reset/peripheral_aresetn]
create_bd_port -dir O -type rst axil_rst
create_bd_port -dir O -type rst axil_arst_n
connect_bd_net -net axil_rst [get_bd_ports axil_rst]
connect_bd_net -net axil_arst_n [get_bd_ports axil_arst_n]


##configuration for HPM0_FPD
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP0 {1}] [get_bd_cells mpsoc] 
set_property -dict [list CONFIG.PSU__MAXIGP0__DATA_WIDTH {32}] [get_bd_cells mpsoc] 
##connect the clock
connect_bd_net -net mpsoc_clk0 [get_bd_pins mpsoc/maxihpm0_fpd_aclk]
##creating interconnect
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:* hpm0_intercon 
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {5}] [get_bd_cells hpm0_intercon]
connect_bd_net -net axil_arst_n [get_bd_pins hpm0_intercon/ARESETN] 
connect_bd_net -net mpsoc_clk0 [get_bd_pins hpm0_intercon/ACLK] 
connect_bd_net -net axil_arst_n [get_bd_pins hpm0_intercon/S00_ARESETN] 
connect_bd_net -net mpsoc_clk0 [get_bd_pins hpm0_intercon/S00_ACLK] 
connect_bd_intf_net [get_bd_intf_pins mpsoc/M_AXI_HPM0_FPD] -boundary_type upper [get_bd_intf_pins hpm0_intercon/S00_AXI]
make_bd_intf_pins_external  [get_bd_intf_pins hpm0_intercon/M00_AXI]
set_property name HPM0_FPD_M00_axil [get_bd_intf_ports M00_AXI_0]
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports /HPM0_FPD_M00_axil]
connect_bd_net -net axil_arst_n [get_bd_pins hpm0_intercon/M00_ARESETN] 
connect_bd_net -net mpsoc_clk0 [get_bd_pins hpm0_intercon/M00_ACLK] 
assign_bd_address [get_bd_addr_segs {HPM0_FPD_M00_axil/Reg }]
set_property range 32K [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_M00_axil_Reg}]
set_property offset 0xA0000000 [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_M00_axil_Reg}]
make_bd_intf_pins_external  [get_bd_intf_pins hpm0_intercon/M01_AXI]
set_property name HPM0_FPD_M01_axil [get_bd_intf_ports M01_AXI_0]
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports /HPM0_FPD_M01_axil]
connect_bd_net -net axil_arst_n [get_bd_pins hpm0_intercon/M01_ARESETN] 
connect_bd_net -net mpsoc_clk0 [get_bd_pins hpm0_intercon/M01_ACLK] 
assign_bd_address [get_bd_addr_segs {HPM0_FPD_M01_axil/Reg }]
set_property range 32K [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_M01_axil_Reg}]
set_property offset 0xA0008000 [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_M01_axil_Reg}]
make_bd_intf_pins_external  [get_bd_intf_pins hpm0_intercon/M02_AXI]
set_property name HPM0_FPD_M02_axil [get_bd_intf_ports M02_AXI_0]
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports /HPM0_FPD_M02_axil]
connect_bd_net -net axil_arst_n [get_bd_pins hpm0_intercon/M02_ARESETN] 
connect_bd_net -net mpsoc_clk0 [get_bd_pins hpm0_intercon/M02_ACLK] 
assign_bd_address [get_bd_addr_segs {HPM0_FPD_M02_axil/Reg }]
set_property range 32K [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_M02_axil_Reg}]
set_property offset 0xA0010000 [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_M02_axil_Reg}]
make_bd_intf_pins_external  [get_bd_intf_pins hpm0_intercon/M03_AXI]
set_property name HPM0_FPD_M03_axil [get_bd_intf_ports M03_AXI_0]
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports /HPM0_FPD_M03_axil]
connect_bd_net -net axil_arst_n [get_bd_pins hpm0_intercon/M03_ARESETN] 
connect_bd_net -net mpsoc_clk0 [get_bd_pins hpm0_intercon/M03_ACLK] 
assign_bd_address [get_bd_addr_segs {HPM0_FPD_M03_axil/Reg }]
set_property range 32K [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_M03_axil_Reg}]
set_property offset 0xA0018000 [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_M03_axil_Reg}]
make_bd_intf_pins_external  [get_bd_intf_pins hpm0_intercon/M04_AXI]
set_property name HPM0_FPD_M04_axil [get_bd_intf_ports M04_AXI_0]
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports /HPM0_FPD_M04_axil]
connect_bd_net -net axil_arst_n [get_bd_pins hpm0_intercon/M04_ARESETN] 
connect_bd_net -net mpsoc_clk0 [get_bd_pins hpm0_intercon/M04_ACLK] 
assign_bd_address [get_bd_addr_segs {HPM0_FPD_M04_axil/Reg }]
set_property offset 0xA0080000 [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_M04_axil_Reg}]
set_property range 512K [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_M04_axil_Reg}]


##configuration for HPM1_FPD
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP1 {0}] [get_bd_cells mpsoc] 


##configuration for HPM0_LPD
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP2 {0}] [get_bd_cells mpsoc] 

##set clock of the axi-lite interfaces
set_property CONFIG.ASSOCIATED_BUSIF {HPM0_FPD_M00_axil:HPM0_FPD_M01_axil:HPM0_FPD_M02_axil:HPM0_FPD_M03_axil:HPM0_FPD_M04_axil} [get_bd_ports /mpsoc_clk_100]
make_wrapper -files [get_files $bd_dir/system.bd] -top
import_files -force -norecurse $bd_dir/hdl/system_wrapper.v
write_bd_tcl -force $cur_dir/rev/system.tcl
