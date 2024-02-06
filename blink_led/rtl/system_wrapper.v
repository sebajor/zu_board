
module system_wrapper
   (HPM0_FPD_M00_axil_araddr,
    HPM0_FPD_M00_axil_arprot,
    HPM0_FPD_M00_axil_arready,
    HPM0_FPD_M00_axil_arvalid,
    HPM0_FPD_M00_axil_awaddr,
    HPM0_FPD_M00_axil_awprot,
    HPM0_FPD_M00_axil_awready,
    HPM0_FPD_M00_axil_awvalid,
    HPM0_FPD_M00_axil_bready,
    HPM0_FPD_M00_axil_bresp,
    HPM0_FPD_M00_axil_bvalid,
    HPM0_FPD_M00_axil_rdata,
    HPM0_FPD_M00_axil_rready,
    HPM0_FPD_M00_axil_rresp,
    HPM0_FPD_M00_axil_rvalid,
    HPM0_FPD_M00_axil_wdata,
    HPM0_FPD_M00_axil_wready,
    HPM0_FPD_M00_axil_wstrb,
    HPM0_FPD_M00_axil_wvalid,
    HPM0_FPD_M01_axil_araddr,
    HPM0_FPD_M01_axil_arprot,
    HPM0_FPD_M01_axil_arready,
    HPM0_FPD_M01_axil_arvalid,
    HPM0_FPD_M01_axil_awaddr,
    HPM0_FPD_M01_axil_awprot,
    HPM0_FPD_M01_axil_awready,
    HPM0_FPD_M01_axil_awvalid,
    HPM0_FPD_M01_axil_bready,
    HPM0_FPD_M01_axil_bresp,
    HPM0_FPD_M01_axil_bvalid,
    HPM0_FPD_M01_axil_rdata,
    HPM0_FPD_M01_axil_rready,
    HPM0_FPD_M01_axil_rresp,
    HPM0_FPD_M01_axil_rvalid,
    HPM0_FPD_M01_axil_wdata,
    HPM0_FPD_M01_axil_wready,
    HPM0_FPD_M01_axil_wstrb,
    HPM0_FPD_M01_axil_wvalid,
    axil_arst_n,
    axil_rst,
    pl_sys_clk);
  output [39:0]HPM0_FPD_M00_axil_araddr;
  output [2:0]HPM0_FPD_M00_axil_arprot;
  input [0:0]HPM0_FPD_M00_axil_arready;
  output [0:0]HPM0_FPD_M00_axil_arvalid;
  output [39:0]HPM0_FPD_M00_axil_awaddr;
  output [2:0]HPM0_FPD_M00_axil_awprot;
  input [0:0]HPM0_FPD_M00_axil_awready;
  output [0:0]HPM0_FPD_M00_axil_awvalid;
  output [0:0]HPM0_FPD_M00_axil_bready;
  input [1:0]HPM0_FPD_M00_axil_bresp;
  input [0:0]HPM0_FPD_M00_axil_bvalid;
  input [31:0]HPM0_FPD_M00_axil_rdata;
  output [0:0]HPM0_FPD_M00_axil_rready;
  input [1:0]HPM0_FPD_M00_axil_rresp;
  input [0:0]HPM0_FPD_M00_axil_rvalid;
  output [31:0]HPM0_FPD_M00_axil_wdata;
  input [0:0]HPM0_FPD_M00_axil_wready;
  output [3:0]HPM0_FPD_M00_axil_wstrb;
  output [0:0]HPM0_FPD_M00_axil_wvalid;
  output [39:0]HPM0_FPD_M01_axil_araddr;
  output [2:0]HPM0_FPD_M01_axil_arprot;
  input [0:0]HPM0_FPD_M01_axil_arready;
  output [0:0]HPM0_FPD_M01_axil_arvalid;
  output [39:0]HPM0_FPD_M01_axil_awaddr;
  output [2:0]HPM0_FPD_M01_axil_awprot;
  input [0:0]HPM0_FPD_M01_axil_awready;
  output [0:0]HPM0_FPD_M01_axil_awvalid;
  output [0:0]HPM0_FPD_M01_axil_bready;
  input [1:0]HPM0_FPD_M01_axil_bresp;
  input [0:0]HPM0_FPD_M01_axil_bvalid;
  input [31:0]HPM0_FPD_M01_axil_rdata;
  output [0:0]HPM0_FPD_M01_axil_rready;
  input [1:0]HPM0_FPD_M01_axil_rresp;
  input [0:0]HPM0_FPD_M01_axil_rvalid;
  output [31:0]HPM0_FPD_M01_axil_wdata;
  input [0:0]HPM0_FPD_M01_axil_wready;
  output [3:0]HPM0_FPD_M01_axil_wstrb;
  output [0:0]HPM0_FPD_M01_axil_wvalid;
  output [0:0]axil_arst_n;
  output [0:0]axil_rst;
  output pl_sys_clk;

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

  /*
  system system_i
       (.HPM0_FPD_M00_axil_araddr(HPM0_FPD_M00_axil_araddr),
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
        .pl_sys_clk(pl_sys_clk));
    */
endmodule

