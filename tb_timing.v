`timescale 1ns/1ps
module tb_timing;
  reg PI_CLK=0, PI_RD=0, PI_WR=0, M68K_CLK=0;
  reg [1:0] PI_A=0; reg [15:0] pi_drive=0; reg pi_oe=0;
  wire [15:0] PI_D = pi_oe ? pi_drive : 16'bz;
  wire PI_TXN_IN_PROGRESS,PI_IPL_ZERO,PI_RESET;
  wire LTCH_A_0,LTCH_A_8,LTCH_A_16,LTCH_A_24,LTCH_A_OE_n;
  wire LTCH_D_RD_U,LTCH_D_RD_L,LTCH_D_RD_OE_n,LTCH_D_WR_U,LTCH_D_WR_L,LTCH_D_WR_OE_n;
  wire [2:0] M68K_FC; wire M68K_AS_n,M68K_UDS_n,M68K_LDS_n,M68K_RW;
  reg M68K_DTACK_n=1, M68K_BERR_n=1, M68K_VPA_n=1; wire M68K_E,M68K_VMA_n;
  reg [2:0] M68K_IPL_n=7; tri M68K_RESET_n, M68K_HALT_n;
  reg M68K_BR_n=1; wire M68K_BG_n; reg M68K_BGACK_n=1;
  reg M68K_C1=0,M68K_C3=0,CLK_SEL=1;
  pistorm dut(.*);
  always #2.5 PI_CLK=~PI_CLK;
  // 7.8336 MHz M68000 clock: 127.65625 ns period.
  always #63.828125 M68K_CLK=~M68K_CLK;

  task pi_write(input [1:0] a,input [15:0] d);
    begin
      @(negedge PI_CLK); PI_A=a; pi_drive=d; pi_oe=1; PI_WR=1;
      repeat(4) @(posedge PI_CLK);
      @(negedge PI_CLK); PI_WR=0; pi_oe=0;
      repeat(4) @(posedge PI_CLK);
    end
  endtask

  integer e_rise_count=0; realtime last_e_rise=0; realtime e_period;
  always @(posedge M68K_E) begin
    if (e_rise_count>0) begin
      e_period=$realtime-last_e_rise;
      if (e_period < 1200.0 || e_period > 1400.0)
        $fatal(1,"E period out of expected 10*C7M range: %0t ns",e_period);
    end
    last_e_rise=$realtime; e_rise_count=e_rise_count+1;
  end

  reg saw_vma=0; reg saw_as=0;
  always @(negedge M68K_AS_n) saw_as=1;
  always @(negedge M68K_VMA_n) saw_vma=1;

  initial begin
    repeat(1000) @(posedge PI_CLK);
    if (e_rise_count < 3) $fatal(1,"E clock did not run");
    pi_write(2'd3,16'h0002); // release CPLD-driven reset
    pi_write(2'd1,16'h0000); // address low, A0=0
    M68K_VPA_n=0;            // emulate SE BBU VPA-space response
    pi_write(2'd2,16'h0000); // read, UDS/LDS selected; FC spare bits zero
    repeat(3000) @(posedge PI_CLK);
    M68K_VPA_n=1;
    if (!saw_as) $fatal(1,"No AS cycle generated");
    if (!saw_vma) $fatal(1,"No VMA generated for VPA cycle");
    $display("PASS: E clock period and VPA/VMA transaction ran; E rises=%0d",e_rise_count);
    $finish;
  end
endmodule
