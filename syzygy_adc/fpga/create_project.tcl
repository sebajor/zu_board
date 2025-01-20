create_project -force -part xczu1cg-sbva484-1-e fpga
add_files -fileset sources_1 defines.v
add_files -fileset sources_1 ../rtl/fpga.v
add_files -fileset sources_1 ../rtl/async_true_dual_ram_read_first.v
add_files -fileset sources_1 ../rtl/async_true_dual_ram.v
add_files -fileset sources_1 ../rtl/async_true_dual_ram_write_first.v
add_files -fileset sources_1 ../rtl/axil_bram_arbiter.v
add_files -fileset sources_1 ../rtl/axil_bram_unbalanced.v
add_files -fileset sources_1 ../rtl/axil_bram.v
add_files -fileset sources_1 ../rtl/bitslip_shift.v
add_files -fileset sources_1 ../rtl/clock_alignment.v
add_files -fileset sources_1 ../rtl/data_phy.v
add_files -fileset sources_1 ../rtl/output_clock.v
add_files -fileset sources_1 ../rtl/s_axil_reg.v
add_files -fileset sources_1 ../rtl/skid_buffer.v
add_files -fileset sources_1 ../rtl/unbalanced_ram.v
add_files -fileset constrs_1 ../fpga.xdc
source ../ip/mpsoc.tcl
exit
