open_project fpga.xpr
open_run impl_1
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
write_bitstream -bin_file -force fpga.bit
exit
