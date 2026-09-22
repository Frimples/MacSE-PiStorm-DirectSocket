# Hardware-readiness audit — 2026-09-21 (pre-correction)

> This document records the blockers found in the pre-correction revision. The current RTL includes targeted fixes for initialized enables, `/BERR`, reset recovery, synchronizer sampling, and the derived-clock structure. The remaining hardware-readiness limitations still apply unless explicitly marked verified in newer documentation.

## Decision

**NO-GO for connecting this programmed CPLD to a powered Macintosh SE and allowing normal bus traffic.**

The firmware is a successfully synthesized research artifact, not yet a safe hardware-test image. The two Icarus tests cover only idealized digital sequences. They do not prove power-up output states, board net mapping, 68000 bus timing, metastability margins, or electrical break-before-make behavior.

Programming the isolated CPLD through a separately verified JTAG chain may be reasonable as a device/programming exercise, but that is not the same as installing it in the SE bus. Initial powered testing must not proceed until the blockers below are resolved or explicitly isolated with hardware instrumentation and current limiting.

## Critical blockers

### 1. External driver enables are not initialized comprehensively

`pistorm.v` initializes CPU-control registers but does not initialize all latch/transceiver control outputs in the `initial` block. `LTCH_A_OE_n`, `LTCH_D_WR_OE_n`, `LTCH_D_RD_U`, `LTCH_D_RD_L`, `LTCH_D_WR_U`, and `LTCH_D_WR_L` receive conditional assignments later in the design.

The current arbitration test checks `FC`, `/AS`, `/UDS`, `/LDS`, `R/W`, and `/VMA`, but does not check latch/transceiver enables during:

- CPLD configuration;
- power-up/reset;
- grant assertion;
- `/BGACK` handoff;
- grant release.

The fitter report does not establish the external circuitry's safe power-up polarity or break-before-make behavior.

### 2. `/BERR` is completely unused

`M68K_BERR_n` is declared but never referenced. Quartus confirms:

```text
No output dependent on input pin "M68K_BERR_n"
```

A bus-error cycle with no `/DTACK` can leave state S3 active indefinitely with `/AS` and data strobes asserted. This must be designed and tested before hardware traffic is allowed.

### 3. The generated `c7m_sync[2]` clock is not timing-constrained

The RTL uses `c7m_sync[2]` as a clock for E-clock generation and transaction logic. Quartus promotes it to a global clock but reports:

```text
Node: c7m_sync[2] was determined to be a clock but was found without an associated clock assignment.
```

The SDC defines clocks for `PI_CLK`, `M68K_CLK`, `M68K_C1`, and `M68K_C3`, but no generated clock for `c7m_sync[2]`. Fitter success is not timing closure.

### 4. The SDC suppresses rather than proves key CDC paths

The SDC applies broad false paths from asynchronous motherboard inputs, to most external outputs, and between `PI_CLK` and `M68K_CLK`. Meanwhile, the RTL directly samples `/DTACK` and `/VPA` in the `PI_CLK`-domain state machine and combines `C1`/`C3` before synchronization.

This prevents the timing report from proving the paths that determine real bus safety. The design needs an intentional CDC/timing strategy, not merely broad false paths.

### 5. Arbitration coverage is incomplete

The testbench proves one idealized `/BR` → `/BG` → `/BGACK` sequence and CPU-control tri-state behavior. It does not prove:

- grant timing relative to the final `/AS` inactive interval;
- address-latch output disable timing;
- data-transceiver output disable timing for both directions;
- read-enable behavior;
- reset during a grant or active cycle;
- a request arriving at every state/phase boundary;
- ownership release and reacquisition under real motherboard timing.

### 6. The pin map remains provisional

The EPM240 device identity was verified by JTAG, but the logical-to-physical board map was reconstructed from QSF assignments and Gerber geometry. The Gerbers contain no logical net names, schematic, or netlist, and the supplied BOM conflicts by naming U4 as `EPM570T100C5`.

A valid EPM240 POF/SVF for the wrong board net mapping can drive clocks, reset, arbitration, or bus strobes onto incorrect nets. The candidate map must be checked against the exact populated board revision before programming.

## Additional blockers

- External `/RESET` and `/HALT` do not reset the internal transaction/arbitration state. They are only driven low while the software-controlled `status[1]` reset is active, and `/RESET` is sampled for `PI_RESET`.
- Reset release is software-controlled; output-safe sequencing before the status write is not proven.
- `/DTACK` and `/VPA` are level-sampled without a timeout, synchronizer, or explicit conflict handling.
- E-clock frequency is tested, but its phase and width relative to real `/AS`, `/VPA`, `/VMA`, VIA, and SCC timing are not measured.
- Interrupt acknowledge, bus error, halt, reset, missing-response, and mixed `/VPA`/`/DTACK` cases are not covered.

## What is verified

- Icarus warning-enabled compilation succeeds.
- Arbitration test passes for its modeled sequence.
- Timing test passes for its modeled E-clock and one `/VPA` transaction.
- Quartus map, fit, and assembly succeed for `EPM240T100C5`.
- Fitter reports 97/240 logic elements and 59/80 user pins used.
- POF and SVF were generated from the actual RTL/QSF rather than edited by hand.
- SVF identifies EPM240 and uses a 10-bit instruction register.

These results establish a buildable artifact, not hardware readiness.

## Required gates before a real SE bus test

1. Resolve the exact populated-board net map with schematic/netlist or continuity tracing for every clock, reset, bus, latch, transceiver, and arbitration net.
2. Define and initialize every external output-enable and direction control to a safe state.
3. Add explicit reset handling for transaction and arbitration state, including reset during an active cycle/grant.
4. Define `/BERR` behavior, timeout behavior, and interrupt-acknowledge behavior.
5. Replace or justify the derived-clock/CDC structure and produce a meaningful timing report with generated clocks and deliberate asynchronous-input constraints.
6. Extend simulation with negative/fault cases: BERR, missing DTACK, reset/halt mid-cycle, VPA/DTACK overlap, BR at every state, and all latch/transceiver enables.
7. Capture real board waveforms using the known-good firmware or passive observation before installing the candidate image.
8. Preserve the known-good EPM240 SVF and use current-limited, observable power-up testing.

Until these gates pass, the correct status is **build complete, hardware validation blocked**.
