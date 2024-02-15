#tri-color leds
set_property IOSTANDARD LVCMOS18 [get_ports {led0[*]}]
set_property SLEW SLOW [get_ports {led0[*]}]
set_property DRIVE 8 [get_ports {led0[*]}]
set_property PACKAGE_PIN A7 [ get_ports {led0[0]}]  ;#R
set_property PACKAGE_PIN B6 [ get_ports {led0[1]}]  ;#G
set_property PACKAGE_PIN B5 [ get_ports {led0[2]}]  ;#B

set_property IOSTANDARD LVCMOS18 [get_ports {led1[*]}]
set_property SLEW SLOW [get_ports {led1[*]}]
set_property DRIVE 8 [get_ports {led1[*]}]
set_property PACKAGE_PIN B4 [ get_ports {led1[0]}]  ;#R
set_property PACKAGE_PIN A2 [ get_ports {led1[1]}]  ;#G
set_property PACKAGE_PIN F4 [ get_ports {led1[2]}]  ;#B

#push button
set_property IOSTANDARD LVCMOS18 [get_ports button0]
set_property PACKAGE_PIN F12 [ get_ports button0]  

set_property IOSTANDARD LVCMOS18 [get_ports button1]
set_property PACKAGE_PIN A8 [ get_ports button1]


#syzygy

##The I2C is shared between the three syzygy ports
set_property IOSTANDARD LVCMOS18 [get_ports hd_syzygy_scl]
set_property PACKAGE_PIN B9 [get_ports hd_syzygy_scl]
set_property IOSTANDARD LVCMOS18 [get_ports hd_syzygy_sda]
set_property PACKAGE_PIN B9 [get_ports hd_syzygy_sda]

#J2 (i2c addr=0x32)
set_property PACKAGE_PIN M22 [get_ports J2_RX_0_N]      ;   #GTR_LANE0_RX_N
set_property PACKAGE_PIN M21 [get_ports J2_RX_0_P]      ;   #GTR_LANE0_RX_P
set_property PACKAGE_PIN H22 [get_ports J2_RX_1_N]      ;   #GTR_LANE1_RX_N
set_property PACKAGE_PIN H21 [get_ports J2_RX_1_P]      ;   #GTR_LANE1_RX_P

set_property PACKAGE_PIN K22 [get_ports J2_TX_0_N]      ;   #GTR_LANE0_TX_N
set_property PACKAGE_PIN K21 [get_ports J2_TX_0_P]      ;   #GTR_LANE0_TX_P
set_property PACKAGE_PIN F22 [get_ports J2_TX_1_N]      ;   #GTR_LANE1_TX_N
set_property PACKAGE_PIN F21 [get_ports J2_TX_1_P]      ;   #GTR_LANE1_TX_P

##the S ports are in the MIO ports of the zynq
set_property PACKAGE_PIN W3 [get_ports J2_S0]           ;   #MIO13
set_property PACKAGE_PIN W5 [get_ports J2_S1]           ;   #MIO14
set_property PACKAGE_PIN Y4 [get_ports J2_S2]           ;   #MIO15
set_property PACKAGE_PIN AA3 [get_ports J2_S3]          ;   #MIO17
set_property PACKAGE_PIN Y3 [get_ports J2_S4]           ;   #MIO16
set_property PACKAGE_PIN Y5 [get_ports J2_S5]           ;   #MIO18
set_property PACKAGE_PIN AA4 [get_ports J2_S6]          ;   #MIO19
set_property PACKAGE_PIN W6 [get_ports J2_S7]          ;   #MIO21
set_property PACKAGE_PIN AB4 [get_ports J2_S8]          ;   #MIO20
set_property PACKAGE_PIN AA6 [get_ports J2_S9]          ;   #MIO22
set_property PACKAGE_PIN AB5 [get_ports J2_S10]         ;   #MIO23  
set_property PACKAGE_PIN D10 [get_ports J2_S11]         ;   #MIO36
set_property PACKAGE_PIN E10 [get_ports J2_S12]         ;   #MIO35
set_property PACKAGE_PIN E11 [get_ports J2_S13]         ;   #MIO37
set_property PACKAGE_PIN G11 [get_ports J2_S14]         ;   #MIO27
set_property PACKAGE_PIN F9 [get_ports J2_S15]          ;   #MIO29
set_property PACKAGE_PIN G12 [get_ports J2_S16]         ;   #MIO28
set_property PACKAGE_PIN G10 [get_ports J2_S17]         ;   #MIO30

set_property PACKAGE_PIN D5 [get_ports J2_P2C_CLK_P]    ;   #HD_DP_07_GC_P
set_property PACKAGE_PIN C5 [get_ports J2_P2C_CLK_N]    ;   #HD_DP_07_GC_N
set_property PACKAGE_PIN C8 [get_ports J2_C2P_CLK_P]    ;   #HD_DP_08_GC_P
set_property PACKAGE_PIN C7 [get_ports J2_C2P_CLK_N]    ;   #HD_DP_08_GC_N

set_property PACKAGE_PIN L20 [get_ports J2_REFCLK_N]    ;   #GTR_CLK0_N
set_property PACKAGE_PIN L19 [get_ports J2_REFCLK_P]    ;   #GTR_CLK0_P

#J1 (i2c addr=0x3B)
set_property PACKAGE_PIN D22 [get_ports J1_RX_0_N]   ;   #GTR_LANE2_RX_N
set_property PACKAGE_PIN D21 [get_ports J1_RX_0_P]   ;   #GTR_LANE2_RX_P

set_property PACKAGE_PIN B22 [get_ports J1_RX_1_N]   ;   #GTR_LANE3_RX_N
set_property PACKAGE_PIN B21 [get_ports J1_RX_1_P]   ;   #GTR_LANE3_RX_P

set_property PACKAGE_PIN C20 [get_ports J1_TX_0_N]   ;   #GTR_LANE2_TX_N
set_property PACKAGE_PIN C19 [get_ports J1_TX_0_P]   ;   #GTR_LANE2_TX_P

set_property PACKAGE_PIN A20 [get_ports J1_TX_1_N]   ;   #GTR_LANE3_TX_N
set_property PACKAGE_PIN A19 [get_ports J1_TX_1_P]   ;   #GTR_LANE3_TX_P

set_property PACKAGE_PIN T3 [get_ports J1_S0] ;  #HP_DP_01_DBC_P
set_property PACKAGE_PIN T2 [get_ports J1_S1] ;  #HP_DP_01_DBC_N
set_property PACKAGE_PIN P3 [get_ports J1_S2] ;  #HP_DP_02_P
set_property PACKAGE_PIN R3 [get_ports J1_S4] ;  #HP_DP_02_N
set_property PACKAGE_PIN R4 [get_ports J1_S6] ;  #HP_DP_04_P
set_property PACKAGE_PIN T4 [get_ports J1_S8] ;  #HP_DP_04_N
set_property PACKAGE_PIN P5 [get_ports J1_S10] ; #HP_DP_06_P
set_property PACKAGE_PIN R5 [get_ports J1_S12] ; #HP_DP_06_N
set_property PACKAGE_PIN K1 [get_ports J1_S14] ; #HP_DP_15_P
set_property PACKAGE_PIN J1 [get_ports J1_S16] ; #HP_DP_15_N

set_property PACKAGE_PIN U2 [get_ports J1_S3] ;  #HP_DP_03_P
set_property PACKAGE_PIN U1 [get_ports J1_S5] ;  #HP_DP_03_N
set_property PACKAGE_PIN R1 [get_ports J1_S7] ;  #HP_DP_05_P
set_property PACKAGE_PIN T1 [get_ports J1_S9] ;  #HP_DP_05_N
set_property PACKAGE_PIN K4 [get_ports J1_S11] ; #HP_DP_14_GC_p
set_property PACKAGE_PIN K3 [get_ports J1_S13] ; #HP_DP_14_GC_N
set_property PACKAGE_PIN D2 [get_ports J1_S15] ; #HP_DP_24_P
set_property PACKAGE_PIN C2 [get_ports J1_S17] ; #HP_DP_24_N


set_property PACKAGE_PIN A4 [get_ports J1_C2P_CLK_P] ;   #HP_SD_12_GC_66_P
set_property PACKAGE_PIN A3 [get_ports J1_C2P_CLK_N] ;   #HP_DO_12_GC_66_N

set_property PACKAGE_PIN B2 [get_ports J1_P2C_CLK_P] ;   #HP_DP_11_GC_66_P
set_property PACKAGE_PIN B1 [get_ports J1_P2C_CLK_N] ;   #HP_DP_11_GC_66_N

set_property PACKAGE_PIN J20 [get_ports J1_REFCLK_N]   ;   #GTR_CLK1_N
set_property PACKAGE_PIN J19 [get_ports J1_REFCLK_P]   ;   #GTR_CLK1_P


#J6 (i2c addr=0x3b)
set_property PACKAGE_PIN H2 [get_ports J6_S0_D0P] ;     #HP_DP_17_P
set_property PACKAGE_PIN G2 [get_ports J6_S2_D0N] ;     #HP_DP_17_N
set_property PACKAGE_PIN H4 [get_ports J6_S4_D2P] ;     #HP_DP_18_P
set_property PACKAGE_PIN G4 [get_ports J6_S6_D2N] ;     #HP_DP_18_N
set_property PACKAGE_PIN J5 [get_ports J6_S8_D4P] ;     #HP_DP_16_QBC_P
set_property PACKAGE_PIN H5 [get_ports J6_S10_D4N] ;    #HP_DP_16_QBC_N
set_property PACKAGE_PIN G1 [get_ports J6_S12_D6P] ;    #HP_DP_19_DBC_P
set_property PACKAGE_PIN F1 [get_ports J6_S14_D6N] ;    #HP_DP_19_DBC_N
set_property PACKAGE_PIN E4 [get_ports J6_S16] ;        #HP_DP_20_P
set_property PACKAGE_PIN E3 [get_ports J6_S18] ;        #HP_DP_20_N
set_property PACKAGE_PIN E1 [get_ports J6_S20] ;        #HP_DP_21_P
set_property PACKAGE_PIN D1 [get_ports J6_S22] ;        #HP_DP_21_N
set_property PACKAGE_PIN D3 [get_ports J6_S24] ;        #HP_DP_22_P
set_property PACKAGE_PIN C3 [get_ports J6_S26] ;        #HP_DP_22_N

set_property PACKAGE_PIN L4 [get_ports J6_P2C_CLK_P] ;  #HP_DP_12_GC_P
set_property PACKAGE_PIN L3 [get_ports J6_P2C_CLK_N] ;  #HP_DP_12_GC_N

set_property PACKAGE_PIN N2 [get_ports J6_S1_D1P] ;     #HP_DP_07_QBC_P
set_property PACKAGE_PIN P1 [get_ports J6_S3_D1N] ;     #HP_DP_07_QBC_N
set_property PACKAGE_PIN N5 [get_ports J6_S5_D3P] ;     #HP_DP_08_P
set_property PACKAGE_PIN N4 [get_ports J6_S7_D3N] ;     #HP_DP_08_N
set_property PACKAGE_PIN M2 [get_ports J6_S9_D5P] ;     #HP_DP_09_P
set_property PACKAGE_PIN M1 [get_ports J6_S11_D5N] ;    #HP_DP_09_N
set_property PACKAGE_PIN M5 [get_ports J6_S13_D7P] ;    #HP_DP_10_QBC_P
set_property PACKAGE_PIN M4 [get_ports J6_S15_D7N] ;    #HP_DP_10_QBC_N
set_property PACKAGE_PIN L2 [get_ports J6_S17] ;        #HP_DP_11_GC_P
set_property PACKAGE_PIN L1 [get_ports J6_S19] ;        #HP_DP_11_GC_N
set_property PACKAGE_PIN F3 [get_ports J6_S21] ;        #HP_DP_23_P
set_property PACKAGE_PIN F2 [get_ports J6_S23] ;         #HP_DP_23_N
set_property PACKAGE_PIN N3 [get_ports J6_S25] ;        #HP_SE_01
set_property PACKAGE_PIN H3 [get_ports J6_S27] ;        #HP_SE_02

set_property PACKAGE_PIN J3 [get_ports J6_C2P_CLK_P] ;  #HP_DP_13_GC_P
set_property PACKAGE_PIN J2 [get_ports J6_C2P_CLK_N] ;  #HP_DP_13_GC_N



#micro-e click  1.8V 
#the input of the microE click is 3.3 (you can place resistors to make it 5V), there is a voltage translator to 1.8
#The analog input of the microE is feed to an MCP3201T ADC that outputs the values to the SPI bus.

set_property PACKAGE_PIN G5 [get_ports CLICK_CS1_AN] ;   ##this one comes from one adc for the analog part of the microE (i belive...)
set_property PACKAGE_PIN G6 [get_ports CLICK_PWM]   ;
set_property PACKAGE_PIN E8 [get_ports CLICK_INT]   ;
set_property PACKAGE_PIN D7 [get_ports CLICK_RX]    ;
set_property PACKAGE_PIN D6 [get_ports CLICK_TX]    ;
set_property PACKAGE_PIN F8 [get_ports CLICK_SCL]   ;
set_property PACKAGE_PIN F7 [get_ports CLICK_SDA]   ;
set_property PACKAGE_PIN F6 [get_ports CLICK_SCK]   ;
set_property PACKAGE_PIN D8 [get_ports CLICK_RST]   ;
set_property PACKAGE_PIN G7 [get_ports CLICK_CS0]   ;
set_property PACKAGE_PIN E6 [get_ports CLICK_MISO]  ;
set_property PACKAGE_PIN E5 [get_ports CLICK_MOSI]  ;

set_property IOSTANDARD LVCMOS18 [get_ports CLICK_*]

###
###
###



#set the non-used pins
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

