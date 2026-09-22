/*
 * Copyright 2020 Claude Schwarz
 * Copyright 2020 Niklas Ekström - rewrite in Verilog
 */
module pistorm(
    output reg      PI_TXN_IN_PROGRESS, // GPIO0
    output reg      PI_IPL_ZERO,        // GPIO1
    input   [1:0]   PI_A,       // GPIO[3..2]
    input           PI_CLK,     // GPIO4
    output reg      PI_RESET,   // GPIO5
    input           PI_RD,      // GPIO6
    input           PI_WR,      // GPIO7
    inout   [15:0]  PI_D,       // GPIO[23..8]

    output reg      LTCH_A_0,
    output reg      LTCH_A_8,
    output reg      LTCH_A_16,
    output reg      LTCH_A_24,
    output reg      LTCH_A_OE_n,
    output reg      LTCH_D_RD_U,
    output reg      LTCH_D_RD_L,
    output reg      LTCH_D_RD_OE_n,
    output reg      LTCH_D_WR_U,
    output reg      LTCH_D_WR_L,
    output reg      LTCH_D_WR_OE_n,

    input           M68K_CLK,
    inout       [2:0] M68K_FC,

    inout           M68K_AS_n,
    inout           M68K_UDS_n,
    inout           M68K_LDS_n,
    inout           M68K_RW,

    input           M68K_DTACK_n,
    input           M68K_BERR_n,

    input           M68K_VPA_n,
    output reg      M68K_E,
    inout           M68K_VMA_n,

    input   [2:0]   M68K_IPL_n,

    inout           M68K_RESET_n,
    inout           M68K_HALT_n,

    input           M68K_BR_n,
    output reg      M68K_BG_n,
    input           M68K_BGACK_n,
    input           M68K_C1,
    input           M68K_C3,
    input           CLK_SEL
  );

  reg [2:0] M68K_FC_r;
  reg M68K_AS_n_r, M68K_UDS_n_r, M68K_LDS_n_r, M68K_RW_r, M68K_VMA_n_r;

  wire c200m = PI_CLK;
  reg [2:0] c7m_sync = 3'd0;
  wire c1c3_clk = !(M68K_C1 ^ M68K_C3);

  localparam REG_DATA = 2'd0;
  localparam REG_ADDR_LO = 2'd1;
  localparam REG_ADDR_HI = 2'd2;
  localparam REG_STATUS = 2'd3;

  initial begin
    PI_TXN_IN_PROGRESS <= 1'b0;
    PI_IPL_ZERO <= 1'b0;

    PI_RESET <= 1'b0;

    M68K_FC_r <= 3'd0;
    M68K_AS_n_r <= 1'b1;
    M68K_UDS_n_r <= 1'b1;
    M68K_LDS_n_r <= 1'b1;
    M68K_RW_r <= 1'b1;

    M68K_E <= 1'b0;
    M68K_VMA_n_r <= 1'b1;

    M68K_BG_n <= 1'b1;

    LTCH_A_0 <= 1'b0;
    LTCH_A_8 <= 1'b0;
    LTCH_A_16 <= 1'b0;
    LTCH_A_24 <= 1'b0;
    LTCH_A_OE_n <= 1'b1;
    LTCH_D_RD_U <= 1'b0;
    LTCH_D_RD_L <= 1'b0;
    LTCH_D_RD_OE_n <= 1'b1;
    LTCH_D_WR_U <= 1'b0;
    LTCH_D_WR_L <= 1'b0;
    LTCH_D_WR_OE_n <= 1'b1;
  end

  reg [1:0] rd_sync = 2'd0;
  reg [1:0] wr_sync = 2'd0;

  always @(posedge c200m) begin
    rd_sync <= {rd_sync[0], PI_RD};
    wr_sync <= {wr_sync[0], PI_WR};
  end

  wire rd_rising = !rd_sync[1] && rd_sync[0];
  wire wr_rising = !wr_sync[1] && wr_sync[0];

  reg [15:0] data_out;
  assign PI_D = PI_A == REG_STATUS && PI_RD ? data_out : 16'bz;

  always @(posedge c200m) begin
    if (rd_rising && PI_A == REG_STATUS) begin
      data_out <= {ipl, 13'd0};
    end
  end

  // Power-up must hold the SE CPU in reset until the Pi explicitly releases it.
  reg [15:0] status = 16'h0000;
  wire reset_out = !status[1];
  wire external_reset_active = !reset_out && !M68K_RESET_n;
  wire external_halt_active = !reset_out && !M68K_HALT_n;

  assign M68K_RESET_n = reset_out ? 1'b0 : 1'bz;
  assign M68K_HALT_n = reset_out ? 1'b0 : 1'bz;

  reg op_req = 1'b0;
  reg op_rw = 1'b1;
  reg op_uds_n = 1'b1;
  reg op_lds_n = 1'b1;
  wire pi_latch_active = !bus_grant && !reset_out &&
                          !external_reset_active && !external_halt_active;

  always @(*) begin
    LTCH_D_WR_U <= pi_latch_active && PI_A == REG_DATA && PI_WR;
    LTCH_D_WR_L <= pi_latch_active && PI_A == REG_DATA && PI_WR;

    LTCH_A_0 <= pi_latch_active && PI_A == REG_ADDR_LO && PI_WR;
    LTCH_A_8 <= pi_latch_active && PI_A == REG_ADDR_LO && PI_WR;

    LTCH_A_16 <= pi_latch_active && PI_A == REG_ADDR_HI && PI_WR;
    LTCH_A_24 <= pi_latch_active && PI_A == REG_ADDR_HI && PI_WR;

    LTCH_D_RD_OE_n <= !pi_latch_active || !(PI_A == REG_DATA && PI_RD);
  end

  reg a0 = 1'b0;

  always @(posedge c200m) begin
    c7m_sync <= {c7m_sync[1:0], (CLK_SEL?M68K_CLK:c1c3_clk)};
  end

  wire c7m_rising = !c7m_sync[2] && c7m_sync[1];
  wire c7m_falling = c7m_sync[2] && !c7m_sync[1];

  reg [2:0] ipl = 3'd0;
  reg [2:0] ipl_1 = 3'd0;
  reg [2:0] ipl_2 = 3'd0;

  always @(posedge c200m) begin
    if (c7m_falling) begin
      ipl_1 <= ~M68K_IPL_n;
      ipl_2 <= ipl_1;
    end

    if (ipl_2 == ipl_1)
      ipl <= ipl_2;

    PI_IPL_ZERO <= ipl == 3'd0;
  end

  always @(posedge c200m) begin
    PI_RESET <= reset_out ? 1'b1 : M68K_RESET_n;
  end

  reg [3:0] e_counter = 4'd0;

  // Keep all state in the PI_CLK domain.  c7m_sync is an edge detector,
  // not a derived clock; this avoids using an unconstrained fabric clock.
  always @(posedge c200m) begin
    if (external_reset_active || external_halt_active) begin
      e_counter <= 4'd0;
      M68K_E <= 1'b0;
    end
    else if (c7m_falling) begin
      if (e_counter == 4'd9) begin
        e_counter <= 4'd0;
        M68K_E <= 1'b0;
      end
      else begin
        e_counter <= e_counter + 4'd1;
        if (e_counter == 4'd5)
          M68K_E <= 1'b1;
      end
    end
  end

  reg [2:0] state = 3'd0;
  reg [2:0] PI_TXN_IN_PROGRESS_delay = 3'd0;
  reg vpa_pending = 1'b0;

  // /BR and /BGACK are asynchronous to PI_CLK.  Synchronize them before the
  // arbitration state machine uses them.
  reg [1:0] br_sync = 2'b11;
  reg [1:0] bgack_sync = 2'b11;
  reg [1:0] dtack_sync = 2'b11;
  reg [1:0] berr_sync = 2'b11;
  reg [1:0] vpa_sync = 2'b11;
  always @(posedge c200m) begin
    br_sync <= {br_sync[0], M68K_BR_n};
    bgack_sync <= {bgack_sync[0], M68K_BGACK_n};
    dtack_sync <= {dtack_sync[0], M68K_DTACK_n};
    berr_sync <= {berr_sync[0], M68K_BERR_n};
    vpa_sync <= {vpa_sync[0], M68K_VPA_n};
  end

  // Direct CPU-socket arbitration.  The SE motherboard may request the
  // processor bus for DMA/peripheral work.  The emulated CPU must grant it
  // only between cycles, then keep all bus-driver enables inactive until the
  // motherboard releases BGACK.  This is separate from the PDS takeover
  // design; here the PiStorm is the CPU and M68K_BR_n is an input.
  reg bus_grant = 1'b0;
  reg bus_ack_seen = 1'b0;

  // A granted external bus master must see the CPU-side control outputs
  // released, not driven inactive.  This models the 68000 three-state bus.
  assign M68K_FC = bus_grant ? 3'bz : M68K_FC_r;
  assign M68K_AS_n = bus_grant ? 1'bz : M68K_AS_n_r;
  assign M68K_UDS_n = bus_grant ? 1'bz : M68K_UDS_n_r;
  assign M68K_LDS_n = bus_grant ? 1'bz : M68K_LDS_n_r;
  assign M68K_RW = bus_grant ? 1'bz : M68K_RW_r;
  assign M68K_VMA_n = bus_grant ? 1'bz : M68K_VMA_n_r;

  always @(posedge c200m) begin
    if (external_reset_active || external_halt_active) begin
      bus_grant <= 1'b0;
      bus_ack_seen <= 1'b0;
      M68K_BG_n <= 1'b1;
      state <= 3'd0;
      op_req <= 1'b0;
      vpa_pending <= 1'b0;
      PI_TXN_IN_PROGRESS <= 1'b0;
      PI_TXN_IN_PROGRESS_delay <= 3'd0;
      LTCH_A_OE_n <= 1'b1;
      LTCH_D_RD_U <= 1'b0;
      LTCH_D_RD_L <= 1'b0;
      LTCH_D_WR_OE_n <= 1'b1;
      M68K_FC_r <= 3'd0;
      M68K_AS_n_r <= 1'b1;
      M68K_UDS_n_r <= 1'b1;
      M68K_LDS_n_r <= 1'b1;
      M68K_RW_r <= 1'b1;
      M68K_VMA_n_r <= 1'b1;
    end
    else begin
    // Three-wire 68000 arbitration, synchronized in the CPLD clock domain.
    // /BG is active low.  Do not grant during an active Pi transaction.
    if (!bus_grant && !br_sync[1] &&
        ((state == 3'd0) || (state == 3'd1 && !op_req))) begin
      bus_grant <= 1'b1;
      bus_ack_seen <= 1'b0;
      M68K_BG_n <= 1'b0;
      state <= 3'd0;
      LTCH_A_OE_n <= 1'b1;
      LTCH_D_WR_OE_n <= 1'b1;
      M68K_AS_n_r <= 1'b1;
      M68K_UDS_n_r <= 1'b1;
      M68K_LDS_n_r <= 1'b1;
      M68K_VMA_n_r <= 1'b1;
      PI_TXN_IN_PROGRESS <= 1'b0;
    end
    else if (bus_grant && !bgack_sync[1]) begin
      bus_ack_seen <= 1'b1;
    end
    else if (bus_grant && bus_ack_seen && bgack_sync[1]) begin
      bus_grant <= 1'b0;
      M68K_BG_n <= 1'b1;
    end

    if (wr_rising) begin
      case (PI_A)
        REG_ADDR_LO: begin
          a0 <= PI_D[0];
          PI_TXN_IN_PROGRESS <= 1'b1;
        end
        REG_ADDR_HI: begin
          op_req <= 1'b1;
          op_rw <= PI_D[9];
          op_uds_n <= PI_D[8] ? a0 : 1'b0;
          op_lds_n <= PI_D[8] ? !a0 : 1'b0;
        end
        REG_STATUS: begin
          status <= PI_D;
        end
      endcase
    end

    if (!bus_grant) begin
      case (state)
      3'd0: begin // S0
        M68K_RW_r <= 1'b1; // S7 -> S0
//        if (c7m_falling) begin
//          if (op_req) begin
            state <= 2'd1;
//          end
//        end
      end

      3'd1: begin // S1
        if (op_req) begin
          if(c7m_rising) begin
            state <= 3'd2;
          end
        end
      end
      3'd2: begin // S2
        // The current Pi-side register protocol carries the upper address
        // byte in PI_D[15:8]; PI_D[12:10] are therefore address bits, not
        // 68000 function-code bits.  Keep the proven standard behavior until
        // the software protocol explicitly transports FC2..FC0.
        M68K_FC_r <= 3'd0;
        M68K_RW_r <= op_rw; // S1 -> S2
        vpa_pending <= 1'b0;
        LTCH_D_WR_OE_n <= op_rw;
        LTCH_A_OE_n <= 1'b0;
        M68K_AS_n_r <= 1'b0;
        M68K_UDS_n_r <= op_rw ? op_uds_n : 1'b1;
        M68K_LDS_n_r <= op_rw ? op_lds_n : 1'b1;
        if (c7m_falling) begin
          M68K_UDS_n_r <= op_uds_n;
          M68K_LDS_n_r <= op_lds_n;
          state <= 3'd3;
        end
      end

      3'd3: begin // S3
        op_req <= 1'b0;
        if(c7m_falling) begin
          if (!M68K_DTACK_n || !dtack_sync[1] ||
              !M68K_BERR_n || !berr_sync[1] ||
              (!M68K_VMA_n && e_counter == 4'd8)) begin
            state <= 3'd4;
            PI_TXN_IN_PROGRESS_delay[2:0] <= 3'b111;
          end
          else if (!vpa_sync[1]) begin
            // The SE's M6800 peripherals require VMA at the established
            // E-clock phase, not merely at an arbitrary time while E is low.
            // Preserve the proven PiStorm phase relationship while sampling
            // VPA on the required falling-edge response phase.
            if (!M68K_E && e_counter == 4'd2)
              M68K_VMA_n_r <= 1'b0;
            else
              vpa_pending <= 1'b1;
          end
        end
        if (vpa_pending && !vpa_sync[1] && !M68K_E && e_counter == 4'd2 &&
            dtack_sync[1] && berr_sync[1]) begin
          M68K_VMA_n_r <= 1'b0;
          vpa_pending <= 1'b0;
        end
      end
      3'd4: begin // S4
        PI_TXN_IN_PROGRESS_delay <= {PI_TXN_IN_PROGRESS_delay[1:0],1'b0};
        PI_TXN_IN_PROGRESS <= PI_TXN_IN_PROGRESS_delay[2];
        LTCH_D_RD_U <= 1'b1;
        LTCH_D_RD_L <= 1'b1;
        if (c7m_falling) begin
          state <= 3'd5;
          PI_TXN_IN_PROGRESS <= 1'b0;
        end
      end

      3'd5: begin // S5
        LTCH_D_RD_U <= 1'b0;
        LTCH_D_RD_L <= 1'b0;
        if (c7m_rising) begin
          state <= 3'd6;
        end
      end
       
      3'd6: begin // S6
        if (c7m_falling) begin
          M68K_VMA_n_r <= 1'b1;
          state <= 3'd7;
        end
      end
       
      3'd7: begin // S7
        LTCH_D_WR_OE_n <= 1'b1;
        LTCH_A_OE_n <= 1'b1;
        M68K_AS_n_r <= 1'b1;
        M68K_UDS_n_r <= 1'b1;
        M68K_LDS_n_r <= 1'b1;
//        if(c7m_rising) begin
//          M68K_RW_r <= 1'b1; // S7 -> S0
          state <= 3'd0;
//        end
      end
    endcase
    end
    end
  end

endmodule
