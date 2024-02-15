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
CONFIG.PSU__USE__M_AXI_GP1 {1} \
CONFIG.PSU__MAXIGP1__DATA_WIDTH {32} \
CONFIG.PSU__USE__M_AXI_GP2 {0} \
CONFIG.PSU__MAXIGP2__DATA_WIDTH {128} \
CONFIG.PSU__USE__S_AXI_GP2 {1} \
CONFIG.PSU__SAXIGP2__DATA_WIDTH {32} 
] [get_bd_cells mpsoc]

##maybe the HP0 slave (s_AXI_GP2) needs other bitwidth to work in dma..no idea
    set freq_mhz [get_property CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ [get_bd_cells mpsoc]]
    set ps_freq_hz [expr $freq_mhz*1e6]

##here the ps uses the hpm0_fpd that has addr (0xA000_0000:0xA3ff_ffff). Actually this is the vcu address that overlaps the hpm0_fpd

##create interfaces
connect_bd_net -net pl_sys_clk [get_bd_pins mpsoc/maxihpm0_fpd_aclk] ;#connect the clock wiht the interface of the hp0
connect_bd_net -net pl_sys_clk [get_bd_pins mpsoc/maxihpm1_fpd_aclk] ;#connect the clock wiht the interface of the hp1
connect_bd_net -net pl_sys_clk [get_bd_pins mpsoc/saxihp0_fpd_aclk] ;#connect the clock wiht the interface of the hpc0


##I will create some brams just because
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:* axi_bram_ctrl_hpm0
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_hpm0]
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:* blk_mem_hpm0

connect_bd_intf_net [get_bd_intf_pins mpsoc/M_AXI_HPM0_FPD] [get_bd_intf_pins axi_bram_ctrl_hpm0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_hpm0/BRAM_PORTA] [get_bd_intf_pins blk_mem_hpm0/BRAM_PORTA]
#connect_bd_net [get_bd_pins axi_bram_ctrl_hpm0/s_axi_aresetn] [get_bd_pins mpsoc/pl_resetn0]
connect_bd_net [get_bd_pins axi_bram_ctrl_hpm0/s_axi_aclk] [get_bd_pins mpsoc/pl_clk0]


create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:* axi_bram_ctrl_hpm1
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_hpm1]
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:* blk_mem_hpm1

connect_bd_intf_net [get_bd_intf_pins mpsoc/M_AXI_HPM1_FPD] [get_bd_intf_pins axi_bram_ctrl_hpm1/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_hpm1/BRAM_PORTA] [get_bd_intf_pins blk_mem_hpm1/BRAM_PORTA]
#connect_bd_net [get_bd_pins axi_bram_ctrl_hpm1/s_axi_aresetn] [get_bd_pins mpsoc/pl_resetn0]
connect_bd_net [get_bd_pins axi_bram_ctrl_hpm1/s_axi_aclk] [get_bd_pins mpsoc/pl_clk0]

assign_bd_address -target_address_space /mpsoc/Data [get_bd_addr_segs axi_bram_ctrl_hpm0/S_AXI/Mem0] -force
#set_property range 256M [get_bd_addr_segs {mpsoc/Data/SEG_axi_bram_ctrl_hpm0_Mem0}]
assign_bd_address -target_address_space /mpsoc/Data [get_bd_addr_segs axi_bram_ctrl_hpm1/S_AXI/Mem0] -force
#set_property range 256M [get_bd_addr_segs {mpsoc/Data/SEG_axi_bram_ctrl_hpm1_Mem0}]
connect_bd_net [get_bd_pins axi_bram_ctrl_hpm0/s_axi_aresetn] [get_bd_pins proc_sys_reset/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_bram_ctrl_hpm1/s_axi_aresetn] [get_bd_pins proc_sys_reset/peripheral_aresetn]







#create_bd_port -dir O -type clk pl_sys_clk
#connect_bd_net -net pl_sys_clk [get_bd_ports pl_sys_clk]
connect_bd_net -net pl_sys_clk [get_bd_pins proc_sys_reset/slowest_sync_clk]
#create_bd_net axil_rst
#create_bd_net axil_arst_n

#connect the interface
connect_bd_net -net pl_resetn [get_bd_pins proc_sys_reset/ext_reset_in]
#connect_bd_net -net axil_rst [get_bd_pins proc_sys_reset/peripheral_reset]
#connect_bd_net -net axil_arst_n [get_bd_pins proc_sys_reset/peripheral_aresetn]
#create_bd_port -dir O -type rst axil_rst
#create_bd_port -dir O -type rst axil_arst_n
#connect_bd_net -net axil_rst [get_bd_ports axil_rst]
#connect_bd_net -net axil_arst_n [get_bd_ports axil_arst_n]

#instantiate axi protocol converter to have axi-lite
#create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:* axi_protocol_convert_hpm0
#create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:* axi_protocol_convert_hpm1
#connect_bd_intf_net [get_bd_intf_pins mpsoc/M_AXI_HPM0_FPD] [get_bd_intf_pins axi_protocol_convert_hpm0/S_AXI]
#connect_bd_intf_net [get_bd_intf_pins mpsoc/M_AXI_HPM1_FPD] [get_bd_intf_pins axi_protocol_convert_hpm1/S_AXI]

#connect_bd_net -net pl_sys_clk [get_bd_pins axi_protocol_convert_hpm0/aclk] ;#connect the clock wiht the interface of the hp0
#connect_bd_net -net pl_sys_clk [get_bd_pins axi_protocol_convert_hpm1/aclk] ;#connect the clock wiht the interface of the hp0
#connect_bd_net [get_bd_pins proc_sys_reset/peripheral_aresetn] [get_bd_pins axi_protocol_convert_hpm0/aresetn]
#connect_bd_net [get_bd_pins proc_sys_reset/peripheral_aresetn] [get_bd_pins axi_protocol_convert_hpm1/aresetn]


##create axilite ports
#make_bd_intf_pins_external  [get_bd_intf_pins axi_protocol_convert_hpm0/M_AXI]
#set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports /M_AXI_0]
#set_property name HPM0_FPD_axil [get_bd_intf_ports M_AXI_0]

#make_bd_intf_pins_external  [get_bd_intf_pins axi_protocol_convert_hpm1/M_AXI]
#set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports /M_AXI_0]
#set_property name HPM1_FPD_axil [get_bd_intf_ports M_AXI_0]

#set ouptut axilite clocks
#set_property CONFIG.ASSOCIATED_BUSIF {HPM0_FPD_axil} [get_bd_ports /pl_sys_clk]
#set_property CONFIG.ASSOCIATED_BUSIF {HPM0_FPD_axil:HPM1_FPD_axil} [get_bd_ports /pl_sys_clk]


#assignate addresses; i will assign all the memeory available
#assign_bd_address [get_bd_addr_segs {HPM0_FPD_axil/Reg }]
#set_property offset 0xA000_0000 [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_axil_Reg}] ;	#base addr
#set_property range 256M [get_bd_addr_segs {mpsoc/Data/SEG_HPM0_FPD_axil_Reg}]

#assign_bd_address [get_bd_addr_segs {HPM1_FPD_axil/Reg }]
#set_property offset 0xB000_0000 [get_bd_addr_segs {mpsoc/Data/SEG_HPM1_FPD_axil_Reg}] ;	#base addr
#set_property range 256M [get_bd_addr_segs {mpsoc/Data/SEG_HPM1_FPD_axil_Reg}]


##generate hdl wrapper
make_wrapper -files [get_files $bd_dir/system.bd] -top
import_files -force -norecurse $bd_dir/hdl/system_wrapper.v

write_bd_tcl -force $cur_dir/rev/system.tcl
