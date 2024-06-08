//`default_nettype none

//`include "async_true_dual_ram_read_first.v"
//`include "async_true_dual_ram.v"
//`include "async_true_dual_ram_write_first.v"
//`include "axil_bram_arbiter.v"
//`include "axil_bram_unbalanced.v"
//`include "axil_bram.v"
//`include "bitslip_shift.v"
//`include "clock_alignment.v"
//`include "data_phy.v"
//`include "output_clock.v"
//`include "s_axil_reg.v"
//`include "skid_buffer.v"
//include "system_wrapper.v"
//`include "unbalanced_ram.v"
//`include "xil_primitives.v"

//Top template
module fpga #(
    parameter CAPTURE_ADDR = 10
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
    //inputs
    .bitslip_count(bitslip_count),
    .mmcm_locked(mmcm_locked),
    .clk_align_frame_valid(clk_align_frame_valid),

//
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

assign led0[0] = bitslip_count_r;
assign led0[1] = mmcm_locked_r;
assign led1[0] = data_valid_r;

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

///by default the adc output has 0 in the bits 0,1... So I have to check what to do with them 
// (the data is unsigned, 2comp???)
wire signed [15:0] adc0_out, adc1_out;



axil_bram_unbalanced #(
	.FPGA_DATA_WIDTH(32),
	.FPGA_ADDR_WIDTH(CAPTURE_ADDR),
	.AXI_DATA_WIDTH(32)
) axil_bram_inst0 (
	.fpga_clk(data_clk_div),
	.bram_din({adc0_data, adc1_data}),
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


 axil_bram_unbalanced #(
	.FPGA_DATA_WIDTH(32),
	.FPGA_ADDR_WIDTH(10),
	.AXI_DATA_WIDTH(32)
) axil_bram_inst1 (
	.fpga_clk(data_clk_div),
	.bram_din({iserdes0_dout0, iserdes1_dout0,
               iserdes0_dout1, iserdes1_dout1}),
	.bram_addr(bram_addr),
	.bram_we(bram_we),
	.bram_dout(),
	.s_axil_araddr(HPM0_FPD_M02_axil_araddr),
	.s_axil_arprot(HPM0_FPD_M02_axil_arprot),
	.s_axil_arready(HPM0_FPD_M02_axil_arready),
	.s_axil_arvalid(HPM0_FPD_M02_axil_arvalid),
	.s_axil_awaddr(HPM0_FPD_M02_axil_awaddr),
	.s_axil_awprot(HPM0_FPD_M02_axil_awprot),
	.s_axil_awready(HPM0_FPD_M02_axil_awready),
	.s_axil_awvalid(HPM0_FPD_M02_axil_awvalid),
	.s_axil_bready(HPM0_FPD_M02_axil_bready),
	.s_axil_bresp(HPM0_FPD_M02_axil_bresp),
	.s_axil_bvalid(HPM0_FPD_M02_axil_bvalid),
	.s_axil_rdata(HPM0_FPD_M02_axil_rdata),
	.s_axil_rready(HPM0_FPD_M02_axil_rready),
	.s_axil_rresp(HPM0_FPD_M02_axil_rresp),
	.s_axil_rvalid(HPM0_FPD_M02_axil_rvalid),
	.s_axil_wdata(HPM0_FPD_M02_axil_wdata),
	.s_axil_wready(HPM0_FPD_M02_axil_wready),
	.s_axil_wstrb(HPM0_FPD_M02_axil_wstrb),
	.s_axil_wvalid(HPM0_FPD_M02_axil_wvalid),
	.axi_clock(mpsoc_clk_100),
	.rst(axil_rst)
);

 axil_bram_unbalanced #(
	.FPGA_DATA_WIDTH(32),
	.FPGA_ADDR_WIDTH(10),
	.AXI_DATA_WIDTH(32)
) axil_bram_inst2 (
	.fpga_clk(),
	.bram_din(),
	.bram_addr(),
	.bram_we(),
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
	.FPGA_DATA_WIDTH(32),
	.FPGA_ADDR_WIDTH(10),
	.AXI_DATA_WIDTH(32)
) axil_bram_inst3 (
	.fpga_clk(),
	.bram_din(),
	.bram_addr(),
	.bram_we(),
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
