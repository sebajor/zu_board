module cocotb_iverilog_dump();
initial begin
    $dumpfile("sim_build/dft_bin_multiple_inputs_tb.fst");
    $dumpvars(0, dft_bin_multiple_inputs_tb);
end
endmodule
