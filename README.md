# Macintosh SE direct CPU-socket CPLD branch

This branch is for the PiStorm connected directly to the Macintosh SE 68000 CPU
socket. It is **not** the PDS-card project.

## Changes made

- Added direct 68000 three-wire bus arbitration:
  - motherboard `/BR` is sampled;
  - CPLD asserts `/BG` only between Pi bus cycles;
  - address/data output enables are forced inactive while the motherboard owns
    the bus;
  - `/BG` remains asserted until the motherboard acknowledges and releases the
    bus.
- Synchronizes asynchronous `/BR` and `/BGACK` inputs before arbitration.
- Releases the CPU control outputs (`FC`, `/AS`, `/UDS`, `/LDS`, `R/W`, `/VMA`)
  to high impedance during an external bus grant.
- Initializes reset, interrupt, synchronizer, and transaction state
  deterministically at power-up.
- Added optional FC2..FC0 transport in `PI_D[12:10]` during `REG_ADDR_HI`.
  Existing callers that leave those spare bits zero remain protocol-compatible.
- Preserved the existing E-clock, VPA/VMA, DTACK, interrupt, and latch timing
  paths used by SE peripheral accesses.

## Verification

`iverilog` syntax compilation passed.
`tb_arbitration.v` passed the simulated sequence:

```text
BR asserted -> BG asserted -> BGACK asserted -> BR released -> BGACK released -> BG released
```

## SVF status

No new SVF is included yet. The source must be compiled with Intel Quartus for the
exact CPLD part and pin assignment. The repository's `.qsf` targets EPM570T100C5,
while the supplied `EPM240_*.svf` files target EPM240; using an SVF for the wrong
part or pin map is unsafe.

Before programming hardware, the direct PiStorm board's CPLD device/package and
pin map must be confirmed, then the source must be compiled in Quartus and the
resulting SVF checked against that exact device.
