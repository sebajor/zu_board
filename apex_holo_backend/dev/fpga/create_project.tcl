create_project -force -part xczu1cg-sbva484-1-e fpga
add_files -fileset sources_1 defines.v
add_files -fileset sources_1 ../rtl/fpga.v
add_files -fileset sources_1 ../rtl/async_true_dual_ram.v
add_files -fileset sources_1 ../rtl/axil_bram_arbiter.v
add_files -fileset sources_1 ../rtl/axil_bram_unbalanced.v
add_files -fileset sources_1 ../rtl/axil_bram.v
add_files -fileset sources_1 ../rtl/bitslip_shift.v
add_files -fileset sources_1 ../rtl/clock_alignment.v
add_files -fileset sources_1 ../rtl/complex_mult.v
add_files -fileset sources_1 ../rtl/complex_power.v
add_files -fileset sources_1 ../rtl/correlation_mults.v
add_files -fileset sources_1 ../rtl/data_phy.v
add_files -fileset sources_1 ../rtl/delay.v
add_files -fileset sources_1 ../rtl/dft_bin_multiple_inputs.v
add_files -fileset sources_1 ../rtl/dsp48_mult.v
add_files -fileset sources_1 ../rtl/output_clock.v
add_files -fileset sources_1 ../rtl/resize_data.v
add_files -fileset sources_1 ../rtl/s_axil_reg.v
add_files -fileset sources_1 ../rtl/scalar_accumulator.v
add_files -fileset sources_1 ../rtl/shift.v
add_files -fileset sources_1 ../rtl/signed_cast.v
add_files -fileset sources_1 ../rtl/single_bin_fx_correlator.v
add_files -fileset sources_1 ../rtl/skid_buffer.v
add_files -fileset sources_1 ../rtl/unbalanced_ram.v
add_files -fileset sources_1 ../rtl/unsign_cast.v
add_files -fileset constrs_1 ../fpga.xdc
source ../ip/mpsoc.tcl
exit
