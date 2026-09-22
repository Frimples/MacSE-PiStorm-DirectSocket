# Validation status and test procedure

## Automated RTL validation

`run_tests.sh` compiles and runs the two Icarus testbenches with warnings enabled.

### Arbitration test

The arbitration test exercises:

```text
BR asserted
BG asserted
BGACK asserted
BR released
BGACK released
BG released
```

It also checks that the registered CPU control outputs become high impedance while external ownership is active.

### Timing test

The timing test exercises a Pi-side read path, E-clock activity, `/VPA` recognition, generated `/VMA`, and the expected relationship to the configured SE clock path.

These tests have passed on both the development host and Raspberry Pi. They are digital simulations only.

## Quartus validation

The EPM240 project was mapped, fitted, and assembled on Quartus Prime Lite 25.1. The final reports are retained under `release/epm240_build/`.

Quartus warnings retained for review:

1. `M68K_BERR_n` is unused by synthesized logic.
2. Derived clock `c7m_sync[2]` lacks a direct timing assignment.

Warnings are not silently converted into claims of timing closure.

## Required hardware validation

Before considering the firmware operational, use a scope or logic analyzer on the actual board and Macintosh SE. Capture at minimum:

- reset and halt;
- `M68K_CLK` and E-clock;
- `/AS`, `/UDS`, `/LDS`, and `R/W`;
- `/DTACK`, `/VPA`, and `/VMA`;
- `/BR`, `/BG`, and `/BGACK`;
- Pi-side latch and transceiver output-enable signals;
- address and data bus contention during ownership transitions.

Test first with current limiting and a recovery image available. Start with reset and bus ownership observation before allowing normal ROM/peripheral traffic.

## Not yet proven

- Physical boot of an SE.
- VIA and SCC register access on a real motherboard.
- All interrupt-acknowledge cases.
- Bus-error behavior.
- Electrical break-before-make timing.
- Metastability margins for the actual asynchronous inputs.
- Compatibility with every direct-socket board revision.
