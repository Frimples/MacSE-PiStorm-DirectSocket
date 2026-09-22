`timescale 1ns/1ps
module tb_safety;
  reg PI_CLK=0, PI_RD=0, PI_WR=0, M68K_CLK=0;
  reg [1:0] PI_A=0; reg [15:0] pi_drive=0; reg pi_oe=0;
  wire [15:0] PI_D = pi_oe ? pi_drive : 16'bz;
  wire PI_TXN_IN_PROGRESS, PI_IPL_ZERO, PI_RESET;
  wire LTCH_A_0,LTCH_A_8,LTCH_A_16,LTCH_A_24,LTCH_A_OE_n;
  wire LTCH_D_RD_U,LTCH_D_RD_L,LTCH_D_RD_OE_n,LTCH_D_WR_U,LTCH_D_WR_L,LTCH_D_WR_OE_n;
  wire [2:0] M68K_FC; wire M68K_AS_n,M68K_UDS_n,M68K_LDS_n,M68K_RW;
  reg M68K_DTACK_n=1, M68K_BERR_n=1, M68K_VPA_n=1; wire M68K_E,M68K_VMA_n;
  reg [2:0] M68K_IPL_n=7; tri M68K_RESET_n, M68K_HALT_n;
  reg external_reset=1, external_halt=1;
  assign M68K_RESET_n = external_reset ? 1'bz : 1'b0;
  assign M68K_HALT_n  = external_halt  ? 1'bz : 1'b0;
  reg M68K_BR_n=1; wire M68K_BG_n; reg M68K_BGACK_n=1;
  reg M68K_C1=0,M68K_C3=0,CLK_SEL=1;
  pistorm dut(.*);
  always #2.5 PI_CLK = ~PI_CLK;
  always #63.828125 M68K_CLK = ~M68K_CLK;

  task pi_write(input [1:0] a,input [15:0] d);
    begin
      @(negedge PI_CLK); PI_A=a; pi_drive=d; pi_oe=1; PI_WR=1;
      repeat(4) @(posedge PI_CLK);
      @(negedge PI_CLK); PI_WR=0; pi_oe=0;
      repeat(4) @(posedge PI_CLK);
    end
  endtask

  task check_safe_outputs;
    begin
      if (LTCH_A_OE_n !== 1'b1) $fatal(1,"address output enable is not safe");
      if (LTCH_D_WR_OE_n !== 1'b1) $fatal(1,"write data output enable is not safe");
      if (LTCH_D_RD_OE_n !== 1'b1) $fatal(1,"read data output enable is not safe");
      if (LTCH_D_WR_U !== 1'b0 || LTCH_D_WR_L !== 1'b0)
        $fatal(1,"write data strobes are not safe");
      if (LTCH_A_0 !== 1'b0 || LTCH_A_8 !== 1'b0 ||
          LTCH_A_16 !== 1'b0 || LTCH_A_24 !== 1'b0)
        $fatal(1,"address latch strobes are not safe");
      if (LTCH_D_RD_U !== 1'b0 || LTCH_D_RD_L !== 1'b0)
        $fatal(1,"read data strobes are not safe");
      if (M68K_AS_n !== 1'b1 || M68K_UDS_n !== 1'b1 || M68K_LDS_n !== 1'b1 ||
          M68K_VMA_n !== 1'b1)
        $fatal(1,"68000 strobes are not inactive");
    end
  endtask

  initial begin
    repeat(20) @(posedge PI_CLK);
    check_safe_outputs();
    PI_A=2'd1; pi_drive=16'h0000; pi_oe=1; PI_WR=1;
    repeat(4) @(posedge PI_CLK);
    check_safe_outputs();
    PI_WR=0; pi_oe=0;

    pi_write(2'd3,16'h0002); // release CPLD-controlled reset/halt
    pi_write(2'd1,16'h0000); // A0=0
    pi_write(2'd2,16'h0000); // read transaction
    M68K_BERR_n=0;           // terminate it with bus error, not DTACK
    repeat(600) @(posedge PI_CLK);
    M68K_BERR_n=1;
    if (M68K_AS_n !== 1'b1) $fatal(1,"BERR did not terminate the bus cycle");
    check_safe_outputs();

    // Reset while idle and verify the state/output safety contract again.
    external_reset=0;
    repeat(20) @(posedge PI_CLK);
    check_safe_outputs();
    if (M68K_BG_n !== 1'b1) $fatal(1,"BG not inactive during external reset");
    external_reset=1;
    $display("PASS: safe enables, BERR completion, and external reset recovery");
    $finish;
  end
endmodule
