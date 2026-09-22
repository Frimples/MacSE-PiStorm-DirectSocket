# Hardware test log

## 2026-09-21 — first isolated firmware installation

**Source:** user-observed result on the physical Macintosh SE/PiStorm system.

The corrected EPM240 firmware was programmed and the Macintosh SE booted. The system remained operational without crashing. Some screen artifacts were visible during/after boot.

Observed result:

```text
CPLD programming: successful
SE boot:          successful
System stability: no crash observed
Display:          artifacts present
Native SCSI:      still not working
```

This is the first real hardware evidence that the generated EPM240 image is electrically compatible enough to reach boot on the tested setup. It does not prove all bus timing or peripheral paths.

## Interpretation boundaries

- The boot result makes the candidate pin map substantially more credible, but does not prove every net assignment or every board revision.
- Screen artifacts are an unresolved display/bus-timing symptom. Do not attribute them to one cause without captures.
- Native SCSI remains a separate unimplemented/unverified path; it should not be used as evidence that the CPLD programming failed.
- No claim is made yet for long-run stability, VIA/SCC correctness, interrupt timing, arbitration under DMA, or write reliability.

## Next evidence to collect

1. Record whether artifacts occur during boot only or persist at the Finder desktop.
2. Record whether artifacts change with CPU speed, reset, disk activity, or screen updates.
3. Capture `M68K_CLK`, E-clock, `/AS`, `/UDS`, `/LDS`, `R/W`, `/DTACK`, `/VPA`, `/VMA`, and the latch/transceiver enables while artifacts occur.
4. Test repeated reset and cold power cycles.
5. Test VIA/SCC accesses independently of SCSI.
6. Keep native SCSI disabled from the CPLD verdict: it requires a separate software/device-emulation implementation and is not a native consequence of this gateware.

## Follow-up observation — persistent video and audio artifacts

The artifacts remain after boot and audio artifacts are also present. Because the SE's video and sound DMA share the motherboard memory system, simultaneous video and audio corruption points first to a shared bus timing, RAM-write, E-clock, or bus-contention issue. This is a working hypothesis, not a confirmed root cause.

Priority isolation sequence:

1. Run the SE with audio activity minimized and compare screen corruption; then run a display-stable screen with audio activity. Record whether either symptom changes independently.
2. Compare cold boot and reset-only recovery, and record whether the artifact pattern is fixed, moving, or correlated with screen updates.
3. Capture `M68K_CLK`, generated E-clock, `/AS`, `/UDS`, `/LDS`, `R/W`, `/DTACK`, `/VPA`, `/VMA`, address/data latch enables, and data-transceiver enables on the same time base.
4. Check whether CPU writes are reaching motherboard RAM with correct width and strobe timing; video/audio DMA must continue seeing coherent RAM contents.
5. Do not change E-clock divisors, latch polarity, or bus timing together. Test one controlled firmware variant at a time and preserve the currently booting image for rollback.

## Follow-up observation — SCSI Probe reports missing termination

SCSI Probe reports that the SCSI bus is not terminated. This is a separate physical-bus issue from the CPLD firmware and from the video/audio artifacts. The CPU-socket PiStorm does not provide SCSI termination.

Before judging native SCSI emulation, power the SE down and verify the physical topology:

- exactly one terminator at each physical end of the SCSI bus;
- the internal hard disk, if present, has termination enabled only when it is at the physical end;
- an external device chain has a terminator on its last device;
- no middle device has termination enabled;
- termination power is present and the terminator type matches the bus/device requirements.

After correcting the topology, rerun SCSI Probe with the normal SCSI devices connected. A termination warning can prevent reliable device selection and should be resolved before diagnosing higher-level native SCSI behavior. It does not explain the simultaneous video/audio artifacts.

## Timing audit — MC68000 comparison

The Motorola/Freescale *M68000 8-/16-/32-bit Microprocessors User's Manual* states that a bus cycle has eight states, that S4 waits for `DTACK`/`BERR`/`VPA`, and that `VPA` and `BERR` are sampled on every **falling** clock edge beginning with S4. The current RTL's state-3 termination block at `pistorm.v` checks synchronized `DTACK`, `BERR`, and `VPA` only when `c7m_rising` is true. That is a concrete phase mismatch to correct and test; it is not a speculative diagnosis.

The same manual specifies E as a ten-CPU-clock free-running signal: six clocks low and four clocks high. At 7.8336 MHz, the calculated values are approximately:

```text
CPU period: 127.655 ns
E period:   1,276.552 ns
E high:       510.621 ns
E low:        765.931 ns
```

The RTL's counter ratio produces the correct nominal 10-clock period and 4/6 duty ratio in simulation, but its phase relative to `/AS`, `VPA`, `VMA`, and the physical SE remains unverified. Reference: https://www.nxp.com/docs/en/reference-manual/MC68000UM.pdf, Section 4 and Section 10.11.

## Timing-corrected candidate

The RTL was corrected to sample synchronized `DTACK`, `BERR`, and `VPA` on the `c7m_falling` event, defer VMA until E is low, and give asynchronous termination precedence over VPA. A new EPM240 POF/SVF was synthesized from that revision.

This image is a candidate for a second **isolated** hardware test. Do not reprogram it while the PiStorm is connected to a powered SE; preserve the currently booting image until the board is isolated and the JTAG ID is rechecked.
