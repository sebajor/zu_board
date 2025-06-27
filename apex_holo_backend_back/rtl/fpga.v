//`default_nettype none
//`include "includes.v"

//Top template
module fpga #(
    parameter CAPTURE_ADDR = 10,

    parameter DIN_WIDTH = 14,
    parameter DIN_POINT = 13,
    parameter TWIDD_WIDTH = 16,
    parameter TWIDD_POINT = 14,
    parameter TWIDD_FILE = "rtl/twidd_init.bin",
    parameter TWIDD_DELAY = 1,
    parameter ACC_DELAY = 0,
    parameter DFT_LEN = 4096,
    parameter DFT_DOUT_WIDTH = 48,
    parameter DFT_DOUT_POINT = 25,
    parameter DFT_DOUT_DELAY = 1,
    parameter ACC_WIDTH = 48,
    parameter ACC_POINT = 25,
    parameter ACC_IN_DELAY = 1,
    parameter ACC_OUT_DELAY = 2,
    parameter CORR_DOUT_WIDTH = 64      //the bin pt of the output is the same as the ACC

)(
    output wire [2:0] led0, led1,

	input wire J6_S0_D0P, J6_S2_D0N,    //out1a_p, out1a_n.
    input wire J6_S1_D1P, J6_S3_D1N,    //frame_p, frame_n,
    input wire J6_S4_D2P, J6_S6_D2N,     //out1b_p, out1b_n,
    input wire J6_S5_D3P, J6_S7_D3N,     //out2a_p, out2a_m,
    input wire J6_S9_D5P, J6_S11_D5N,    //out2b_p, out2b_n

    input wire  J6_S8_D4P,                //sdo
    output wire J6_S10_D4N,                 //cs_b
    output wire J6_S12_D6P,                 //sclk
    output wire J6_S14_D6N,                  //sdi

    input wire J6_P2C_CLK_P,
	input wire J6_P2C_CLK_N,
	output wire J6_C2P_CLK_N,
	output wire J6_C2P_CLK_P
);

//to keep the same signals
wire syzygy_d0_p = J6_S0_D0P;
wire syzygy_d0_n = J6_S2_D0N;
wire syzygy_d1_p = J6_S1_D1P;
wire syzygy_d1_n = J6_S3_D1N;
wire syzygy_d2_p = J6_S4_D2P;
wire syzygy_d2_n = J6_S6_D2N;
wire syzygy_d3_p = J6_S5_D3P;
wire syzygy_d3_n = J6_S7_D3N;
wire syzygy_d5_p = J6_S9_D5P;
wire syzygy_d5_n = J6_S11_D5N;
wire syzygy_c2p_clk_p = J6_C2P_CLK_P;
wire syzygy_c2p_clk_n = J6_C2P_CLK_N;
wire syzygy_p2c_clk_p = J6_P2C_CLK_P;
wire syzygy_p2c_clk_n = J6_P2C_CLK_N;



//set the spi signals as 1, use default settings
assign J6_S10_D4N =1; 
assign J6_S12_D6P =1;
assign J6_S14_D6N =1;



wire mpsoc_clk_100;
//HPM0_FPD signals
wire  [39:0] HPM0_FPD_M00_axil_araddr;
wire  [2:0] HPM0_FPD_M00_axil_arprot;
wire HPM0_FPD_M00_axil_arready;
wire HPM0_FPD_M00_axil_arvalid;
wire  [39:0] HPM0_FPD_M00_axil_awaddr;
wire  [2:0] HPM0_FPD_M00_axil_awprot;
wire HPM0_FPD_M00_axil_awready;
wire HPM0_FPD_M00_axil_awvalid;
wire HPM0_FPD_M00_axil_bready;
wire  [1:0] HPM0_FPD_M00_axil_bresp;
wire HPM0_FPD_M00_axil_bvalid;
wire  [31:0] HPM0_FPD_M00_axil_rdata;
wire HPM0_FPD_M00_axil_rready;
wire  [1:0] HPM0_FPD_M00_axil_rresp;
wire HPM0_FPD_M00_axil_rvalid;
wire  [31:0] HPM0_FPD_M00_axil_wdata;
wire HPM0_FPD_M00_axil_wready;
wire  [3:0] HPM0_FPD_M00_axil_wstrb;
wire HPM0_FPD_M00_axil_wvalid;
wire  [39:0] HPM0_FPD_M01_axil_araddr;
wire  [2:0] HPM0_FPD_M01_axil_arprot;
wire HPM0_FPD_M01_axil_arready;
wire HPM0_FPD_M01_axil_arvalid;
wire  [39:0] HPM0_FPD_M01_axil_awaddr;
wire  [2:0] HPM0_FPD_M01_axil_awprot;
wire HPM0_FPD_M01_axil_awready;
wire HPM0_FPD_M01_axil_awvalid;
wire HPM0_FPD_M01_axil_bready;
wire  [1:0] HPM0_FPD_M01_axil_bresp;
wire HPM0_FPD_M01_axil_bvalid;
wire  [31:0] HPM0_FPD_M01_axil_rdata;
wire HPM0_FPD_M01_axil_rready;
wire  [1:0] HPM0_FPD_M01_axil_rresp;
wire HPM0_FPD_M01_axil_rvalid;
wire  [31:0] HPM0_FPD_M01_axil_wdata;
wire HPM0_FPD_M01_axil_wready;
wire  [3:0] HPM0_FPD_M01_axil_wstrb;
wire HPM0_FPD_M01_axil_wvalid;
wire  [39:0] HPM0_FPD_M02_axil_araddr;
wire  [2:0] HPM0_FPD_M02_axil_arprot;
wire HPM0_FPD_M02_axil_arready;
wire HPM0_FPD_M02_axil_arvalid;
wire  [39:0] HPM0_FPD_M02_axil_awaddr;
wire  [2:0] HPM0_FPD_M02_axil_awprot;
wire HPM0_FPD_M02_axil_awready;
wire HPM0_FPD_M02_axil_awvalid;
wire HPM0_FPD_M02_axil_bready;
wire  [1:0] HPM0_FPD_M02_axil_bresp;
wire HPM0_FPD_M02_axil_bvalid;
wire  [31:0] HPM0_FPD_M02_axil_rdata;
wire HPM0_FPD_M02_axil_rready;
wire  [1:0] HPM0_FPD_M02_axil_rresp;
wire HPM0_FPD_M02_axil_rvalid;
wire  [31:0] HPM0_FPD_M02_axil_wdata;
wire HPM0_FPD_M02_axil_wready;
wire  [3:0] HPM0_FPD_M02_axil_wstrb;
wire HPM0_FPD_M02_axil_wvalid;
wire  [39:0] HPM0_FPD_M03_axil_araddr;
wire  [2:0] HPM0_FPD_M03_axil_arprot;
wire HPM0_FPD_M03_axil_arready;
wire HPM0_FPD_M03_axil_arvalid;
wire  [39:0] HPM0_FPD_M03_axil_awaddr;
wire  [2:0] HPM0_FPD_M03_axil_awprot;
wire HPM0_FPD_M03_axil_awready;
wire HPM0_FPD_M03_axil_awvalid;
wire HPM0_FPD_M03_axil_bready;
wire  [1:0] HPM0_FPD_M03_axil_bresp;
wire HPM0_FPD_M03_axil_bvalid;
wire  [31:0] HPM0_FPD_M03_axil_rdata;
wire HPM0_FPD_M03_axil_rready;
wire  [1:0] HPM0_FPD_M03_axil_rresp;
wire HPM0_FPD_M03_axil_rvalid;
wire  [31:0] HPM0_FPD_M03_axil_wdata;
wire HPM0_FPD_M03_axil_wready;
wire  [3:0] HPM0_FPD_M03_axil_wstrb;
wire HPM0_FPD_M03_axil_wvalid;
wire  [39:0] HPM0_FPD_M04_axil_araddr;
wire  [2:0] HPM0_FPD_M04_axil_arprot;
wire HPM0_FPD_M04_axil_arready;
wire HPM0_FPD_M04_axil_arvalid;
wire  [39:0] HPM0_FPD_M04_axil_awaddr;
wire  [2:0] HPM0_FPD_M04_axil_awprot;
wire HPM0_FPD_M04_axil_awready;
wire HPM0_FPD_M04_axil_awvalid;
wire HPM0_FPD_M04_axil_bready;
wire  [1:0] HPM0_FPD_M04_axil_bresp;
wire HPM0_FPD_M04_axil_bvalid;
wire  [31:0] HPM0_FPD_M04_axil_rdata;
wire HPM0_FPD_M04_axil_rready;
wire  [1:0] HPM0_FPD_M04_axil_rresp;
wire HPM0_FPD_M04_axil_rvalid;
wire  [31:0] HPM0_FPD_M04_axil_wdata;
wire HPM0_FPD_M04_axil_wready;
wire  [3:0] HPM0_FPD_M04_axil_wstrb;
wire HPM0_FPD_M04_axil_wvalid;
wire axil_arst_n, axil_rst;


system_wrapper system_wrapper_inst (
	.mpsoc_clk_100(mpsoc_clk_100),
	//HPM0_FPD signals
	.HPM0_FPD_M00_axil_araddr(HPM0_FPD_M00_axil_araddr),
	.HPM0_FPD_M00_axil_arprot(HPM0_FPD_M00_axil_arprot),
	.HPM0_FPD_M00_axil_arready(HPM0_FPD_M00_axil_arready),
	.HPM0_FPD_M00_axil_arvalid(HPM0_FPD_M00_axil_arvalid),
	.HPM0_FPD_M00_axil_awaddr(HPM0_FPD_M00_axil_awaddr),
	.HPM0_FPD_M00_axil_awprot(HPM0_FPD_M00_axil_awprot),
	.HPM0_FPD_M00_axil_awready(HPM0_FPD_M00_axil_awready),
	.HPM0_FPD_M00_axil_awvalid(HPM0_FPD_M00_axil_awvalid),
	.HPM0_FPD_M00_axil_bready(HPM0_FPD_M00_axil_bready),
	.HPM0_FPD_M00_axil_bresp(HPM0_FPD_M00_axil_bresp),
	.HPM0_FPD_M00_axil_bvalid(HPM0_FPD_M00_axil_bvalid),
	.HPM0_FPD_M00_axil_rdata(HPM0_FPD_M00_axil_rdata),
	.HPM0_FPD_M00_axil_rready(HPM0_FPD_M00_axil_rready),
	.HPM0_FPD_M00_axil_rresp(HPM0_FPD_M00_axil_rresp),
	.HPM0_FPD_M00_axil_rvalid(HPM0_FPD_M00_axil_rvalid),
	.HPM0_FPD_M00_axil_wdata(HPM0_FPD_M00_axil_wdata),
	.HPM0_FPD_M00_axil_wready(HPM0_FPD_M00_axil_wready),
	.HPM0_FPD_M00_axil_wstrb(HPM0_FPD_M00_axil_wstrb),
	.HPM0_FPD_M00_axil_wvalid(HPM0_FPD_M00_axil_wvalid),
	.HPM0_FPD_M01_axil_araddr(HPM0_FPD_M01_axil_araddr),
	.HPM0_FPD_M01_axil_arprot(HPM0_FPD_M01_axil_arprot),
	.HPM0_FPD_M01_axil_arready(HPM0_FPD_M01_axil_arready),
	.HPM0_FPD_M01_axil_arvalid(HPM0_FPD_M01_axil_arvalid),
	.HPM0_FPD_M01_axil_awaddr(HPM0_FPD_M01_axil_awaddr),
	.HPM0_FPD_M01_axil_awprot(HPM0_FPD_M01_axil_awprot),
	.HPM0_FPD_M01_axil_awready(HPM0_FPD_M01_axil_awready),
	.HPM0_FPD_M01_axil_awvalid(HPM0_FPD_M01_axil_awvalid),
	.HPM0_FPD_M01_axil_bready(HPM0_FPD_M01_axil_bready),
	.HPM0_FPD_M01_axil_bresp(HPM0_FPD_M01_axil_bresp),
	.HPM0_FPD_M01_axil_bvalid(HPM0_FPD_M01_axil_bvalid),
	.HPM0_FPD_M01_axil_rdata(HPM0_FPD_M01_axil_rdata),
	.HPM0_FPD_M01_axil_rready(HPM0_FPD_M01_axil_rready),
	.HPM0_FPD_M01_axil_rresp(HPM0_FPD_M01_axil_rresp),
	.HPM0_FPD_M01_axil_rvalid(HPM0_FPD_M01_axil_rvalid),
	.HPM0_FPD_M01_axil_wdata(HPM0_FPD_M01_axil_wdata),
	.HPM0_FPD_M01_axil_wready(HPM0_FPD_M01_axil_wready),
	.HPM0_FPD_M01_axil_wstrb(HPM0_FPD_M01_axil_wstrb),
	.HPM0_FPD_M01_axil_wvalid(HPM0_FPD_M01_axil_wvalid),
	.HPM0_FPD_M02_axil_araddr(HPM0_FPD_M02_axil_araddr),
	.HPM0_FPD_M02_axil_arprot(HPM0_FPD_M02_axil_arprot),
	.HPM0_FPD_M02_axil_arready(HPM0_FPD_M02_axil_arready),
	.HPM0_FPD_M02_axil_arvalid(HPM0_FPD_M02_axil_arvalid),
	.HPM0_FPD_M02_axil_awaddr(HPM0_FPD_M02_axil_awaddr),
	.HPM0_FPD_M02_axil_awprot(HPM0_FPD_M02_axil_awprot),
	.HPM0_FPD_M02_axil_awready(HPM0_FPD_M02_axil_awready),
	.HPM0_FPD_M02_axil_awvalid(HPM0_FPD_M02_axil_awvalid),
	.HPM0_FPD_M02_axil_bready(HPM0_FPD_M02_axil_bready),
	.HPM0_FPD_M02_axil_bresp(HPM0_FPD_M02_axil_bresp),
	.HPM0_FPD_M02_axil_bvalid(HPM0_FPD_M02_axil_bvalid),
	.HPM0_FPD_M02_axil_rdata(HPM0_FPD_M02_axil_rdata),
	.HPM0_FPD_M02_axil_rready(HPM0_FPD_M02_axil_rready),
	.HPM0_FPD_M02_axil_rresp(HPM0_FPD_M02_axil_rresp),
	.HPM0_FPD_M02_axil_rvalid(HPM0_FPD_M02_axil_rvalid),
	.HPM0_FPD_M02_axil_wdata(HPM0_FPD_M02_axil_wdata),
	.HPM0_FPD_M02_axil_wready(HPM0_FPD_M02_axil_wready),
	.HPM0_FPD_M02_axil_wstrb(HPM0_FPD_M02_axil_wstrb),
	.HPM0_FPD_M02_axil_wvalid(HPM0_FPD_M02_axil_wvalid),
	.HPM0_FPD_M03_axil_araddr(HPM0_FPD_M03_axil_araddr),
	.HPM0_FPD_M03_axil_arprot(HPM0_FPD_M03_axil_arprot),
	.HPM0_FPD_M03_axil_arready(HPM0_FPD_M03_axil_arready),
	.HPM0_FPD_M03_axil_arvalid(HPM0_FPD_M03_axil_arvalid),
	.HPM0_FPD_M03_axil_awaddr(HPM0_FPD_M03_axil_awaddr),
	.HPM0_FPD_M03_axil_awprot(HPM0_FPD_M03_axil_awprot),
	.HPM0_FPD_M03_axil_awready(HPM0_FPD_M03_axil_awready),
	.HPM0_FPD_M03_axil_awvalid(HPM0_FPD_M03_axil_awvalid),
	.HPM0_FPD_M03_axil_bready(HPM0_FPD_M03_axil_bready),
	.HPM0_FPD_M03_axil_bresp(HPM0_FPD_M03_axil_bresp),
	.HPM0_FPD_M03_axil_bvalid(HPM0_FPD_M03_axil_bvalid),
	.HPM0_FPD_M03_axil_rdata(HPM0_FPD_M03_axil_rdata),
	.HPM0_FPD_M03_axil_rready(HPM0_FPD_M03_axil_rready),
	.HPM0_FPD_M03_axil_rresp(HPM0_FPD_M03_axil_rresp),
	.HPM0_FPD_M03_axil_rvalid(HPM0_FPD_M03_axil_rvalid),
	.HPM0_FPD_M03_axil_wdata(HPM0_FPD_M03_axil_wdata),
	.HPM0_FPD_M03_axil_wready(HPM0_FPD_M03_axil_wready),
	.HPM0_FPD_M03_axil_wstrb(HPM0_FPD_M03_axil_wstrb),
	.HPM0_FPD_M03_axil_wvalid(HPM0_FPD_M03_axil_wvalid),
	.HPM0_FPD_M04_axil_araddr(HPM0_FPD_M04_axil_araddr),
	.HPM0_FPD_M04_axil_arprot(HPM0_FPD_M04_axil_arprot),
	.HPM0_FPD_M04_axil_arready(HPM0_FPD_M04_axil_arready),
	.HPM0_FPD_M04_axil_arvalid(HPM0_FPD_M04_axil_arvalid),
	.HPM0_FPD_M04_axil_awaddr(HPM0_FPD_M04_axil_awaddr),
	.HPM0_FPD_M04_axil_awprot(HPM0_FPD_M04_axil_awprot),
	.HPM0_FPD_M04_axil_awready(HPM0_FPD_M04_axil_awready),
	.HPM0_FPD_M04_axil_awvalid(HPM0_FPD_M04_axil_awvalid),
	.HPM0_FPD_M04_axil_bready(HPM0_FPD_M04_axil_bready),
	.HPM0_FPD_M04_axil_bresp(HPM0_FPD_M04_axil_bresp),
	.HPM0_FPD_M04_axil_bvalid(HPM0_FPD_M04_axil_bvalid),
	.HPM0_FPD_M04_axil_rdata(HPM0_FPD_M04_axil_rdata),
	.HPM0_FPD_M04_axil_rready(HPM0_FPD_M04_axil_rready),
	.HPM0_FPD_M04_axil_rresp(HPM0_FPD_M04_axil_rresp),
	.HPM0_FPD_M04_axil_rvalid(HPM0_FPD_M04_axil_rvalid),
	.HPM0_FPD_M04_axil_wdata(HPM0_FPD_M04_axil_wdata),
	.HPM0_FPD_M04_axil_wready(HPM0_FPD_M04_axil_wready),
	.HPM0_FPD_M04_axil_wstrb(HPM0_FPD_M04_axil_wstrb),
	.HPM0_FPD_M04_axil_wvalid(HPM0_FPD_M04_axil_wvalid),
	.axil_rst(axil_rst),
	.axil_arst_n(axil_arst_n)
);

wire reset;
wire enable_adc;
wire enable_bram;
wire enable_correlator;
wire [31:0] delay_line, acc_len;

wire correlator_ack;


s_axil_reg #(
	.DATA_WIDTH(32),
	.ADDR_WIDTH(4)
) s_axil_reg_inst0 (
//
//put user inputs outputs  TODO!!
    //outputs
    .reset(reset),
    .enable_adc(enable_adc),
    .enable_bram(enable_bram),
    .delay_line(delay_line),
    .acc_len(acc_len),
    .enable_correlator(enable_correlator),
    //inputs
    .bitslip_count(bitslip_count),
    .mmcm_locked(mmcm_locked),
    .clk_align_frame_valid(clk_align_frame_valid),
   //ok signals and data from the correlator
    .correlator_valid(corr_data_available),
    .correlator_ack_error(corr_ack_error),
    .correlator_ack(correlator_ack),
    .pow0_0(pow0_0),
    .pow0_1(pow0_1), 
    .pow1_0(pow1_0), 
    .pow1_1(pow1_1),
    .ab_real_0(ab_real_0),
    .ab_real_1(ab_real_1),
    .ab_imag_0(ab_imag_0),
    .ab_imag_1(ab_imag_1),
    //axi interface
	.s_axil_araddr(HPM0_FPD_M01_axil_araddr),
	.s_axil_arprot(HPM0_FPD_M01_axil_arprot),
	.s_axil_arready(HPM0_FPD_M01_axil_arready),
	.s_axil_arvalid(HPM0_FPD_M01_axil_arvalid),
	.s_axil_awaddr(HPM0_FPD_M01_axil_awaddr),
	.s_axil_awprot(HPM0_FPD_M01_axil_awprot),
	.s_axil_awready(HPM0_FPD_M01_axil_awready),
	.s_axil_awvalid(HPM0_FPD_M01_axil_awvalid),
	.s_axil_bready(HPM0_FPD_M01_axil_bready),
	.s_axil_bresp(HPM0_FPD_M01_axil_bresp),
	.s_axil_bvalid(HPM0_FPD_M01_axil_bvalid),
	.s_axil_rdata(HPM0_FPD_M01_axil_rdata),
	.s_axil_rready(HPM0_FPD_M01_axil_rready),
	.s_axil_rresp(HPM0_FPD_M01_axil_rresp),
	.s_axil_rvalid(HPM0_FPD_M01_axil_rvalid),
	.s_axil_wdata(HPM0_FPD_M01_axil_wdata),
	.s_axil_wready(HPM0_FPD_M01_axil_wready),
	.s_axil_wstrb(HPM0_FPD_M01_axil_wstrb),
	.s_axil_wvalid(HPM0_FPD_M01_axil_wvalid),
	.axi_clock(mpsoc_clk_100),
	.rst(axil_rst)
);

//ouptut clock

output_clock #(
    .ARCHITECTURE("ULTRASCALE")   //ultrascale or 7-series

) output_clock_inst (
    .clk(mpsoc_clk_100),
    .adc_ref_clk_p(syzygy_c2p_clk_p),
    .adc_ref_clk_n(syzygy_c2p_clk_n)
);



//create clocks
wire data_clk_bufio;
wire data_clk_div;
wire mmcm_locked;
wire [7:0] iserdes_dout;
wire [3:0] bitslip_count;
wire clk_align_frame_valid;


reg [2:0] sync_rst_buf;
wire sync_rst = sync_rst_buf[2];
always@(posedge data_clk_div)begin
    sync_rst_buf <= {sync_rst_buf[1:0], reset};
end

reg [3:0] bitslip_count_r=0;
reg mmcm_locked_r=0;
reg data_valid_r =0;
always@(posedge mpsoc_clk_100) begin
    bitslip_count_r <= bitslip_count;
    mmcm_locked_r <= mmcm_locked;
    data_valid_r <= clk_align_frame_valid;
end

//assign led0[0] = bitslip_count_r;
//assign led0[1] = mmcm_locked_r;
//assign led1[0] = data_valid_r;
//
assign led0[0] = corr_data_available;
assign led1[1] = corr_ack_error;

clock_alignment #(
    .ADC_BITS(14),
    .IOSTANDARD("LVDS"),
    .CLKIN1_PERIOD(2.5),//2 this is the good value for having 125mhz wiht the configuration
    .CLKFBOUT_PHASE(-126)//-126
) clock_alignment_inst (
    .data_clock_p(syzygy_p2c_clk_p),
    .data_clock_n(syzygy_p2c_clk_n),
    .frame_clock_p(syzygy_d1_p),
    .frame_clock_n(syzygy_d1_n),
    .async_rst(reset),
    .sync_rst(sync_rst),
    .enable(enable_adc),
    .data_clk_bufio(data_clk_bufio),
    .data_clk_div(data_clk_div),
    .mmcm_locked(mmcm_locked),
    .iserdes_dout(iserdes_dout),
    .iserdes2_bitslip(),
    .bitslip_count(bitslip_count),
    .frame_valid(clk_align_frame_valid)
);



wire [15:0] adc0_data, adc1_data;
wire [7:0] iserdes0_dout0, iserdes0_dout1,
            iserdes1_dout0, iserdes1_dout1;  

data_phy data_phy_inst0 (
    .sync_rst(sync_rst),
    .adc_data_p({syzygy_d2_p, syzygy_d0_p}),
    .adc_data_n({syzygy_d2_n, syzygy_d0_n}),
    //these signals came from the clock alignment module
    .data_clk_bufio(data_clk_bufio),
    .data_clk_div(data_clk_div),
    .bitslip_count(bitslip_count),
    .adc_data(adc0_data),
    //debuging signals
    .iserdes0_dout(iserdes0_dout0),
    .iserdes1_dout(iserdes1_dout0)
);


data_phy data_phy_inst1 (
    .sync_rst(sync_rst),
    .adc_data_p({syzygy_d5_p, syzygy_d3_p}),
    .adc_data_n({syzygy_d5_n, syzygy_d3_n}),
    //these signals came from the clock alignment module
    .data_clk_bufio(data_clk_bufio),
    .data_clk_div(data_clk_div),
    .bitslip_count(bitslip_count),
    .adc_data(adc1_data),
    //debuging signals
    .iserdes0_dout(iserdes0_dout1),
    .iserdes1_dout(iserdes1_dout1)
);






//logic to capture adc data
reg [2:0] enable_bram_buf=0;
always@(posedge data_clk_div)
    enable_bram_buf <= {enable_bram_buf[1:0], enable_bram};
wire enable_bram_sync = enable_bram_buf[2];
//
//
reg enable_bram_r=0, capture=0;
always@(posedge data_clk_div)begin
    enable_bram_r <= enable_bram_sync;
    if(enable_bram_sync & ~enable_bram_r)
        capture <= 1;
    else if(enable_bram_r & ~enable_bram_sync)
        capture <= 0;
end

reg [CAPTURE_ADDR:0] bram_addr={(CAPTURE_ADDR+1){1'b1}};
reg bram_we=0;
always@(posedge data_clk_div)begin
    if(capture)begin
        if(bram_addr!=({(CAPTURE_ADDR){1'b1}}))begin
            bram_addr <= bram_addr+1;
            bram_we <=1;
        end
        else
            bram_we <=0;
    end
    else begin
        bram_addr <={(CAPTURE_ADDR+1){1'b1}};
        bram_we <= 0;
    end
end

//convert the adc data to signed
//The first 2 bits are zeros and we
wire signed [13:0] adc0_signed, adc1_signed;

assign adc0_signed = {~adc0_data[15], adc0_data[14:2]};
assign adc1_signed = {~adc1_data[15], adc1_data[14:2]};

wire signed [15:0] adc0_bram = $signed(adc0_signed);
wire signed [15:0] adc1_bram = $signed(adc1_signed);


axil_bram_unbalanced #(
	.FPGA_DATA_WIDTH(32),
	.FPGA_ADDR_WIDTH(CAPTURE_ADDR),
	.AXI_DATA_WIDTH(32)
) axil_bram_inst0 (
	.fpga_clk(data_clk_div),
	.bram_din({adc0_bram, adc1_bram}),
	.bram_addr(bram_addr),
	.bram_we(bram_we),
	.bram_dout(),
	.s_axil_araddr(HPM0_FPD_M00_axil_araddr),
	.s_axil_arprot(HPM0_FPD_M00_axil_arprot),
	.s_axil_arready(HPM0_FPD_M00_axil_arready),
	.s_axil_arvalid(HPM0_FPD_M00_axil_arvalid),
	.s_axil_awaddr(HPM0_FPD_M00_axil_awaddr),
	.s_axil_awprot(HPM0_FPD_M00_axil_awprot),
	.s_axil_awready(HPM0_FPD_M00_axil_awready),
.s_axil_awvalid(HPM0_FPD_M00_axil_awvalid),
	.s_axil_bready(HPM0_FPD_M00_axil_bready),
	.s_axil_bresp(HPM0_FPD_M00_axil_bresp),
	.s_axil_bvalid(HPM0_FPD_M00_axil_bvalid),
	.s_axil_rdata(HPM0_FPD_M00_axil_rdata),
	.s_axil_rready(HPM0_FPD_M00_axil_rready),
	.s_axil_rresp(HPM0_FPD_M00_axil_rresp),
	.s_axil_rvalid(HPM0_FPD_M00_axil_rvalid),
	.s_axil_wdata(HPM0_FPD_M00_axil_wdata),
	.s_axil_wready(HPM0_FPD_M00_axil_wready),
	.s_axil_wstrb(HPM0_FPD_M00_axil_wstrb),
	.s_axil_wvalid(HPM0_FPD_M00_axil_wvalid),
	.axi_clock(mpsoc_clk_100),
	.rst(axil_rst)
);




wire [CORR_DOUT_WIDTH-1:0] aa, bb;
wire signed [CORR_DOUT_WIDTH-1:0] ab_re, ab_im;
wire corr_dout_valid;

single_bin_fx_correlator #(
    .DIN_WIDTH(DIN_WIDTH),
    .DIN_POINT(DIN_POINT),
    .TWIDD_WIDTH(TWIDD_WIDTH),
    .TWIDD_POINT(TWIDD_POINT),
    .TWIDD_FILE(TWIDD_FILE),
    .TWIDD_DELAY(TWIDD_DELAY),
    .ACC_DELAY(ACC_DELAY),
    .DFT_LEN(DFT_LEN),
    .DFT_DOUT_WIDTH(DFT_DOUT_WIDTH),
    .DFT_DOUT_POINT(DFT_DOUT_POINT),
    .DFT_DOUT_DELAY(DFT_DOUT_DELAY),
    .ACC_WIDTH(ACC_WIDTH),
    .ACC_POINT(ACC_POINT),
    .ACC_IN_DELAY(ACC_IN_DELAY),
    .ACC_OUT_DELAY(ACC_OUT_DELAY),
    .DOUT_WIDTH(CORR_DOUT_WIDTH)
) single_bin_fx_correlator_inst (
    .clk(data_clk_div),
    .rst(reset), 
    .din0_re(adc0_signed),
    .din0_im({(DIN_WIDTH){1'b0}}),
    .din1_re(adc1_signed),
    .din1_im({(DIN_WIDTH){1'b0}}),
    .din_valid(enable_correlator),
    .delay_line(delay_line),
    .acc_len(acc_len),
    .aa(aa),
    .bb(bb), 
    .ab_re(ab_re),
    .ab_im(ab_im),
    .dout_valid(corr_dout_valid),
    .axi_clock(mpsoc_clk_100),
    .axil_rst(axil_rst),
    .s_axil_awaddr(HPM0_FPD_M02_axil_awaddr),
    .s_axil_awprot(HPM0_FPD_M02_axil_awprot),
    .s_axil_awvalid(HPM0_FPD_M02_axil_awvalid),
    .s_axil_awready(HPM0_FPD_M02_axil_awready),
    .s_axil_wdata(HPM0_FPD_M02_axil_wdata),
    .s_axil_wstrb(HPM0_FPD_M02_axil_wstrb),
    .s_axil_wvalid(HPM0_FPD_M02_axil_wvalid),
    .s_axil_wready(HPM0_FPD_M02_axil_wready),
    .s_axil_bresp(HPM0_FPD_M02_axil_bresp),
    .s_axil_bvalid(HPM0_FPD_M02_axil_bvalid),
    .s_axil_bready(HPM0_FPD_M02_axil_bready),
    .s_axil_araddr(HPM0_FPD_M02_axil_araddr),
    .s_axil_arvalid(HPM0_FPD_M02_axil_arvalid),
    .s_axil_arready(HPM0_FPD_M02_axil_arready),
    .s_axil_arprot(HPM0_FPD_M02_axil_arprot),
    .s_axil_rdata(HPM0_FPD_M02_axil_rdata),
    .s_axil_rresp(HPM0_FPD_M02_axil_rresp),
    .s_axil_rvalid(HPM0_FPD_M02_axil_rvalid),
    .s_axil_rready(HPM0_FPD_M02_axil_rready)
);

//This is a simple logic that takes the data and write it into a axi-lite reg

//clock domain crossing
wire [63:0] aa_axi, bb_axi, ab_re_axi, ab_im_axi;
wire corr_valid_axi;
delay #(
    .DATA_WIDTH(64*4+1),
    .DELAY_VALUE(3)
) synchronizer (
    .clk(mpsoc_clk_100),
    .din({aa,bb,ab_re,ab_im,corr_dout_valid}),
    .dout({aa_axi, bb_axi, ab_re_axi, ab_im_axi, corr_valid_axi})
);


reg corr_data_available = 0;    //data present flag
reg corr_ack_error = 0;
reg [31:0] pow0_0=0, pow0_1=0;
reg [31:0] pow1_0=0, pow1_1=0;
reg [31:0] ab_real_0=0, ab_real_1=0;
reg [31:0] ab_imag_0=0, ab_imag_1=0;
reg correlator_ack_r =0;    //to detect rising edges

always@(posedge mpsoc_clk_100)begin
    correlator_ack_r <= correlator_ack;
    if(reset)begin
        corr_data_available <= 0;
        corr_ack_error <= 0;
    end
    else if(~corr_data_available)begin
        if(corr_valid_axi)begin
            corr_data_available <= 1; 
            pow0_0 <= aa_axi[0+:32];
            pow0_1 <= aa_axi[32+:32];
            pow1_0 <= bb_axi[0+:32];
            pow1_1 <= bb_axi[32+:32];
            ab_real_0 <= ab_re_axi[0+:32];
            ab_real_1 <= ab_re_axi[32+:32];
            ab_imag_0 <= ab_im_axi[0+:32];
            ab_imag_1 <= ab_im_axi[32+:32];
        end
    end
    else if(corr_data_available)begin
        if(corr_valid_axi)
            corr_ack_error <= 1;
        else if(correlator_ack & ~correlator_ack_r)
            corr_data_available <= 0;
    end
end







//In this case the system is writing continously a bram.. it takes ages to
//write the complete bram

reg [9:0] bram_counter = 0;
always@(posedge data_clk_div)begin
    if(reset)
        bram_counter <= 0;
    else if(corr_dout_valid)
        bram_counter<=bram_counter+1;
end

 axil_bram_unbalanced #(
	.FPGA_DATA_WIDTH(128),
	.FPGA_ADDR_WIDTH(10),
	.AXI_DATA_WIDTH(32)
) axil_bram_inst2 (
	.fpga_clk(data_clk_div),
	.bram_din({bb,aa}),
	.bram_addr(bram_counter),
	.bram_we(corr_dout_valid),
	.bram_dout(),
	.s_axil_araddr(HPM0_FPD_M03_axil_araddr),
	.s_axil_arprot(HPM0_FPD_M03_axil_arprot),
	.s_axil_arready(HPM0_FPD_M03_axil_arready),
	.s_axil_arvalid(HPM0_FPD_M03_axil_arvalid),
	.s_axil_awaddr(HPM0_FPD_M03_axil_awaddr),
	.s_axil_awprot(HPM0_FPD_M03_axil_awprot),
	.s_axil_awready(HPM0_FPD_M03_axil_awready),
	.s_axil_awvalid(HPM0_FPD_M03_axil_awvalid),
	.s_axil_bready(HPM0_FPD_M03_axil_bready),
	.s_axil_bresp(HPM0_FPD_M03_axil_bresp),
	.s_axil_bvalid(HPM0_FPD_M03_axil_bvalid),
	.s_axil_rdata(HPM0_FPD_M03_axil_rdata),
	.s_axil_rready(HPM0_FPD_M03_axil_rready),
	.s_axil_rresp(HPM0_FPD_M03_axil_rresp),
	.s_axil_rvalid(HPM0_FPD_M03_axil_rvalid),
	.s_axil_wdata(HPM0_FPD_M03_axil_wdata),
	.s_axil_wready(HPM0_FPD_M03_axil_wready),
	.s_axil_wstrb(HPM0_FPD_M03_axil_wstrb),
	.s_axil_wvalid(HPM0_FPD_M03_axil_wvalid),
	.axi_clock(mpsoc_clk_100),
	.rst(axil_rst)
);

 axil_bram_unbalanced #(
	.FPGA_DATA_WIDTH(128),
	.FPGA_ADDR_WIDTH(10),
	.AXI_DATA_WIDTH(32)
) axil_bram_inst3 (
	.fpga_clk(data_clk_div),
	.bram_din({ab_im, ab_re}),
	.bram_addr(bram_counter),
	.bram_we(corr_dout_valid),
	.bram_dout(),
	.s_axil_araddr(HPM0_FPD_M04_axil_araddr),
	.s_axil_arprot(HPM0_FPD_M04_axil_arprot),
	.s_axil_arready(HPM0_FPD_M04_axil_arready),
	.s_axil_arvalid(HPM0_FPD_M04_axil_arvalid),
	.s_axil_awaddr(HPM0_FPD_M04_axil_awaddr),
	.s_axil_awprot(HPM0_FPD_M04_axil_awprot),
	.s_axil_awready(HPM0_FPD_M04_axil_awready),
	.s_axil_awvalid(HPM0_FPD_M04_axil_awvalid),
	.s_axil_bready(HPM0_FPD_M04_axil_bready),
	.s_axil_bresp(HPM0_FPD_M04_axil_bresp),
	.s_axil_bvalid(HPM0_FPD_M04_axil_bvalid),
	.s_axil_rdata(HPM0_FPD_M04_axil_rdata),
	.s_axil_rready(HPM0_FPD_M04_axil_rready),
	.s_axil_rresp(HPM0_FPD_M04_axil_rresp),
	.s_axil_rvalid(HPM0_FPD_M04_axil_rvalid),
	.s_axil_wdata(HPM0_FPD_M04_axil_wdata),
	.s_axil_wready(HPM0_FPD_M04_axil_wready),
	.s_axil_wstrb(HPM0_FPD_M04_axil_wstrb),
	.s_axil_wvalid(HPM0_FPD_M04_axil_wvalid),
	.axi_clock(mpsoc_clk_100),
	.rst(axil_rst)
);
endmodule
`resetall
