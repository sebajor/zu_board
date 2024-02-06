//`include "system_wrapper.v"
//`include "skid_buffer.v"
//`include "s_axil_reg.v"
//`include "axil_bram.v"
//`include "axil_bram_arbiter.v"
//`include "async_true_dual_ram.v"




module fpga (
    output wire [2:0] led0, led1
);

wire [39:0]HPM0_FPD_M00_axil_araddr;
wire [2:0]HPM0_FPD_M00_axil_arprot;
wire [0:0]HPM0_FPD_M00_axil_arready;
wire [0:0]HPM0_FPD_M00_axil_arvalid;
wire [39:0]HPM0_FPD_M00_axil_awaddr;
wire [2:0]HPM0_FPD_M00_axil_awprot;
wire [0:0]HPM0_FPD_M00_axil_awready;
wire [0:0]HPM0_FPD_M00_axil_awvalid;
wire [0:0]HPM0_FPD_M00_axil_bready;
wire [1:0]HPM0_FPD_M00_axil_bresp;
wire [0:0]HPM0_FPD_M00_axil_bvalid;
wire [31:0]HPM0_FPD_M00_axil_rdata;
wire [0:0]HPM0_FPD_M00_axil_rready;
wire [1:0]HPM0_FPD_M00_axil_rresp;
wire [0:0]HPM0_FPD_M00_axil_rvalid;
wire [31:0]HPM0_FPD_M00_axil_wdata;
wire [0:0]HPM0_FPD_M00_axil_wready;
wire [3:0]HPM0_FPD_M00_axil_wstrb;
wire [0:0]HPM0_FPD_M00_axil_wvalid;
   
wire [39:0]HPM0_FPD_M01_axil_araddr;
wire [2:0]HPM0_FPD_M01_axil_arprot;
wire [0:0]HPM0_FPD_M01_axil_arready;
wire [0:0]HPM0_FPD_M01_axil_arvalid;
wire [39:0]HPM0_FPD_M01_axil_awaddr;
wire [2:0]HPM0_FPD_M01_axil_awprot;
wire [0:0]HPM0_FPD_M01_axil_awready;
wire [0:0]HPM0_FPD_M01_axil_awvalid;
wire [0:0]HPM0_FPD_M01_axil_bready;
wire [1:0]HPM0_FPD_M01_axil_bresp;
wire [0:0]HPM0_FPD_M01_axil_bvalid;
wire [31:0]HPM0_FPD_M01_axil_rdata;
wire [0:0]HPM0_FPD_M01_axil_rready;
wire [1:0]HPM0_FPD_M01_axil_rresp;
wire [0:0]HPM0_FPD_M01_axil_rvalid;
wire [31:0]HPM0_FPD_M01_axil_wdata;
wire [0:0]HPM0_FPD_M01_axil_wready;
wire [3:0]HPM0_FPD_M01_axil_wstrb;
wire [0:0]HPM0_FPD_M01_axil_wvalid;
wire [0:0]axil_arst_n;
wire [0:0]axil_rst;
wire pl_sys_clk;



system_wrapper system_wrapper_inst (
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
    .axil_arst_n(axil_arst_n),
    .axil_rst(axil_rst),
    .pl_sys_clk(pl_sys_clk)
);

wire [31:0] bram_write, bram_read, leds, bram_addr;
wire bram_we;

s_axil_reg #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(3)
) s_axil_reg_inst  (
    .bram_write(bram_write),
    .bram_addr(bram_addr),
    .bram_we(bram_we),
    .bram_read(bram_read),
    .leds(leds),
    .axi_clock(pl_sys_clk), 
    .rst(axil_rst), 
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
assign led0 = leds[2:0];
assign led1 = leds[5:3];


axil_bram #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(10)
) axil_bram_inst (
    .axi_clock(pl_sys_clk), 
    .rst(axil_rst), 
    .s_axil_awaddr(HPM0_FPD_M01_axil_awaddr),
    .s_axil_awprot(HPM0_FPD_M01_axil_awprot),
    .s_axil_awvalid(HPM0_FPD_M01_axil_awvalid),
    .s_axil_awready(HPM0_FPD_M01_axil_awready),
    .s_axil_wdata(HPM0_FPD_M01_axil_wdata),
    .s_axil_wstrb(HPM0_FPD_M01_axil_wstrb),
    .s_axil_wvalid(HPM0_FPD_M01_axil_wvalid),
    .s_axil_wready(HPM0_FPD_M01_axil_wready),
    .s_axil_bresp(HPM0_FPD_M01_axil_bresp),
    .s_axil_bvalid(HPM0_FPD_M01_axil_bvalid),
    .s_axil_bready(HPM0_FPD_M01_axil_bready),
    .s_axil_araddr(HPM0_FPD_M01_axil_araddr),
    .s_axil_arvalid(HPM0_FPD_M01_axil_arvalid),
    .s_axil_arready(HPM0_FPD_M01_axil_arready),
    .s_axil_arprot(HPM0_FPD_M01_axil_arprot),
    .s_axil_rdata(HPM0_FPD_M01_axil_rdata),
    .s_axil_rresp(HPM0_FPD_M01_axil_rresp),
    .s_axil_rvalid(HPM0_FPD_M01_axil_rvalid),
    .s_axil_rready(HPM0_FPD_M01_axil_rready),
    .fpga_clk(pl_sys_clk),
    .bram_din(bram_write),
    .bram_addr(bram_addr[9:0]),
    .bram_we(bram_we),
    .bram_dout(bram_read)
);


endmodule
