set cur_dir [pwd]
puts $cur_dir
set bd_dir $cur_dir/fpga.srcs/sources_1/bd/system
exec mkdir -p $cur_dir/rev

create_bd_design system

##instantiate ps
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:* mpsoc
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:* proc_sys_reset
#source the standard configuration
source ../ip/zub1cg_mpsoc.tcl
create_bd_net pl_sys_clk
connect_bd_net -net pl_sys_clk [get_bd_pins mpsoc/pl_clk0]
create_bd_net pl_resetn
connect_bd_net -net pl_resetn [get_bd_pins mpsoc/pl_resetn0]
set_property -dict [list \
CONFIG.PSU__USE__M_AXI_GP0 {1} \
CONFIG.PSU__MAXIGP0__DATA_WIDTH {32} \
CONFIG.PSU__USE__M_AXI_GP1 {0} \
CONFIG.PSU__MAXIGP1__DATA_WIDTH {128} \
CONFIG.PSU__USE__M_AXI_GP2 {0} \
CONFIG.PSU__MAXIGP2__DATA_WIDTH {128} \
] [get_bd_cells mpsoc]

    set freq_mhz [get_property CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ [get_bd_cells mpsoc]]
    set ps_freq_hz [expr $freq_mhz*1e6]

##here the ps uses the hpm0_fpd that has addr (0xA000_0000:0xA3ff_ffff). Actually this is the vcu address that overlaps the hpm0_fpd

##create interfaces
connect_bd_net -net pl_sys_clk [get_bd_pins mpsoc/maxihpm0_fpd_aclk] ;#connect the clock wiht the interface of the hp0
create_bd_port -dir O -type clk pl_sys_clk
connect_bd_net -net pl_sys_clk [get_bd_ports pl_sys_clk]
connect_bd_net -net pl_sys_clk [get_bd_pins proc_sys_reset/slowest_sync_clk]
create_bd_net axil_rst
create_bd_net axil_arst_n

#connect the interface
connect_bd_net -net pl_resetn [get_bd_pins proc_sys_reset/ext_reset_in]
connect_bd_net -net axil_rst [get_bd_pins proc_sys_reset/peripheral_reset]
connect_bd_net -net axil_arst_n [get_bd_pins proc_sys_reset/peripheral_aresetn]
create_bd_port -dir O -type rst axil_rst
create_bd_port -dir O -type rst axil_arst_n
connect_bd_net -net axil_rst [get_bd_ports axil_rst]
connect_bd_net -net axil_arst_n [get_bd_ports axil_arst_n]

##instantiate the interconnect with two slaves and 1 master
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:* axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2}] [get_bd_cells axi_interconnect_0]

#connect ps clock to interconnect and reset
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/mpsoc/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/ACLK]

#set the ps as the master of the interconnect
connect_bd_intf_net [get_bd_intf_pins mpsoc/M_AXI_HPM0_FPD] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
#connect the clocks and resets of the master
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/mpsoc/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/S00_ACLK]

##create axilite ports
make_bd_intf_pins_external  [get_bd_intf_pins axi_interconnect_0/M00_AXI]
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports /M00_AXI_0]

make_bd_intf_pins_external  [get_bd_intf_pins axi_interconnect_0/M01_AXI]
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports /M01_AXI_0]

##slaves clocks
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/mpsoc/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/M00_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/mpsoc/pl_clk0 (99 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/M01_ACLK]

#set ouptut axilite clocks
set_property CONFIG.ASSOCIATED_BUSIF {M00_AXI_0} [get_bd_ports /pl_sys_clk]
set_property CONFIG.ASSOCIATED_BUSIF {M00_AXI_0:M01_AXI_0} [get_bd_ports /pl_sys_clk]


##assign addresses
assign_bd_address [get_bd_addr_segs {M01_AXI_0/Reg }]
set_property offset 0xA000_0000 [get_bd_addr_segs {mpsoc/Data/SEG_M01_AXI_0_Reg}] ;	#base addr
set_property range 32K [get_bd_addr_segs {mpsoc/Data/SEG_M01_AXI_0_Reg}];		#size


assign_bd_address [get_bd_addr_segs {M00_AXI_0/Reg }]
set_property offset 0xA110_0000 [get_bd_addr_segs {mpsoc/Data/SEG_M00_AXI_0_Reg}]
set_property range 32K [get_bd_addr_segs {mpsoc/Data/SEG_M00_AXI_0_Reg}]

#change the damn names of the axi interfaces
set_property name HPM0_FPD_M00_axil [get_bd_intf_ports M00_AXI_0]
set_property name HPM0_FPD_M01_axil [get_bd_intf_ports M01_AXI_0]



##generate hdl wrapper
make_wrapper -files [get_files $bd_dir/system.bd] -top
import_files -force -norecurse $bd_dir/hdl/system_wrapper.v

write_bd_tcl -force $cur_dir/rev/system.tcl
