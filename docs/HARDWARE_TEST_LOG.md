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
