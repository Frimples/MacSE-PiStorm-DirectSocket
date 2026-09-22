`timescale 1ns/1ps
module tb;
  reg PI_CLK=0, PI_RD=0, PI_WR=0, M68K_CLK=0;
  reg [1:0] PI_A=0; reg [15:0] PI_D_drive=0; reg PI_D_oe=0;
  wire [15:0] PI_D = PI_D_oe ? PI_D_drive : 16'bz;
  wire PI_TXN_IN_PROGRESS, PI_IPL_ZERO, PI_RESET;
  wire LTCH_A_0,LTCH_A_8,LTCH_A_16,LTCH_A_24,LTCH_A_OE_n;
  wire LTCH_D_RD_U,LTCH_D_RD_L,LTCH_D_RD_OE_n,LTCH_D_WR_U,LTCH_D_WR_L,LTCH_D_WR_OE_n;
  wire [2:0] M68K_FC; wire M68K_AS_n,M68K_UDS_n,M68K_LDS_n,M68K_RW;
  reg M68K_DTACK_n=1, M68K_BERR_n=1, M68K_VPA_n=1; wire M68K_E,M68K_VMA_n;
  reg [2:0] M68K_IPL_n=7; tri M68K_RESET_n, M68K_HALT_n;
  reg M68K_BR_n=1; wire M68K_BG_n; reg M68K_BGACK_n=1;
  reg M68K_C1=0,M68K_C3=0,CLK_SEL=1;
  pistorm dut(.*);
  always #2.5 PI_CLK = ~PI_CLK;
  always #70.5 M68K_CLK = ~M68K_CLK;
  initial begin
    repeat(100) @(posedge PI_CLK);
    M68K_BR_n=0;
    repeat(200) @(posedge PI_CLK);
    if (M68K_BG_n !== 1'b0) $fatal(1,"BG did not assert after BR");
    if (M68K_AS_n !== 1'bz || M68K_UDS_n !== 1'bz || M68K_LDS_n !== 1'bz ||
        M68K_RW !== 1'bz || M68K_VMA_n !== 1'bz || M68K_FC !== 3'bzzz)
      $fatal(1,"CPU control outputs were not tri-stated during BG");
    // External bus master acknowledges; BR must remain asserted until it leaves.
    M68K_BGACK_n=0;
    repeat(50) @(posedge PI_CLK);
    if (M68K_BG_n !== 1'b0) $fatal(1,"BG released while BGACK active");
    M68K_BR_n=1;
    repeat(50) @(posedge PI_CLK);
    if (M68K_BG_n !== 1'b0) $fatal(1,"BG released before BGACK");
    M68K_BGACK_n=1;
    repeat(50) @(posedge PI_CLK);
    if (M68K_BG_n !== 1'b1) $fatal(1,"BG did not release after handoff");
    $display("PASS: direct-socket BR/BG/BGACK arbitration");
    $finish;
  end
endmodule
