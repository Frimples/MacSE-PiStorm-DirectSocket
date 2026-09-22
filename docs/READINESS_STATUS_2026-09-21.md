# Current readiness after RTL correction — 2026-09-21

## Result

The review findings were addressed in the RTL where they were implementable without inventing board-specific behavior:

- All latch/transceiver control outputs now have safe initialized states.
- PI-side latch/read controls are inhibited while CPLD reset, external reset/halt, or external bus ownership is active.
- `/BERR`, `/DTACK`, and `/VPA` are sampled through synchronizer registers; `/BERR` completes the transaction path instead of being ignored.
- External reset/halt recovery clears transaction state, arbitration state, strobes, E-clock state, and output enables.
- The generated `c7m_sync[2]` fabric clock was removed. E-clock and transaction timing now remain in the `PI_CLK` domain using synchronized edge detection.
- The SDC no longer blanket-false-paths all external inputs and outputs. False paths are limited to first-stage asynchronous synchronizer crossings.

## Verification

The revised `run_tests.sh` passes:

- BR/BG/BGACK arbitration and CPU-control tri-state test.
- E-clock and `/VPA`/`/VMA` timing test.
- Safe power-up/output-enable test.
- `/BERR` transaction completion test.
- External reset recovery test.

The revised Quartus build passes map, fit, assembly, and explicit POF-to-SVF conversion for `EPM240T100C5`. The previous design-functional warnings are gone; Quartus reports only the Lite-edition LogicLock license notice.

The revised artifact hashes are recorded in the release directory and must replace the superseded SVF/POF pair.

## Still not a hardware-test approval

The following remain unverified and are independent of the corrected RTL:

1. The reconstructed logical-to-physical pin map is still provisional because the Gerbers contain no schematic/netlist/logical names and the supplied BOM conflicts with live JTAG identification.
2. Actual latch/transceiver polarity, power-up behavior, and break-before-make behavior on the populated board are not measured.
3. Real Macintosh SE waveforms are absent. VIA, SCC, interrupt acknowledge, reset, halt, DTACK, VPA, VMA, E-clock phase, and bus arbitration have not been captured on the motherboard.
4. The revised CDC structure is more explicit, but asynchronous input timing and board-level voltage/edge-rate margins still require measurement.
5. The revised tests cover modeled fault cases, not all 68000 protocol corner cases or every SE board revision.

Therefore the status is:

```text
RTL correction:       complete
Simulation:           passing
EPM240 build:         passing
New SVF:              generated
Pin-map proof:        incomplete
Physical validation:  not performed
Normal SE bus test:   still NO-GO
```
