//default_nettype none

/*
*   Like it is not advisable to ouptut directly a clock (bcs you want to keep the 
*   clock in global clock net, if you just output it can generate some routing problems)
*
*/

module output_clock #(
    parameter ARCHITECTURE = "ULTRASCALE"   //ultrascale or SEVEN_series

)(
    input wire clk,
    output wire adc_ref_clk_p, adc_ref_clk_n
);

generate
    if(ARCHITECTURE=="SEVEN_SERIES")begin
        wire adc_ref_clk;

        ODDR #(
            .DDR_CLK_EDGE("OPPOSITE_EDGE"),
            .INIT (1'b0),
            .SRTYPE("SYNC")
        ) adc_clk_oddr (
            .Q(adc_ref_clk),
            .C(clk),
            .CE(1'b1),
            .D1(1'b1),
            .D2(1'b0),
            .R(1'b0),
            .S(1'b0)
        );
        OBUFDS adc_clk_obuf (
            .I(adc_ref_clk),
            .O(adc_ref_clk_p),
            .OB(adc_ref_clk_n)
        );
    end
    else if(ARCHITECTURE=="ULTRASCALE")begin
        wire adc_ref_clk;
        ODDRE1 #(
            .IS_C_INVERTED(1'b0),           // Optional inversion for C
            .IS_D1_INVERTED(1'b0),          // Unsupported, do not use
            .IS_D2_INVERTED(1'b0),          // Unsupported, do not use
            .SIM_DEVICE("ULTRASCALE_PLUS"), // Set the device version for simulation functionality (ULTRASCALE,
            .SRVAL(1'b0)                    // Initializes the ODDRE1 Flip-Flops to the specified value (1'b0, 1'b1)
        )adc_clk_oddr (
            .Q(adc_ref_clk),   // 1-bit output: Data output to IOB
            .C(clk),   // 1-bit input: High-speed clock input
            .D1(1'b1), // 1-bit input: Parallel data input 1
            .D2(1'b0), // 1-bit input: Parallel data input 2
            .SR(1'b0)  // 1-bit input: Active-High Async Reset
        );

        
        OBUFDS #(
            .IOSTANDARD("LVDS"), // Specify the output I/O standard
            .SLEW("FAST") 
        ) adc_enc_obuf (
            .I(adc_ref_clk), 
            .O(adc_ref_clk_p),
            .OB(adc_ref_clk_n)
        );
    end
endgenerate
endmodule


