`default_nettype none
`include "async_true_dual_ram2.v"
`include "axil_bram_arbiter.v"
`include "axil_bram_unbalanced.v"
`include "axil_bram.v"
`include "bram_infer.v"
`include "complex_mult.v"
`include "delay.v"
`include "dsp48_mult.v"
`include "resize_data.v"
`include "s_axil_reg.v"
`include "scalar_accumulator.v"
`include "shift.v"
`include "signed_cast.v"
`include "single_bin_dft.v"
`include "skid_buffer.v"
`include "test_bench.v"
`include "unbalanced_ram.v"
`include "unsign_cast.v"

/*
*   
*
*/

module test_bench #(
    //dft parameters
    parameter DIN_WIDTH = 16,
    parameter DIN_POINT = 15,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "twidd_init.bin",
    parameter DFT_LEN = 128,
    parameter DFT_DOUT_WIDTH = 32,
    parameter DFT_DOUT_POINT = 15,
    parameter DFT_DOUT_DELAY = 1,

    parameter DOUT_WIDTH = 32,
    
    parameter CAST_WARNING = 1

) (
    input wire fpga_clock,

    input wire axi_clock,
    input wire axil_rst,

    input wire signed [DIN_WIDTH-1:0] din_re, din_im,
    input wire din_valid,

    //control signals
    input wire cnt_rst,
    input wire dft_delay_line,
    input wire [31:0] acc_len,

    //
    //twiddle factor axilite interface
    //
    //write address channel
    input wire [$clog2(DFT_LEN)+1:0]  HPM0_FPD_M00_axil_awaddr,
    input wire [2:0] HPM0_FPD_M00_axil_awprot,
    input wire HPM0_FPD_M00_axil_awvalid,
    output wire HPM0_FPD_M00_axil_awready,
    //write data channel
    input wire [2*TWIDD_WIDTH-1:0] HPM0_FPD_M00_axil_wdata,
    input wire [(2*TWIDD_WIDTH)/8-1:0] HPM0_FPD_M00_axil_wstrb,
    input wire HPM0_FPD_M00_axil_wvalid,
    output wire HPM0_FPD_M00_axil_wready,
    //write response channel
    output wire [1:0] HPM0_FPD_M00_axil_bresp,
    output wire HPM0_FPD_M00_axil_bvalid,
    input wire HPM0_FPD_M00_axil_bready,
    //read address channel
    input wire [$clog2(DFT_LEN)+1:0] HPM0_FPD_M00_axil_araddr,
    input wire HPM0_FPD_M00_axil_arvalid,
    output wire HPM0_FPD_M00_axil_arready,
    input wire [2:0] HPM0_FPD_M00_axil_arprot,
    //read data channel
    output wire [(2*TWIDD_WIDTH)-1:0] HPM0_FPD_M00_axil_rdata,
    output wire [1:0] HPM0_FPD_M00_axil_rresp,
    output wire HPM0_FPD_M00_axil_rvalid,
    input wire HPM0_FPD_M00_axil_rready,

    //axi lite bram aa
    input wire [$clog2(DFT_LEN)+1:0]  HPM0_FPD_M01_axil_awaddr,
    input wire [2:0] HPM0_FPD_M01_axil_awprot,
    input wire HPM0_FPD_M01_axil_awvalid,
    output wire HPM0_FPD_M01_axil_awready,
    //write data channel
    input wire [2*TWIDD_WIDTH-1:0] HPM0_FPD_M01_axil_wdata,
    input wire [(2*TWIDD_WIDTH)/8-1:0] HPM0_FPD_M01_axil_wstrb,
    input wire HPM0_FPD_M01_axil_wvalid,
    output wire HPM0_FPD_M01_axil_wready,
    //write response channel
    output wire [1:0] HPM0_FPD_M01_axil_bresp,
    output wire HPM0_FPD_M01_axil_bvalid,
    input wire HPM0_FPD_M01_axil_bready,
    //read address channel
    input wire [$clog2(DFT_LEN)+1:0] HPM0_FPD_M01_axil_araddr,
    input wire HPM0_FPD_M01_axil_arvalid,
    output wire HPM0_FPD_M01_axil_arready,
    input wire [2:0] HPM0_FPD_M01_axil_arprot,
    //read data channel
    output wire [(2*TWIDD_WIDTH)-1:0] HPM0_FPD_M01_axil_rdata,
    output wire [1:0] HPM0_FPD_M01_axil_rresp,
    output wire HPM0_FPD_M01_axil_rvalid,
    input wire HPM0_FPD_M01_axil_rready,

    //axi lite bram bb
    input wire [$clog2(DFT_LEN)+1:0]  HPM0_FPD_M02_axil_awaddr,
    input wire [2:0] HPM0_FPD_M02_axil_awprot,
    input wire HPM0_FPD_M02_axil_awvalid,
    output wire HPM0_FPD_M02_axil_awready,
    //write data channel
    input wire [2*TWIDD_WIDTH-1:0] HPM0_FPD_M02_axil_wdata,
    input wire [(2*TWIDD_WIDTH)/8-1:0] HPM0_FPD_M02_axil_wstrb,
    input wire HPM0_FPD_M02_axil_wvalid,
    output wire HPM0_FPD_M02_axil_wready,
    //write response channel
    output wire [1:0] HPM0_FPD_M02_axil_bresp,
    output wire HPM0_FPD_M02_axil_bvalid,
    input wire HPM0_FPD_M02_axil_bready,
    //read address channel
    input wire [$clog2(DFT_LEN)+1:0] HPM0_FPD_M02_axil_araddr,
    input wire HPM0_FPD_M02_axil_arvalid,
    output wire HPM0_FPD_M02_axil_arready,
    input wire [2:0] HPM0_FPD_M02_axil_arprot,
    //read data channel
    output wire [(2*TWIDD_WIDTH)-1:0] HPM0_FPD_M02_axil_rdata,
    output wire [1:0] HPM0_FPD_M02_axil_rresp,
    output wire HPM0_FPD_M02_axil_rvalid,
    input wire HPM0_FPD_M02_axil_rready,
    
    //axi lite bram ab_re
    input wire [$clog2(DFT_LEN)+1:0]  HPM0_FPD_M03_axil_awaddr,
    input wire [2:0] HPM0_FPD_M03_axil_awprot,
    input wire HPM0_FPD_M03_axil_awvalid,
    output wire HPM0_FPD_M03_axil_awready,
    //write data channel
    input wire [2*TWIDD_WIDTH-1:0] HPM0_FPD_M03_axil_wdata,
    input wire [(2*TWIDD_WIDTH)/8-1:0] HPM0_FPD_M03_axil_wstrb,
    input wire HPM0_FPD_M03_axil_wvalid,
    output wire HPM0_FPD_M03_axil_wready,
    //write response channel
    output wire [1:0] HPM0_FPD_M03_axil_bresp,
    output wire HPM0_FPD_M03_axil_bvalid,
    input wire HPM0_FPD_M03_axil_bready,
    //read address channel
    input wire [$clog2(DFT_LEN)+1:0] HPM0_FPD_M03_axil_araddr,
    input wire HPM0_FPD_M03_axil_arvalid,
    output wire HPM0_FPD_M03_axil_arready,
    input wire [2:0] HPM0_FPD_M03_axil_arprot,
    //read data channel
    output wire [(2*TWIDD_WIDTH)-1:0] HPM0_FPD_M03_axil_rdata,
    output wire [1:0] HPM0_FPD_M03_axil_rresp,
    output wire HPM0_FPD_M03_axil_rvalid,
    input wire HPM0_FPD_M03_axil_rready,

    //axi lite bram ab_im
    input wire [$clog2(DFT_LEN)+1:0]  HPM0_FPD_M04_axil_awaddr,
    input wire [2:0] HPM0_FPD_M04_axil_awprot,
    input wire HPM0_FPD_M04_axil_awvalid,
    output wire HPM0_FPD_M04_axil_awready,
    //write data channel
    input wire [2*TWIDD_WIDTH-1:0] HPM0_FPD_M04_axil_wdata,
    input wire [(2*TWIDD_WIDTH)/8-1:0] HPM0_FPD_M04_axil_wstrb,
    input wire HPM0_FPD_M04_axil_wvalid,
    output wire HPM0_FPD_M04_axil_wready,
    //write response channel
    output wire [1:0] HPM0_FPD_M04_axil_bresp,
    output wire HPM0_FPD_M04_axil_bvalid,
    input wire HPM0_FPD_M04_axil_bready,
    //read address channel
    input wire [$clog2(DFT_LEN)+1:0] HPM0_FPD_M04_axil_araddr,
    input wire HPM0_FPD_M04_axil_arvalid,
    output wire HPM0_FPD_M04_axil_arready,
    input wire [2:0] HPM0_FPD_M04_axil_arprot,
    //read data channel
    output wire [(2*TWIDD_WIDTH)-1:0] HPM0_FPD_M04_axil_rdata,
    output wire [1:0] HPM0_FPD_M04_axil_rresp,
    output wire HPM0_FPD_M04_axil_rvalid,
    input wire HPM0_FPD_M04_axil_rready
);


wire signed [DFT_DOUT_WIDTH-1:0] dft_dout_re, dft_dout_im;
wire dft_dout_valid;

wire dft_casting_warning;


single_bin_dft #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .DFT_LEN(DFT_LEN),
    .DOUT_WIDTH(DFT_DOUT_WIDTH),
    .DOUT_POINT(DFT_DOUT_POINT),
    .DOUT_DELAY(DFT_DOUT_DELAY),
    .CAST_WARNING(CAST_WARNING)
) single_bin_dft_inst  (
    .clk(fpga_clk),
    .rst(cnt_rst), 
    .din_re(din_re), 
    .din_im(din_im),
    .din_valid(din_valid),
    .delay_line(dft_delay_line),   //this controls the DFT size(), the one at the parameter is the max value
    .dout_re(dft_dout_re), 
    .dout_im(dft_dout_im), 
    .dout_valid(dft_dout_valid),
    .cast_warning(dft_casting_warning),
    //axilite interface
    .axi_clock(axi_clock),
    .axil_rst(axil_rst),
    .s_axil_awaddr(HPM0_FPD_M00_axil_awaddr),
    .s_axil_awprot(HPM0_FPD_M00_axil_awprot),
    .s_axil_awvalid(HPM0_FPD_M00_axil_awvalid),
    .s_axil_awready(HPM0_FPD_M00_axil_awready),
    .s_axil_wdata(HPM0_FPD_M00_axil_wdata),
    .s_axil_wstrb(HPM0_FPD_M00_axil_wstrb),
    .s_axil_wvalid(HPM0_FPD_M00_axil_wvalid),
    .s_axil_wready(HPM0_FPD_M00_axil_wready),
    .s_axil_bresp(HPM0_FPD_M00_axil_bresp),
    .s_axil_bvalid(HPM0_FPD_M00_axil_bvalid),
    .s_axil_bready(HPM0_FPD_M00_axil_bready),
    .s_axil_araddr(HPM0_FPD_M00_axil_araddr),
    .s_axil_arvalid(HPM0_FPD_M00_axil_arvalid),
    .s_axil_arready(HPM0_FPD_M00_axil_arready),
    .s_axil_arprot(HPM0_FPD_M00_axil_arprot),
    .s_axil_rdata(HPM0_FPD_M00_axil_rdata),
    .s_axil_rresp(HPM0_FPD_M00_axil_rresp),
    .s_axil_rvalid(HPM0_FPD_M00_axil_rvalid),
    .s_axil_rready(HPM0_FPD_M00_axil_rready)
);

//correlation mults
correlation_mults #(
    .DIN_WIDTH(DFT_DOUT_WIDTH)
) correlation_mults_inst  (
    clk,
    din1_re, din1_im,
    din2_re, din2_im,
    din_valid,
    din1_pow, din2_pow,
    corr_re, corr_im,
    dout_valid
);





//accumulator
scalar_accumulator #(
    .DIN_WIDTH(DFT_DOUT_WIDTH),
    .ACC_WIDTH(DOUT_WIDTH),
    .DATA_TYPE("signed")
) signed_accumulator [1:0]  (
    .clk(fpga_clock),
    .din(),
    .din_valid(),
    .acc_done(),
    .dout(),
    .dout_valid()
);





endmodule
