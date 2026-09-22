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
