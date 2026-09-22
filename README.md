# Macintosh SE PiStorm Direct-Socket RTL

An independently documented, Macintosh SE-focused CPLD firmware project for a PiStorm connected directly to the original 68000 CPU socket.

> **Status: build artifact complete; hardware validation pending.**
>
> The repository contains a newly synthesized EPM240 programming image, but it has not been programmed into hardware and no real Macintosh SE waveform capture has yet been performed.

This project is deliberately separate from the PiStorm PDS-card work. It does not claim to implement Amiga compatibility, a PDS bus takeover, or a proven drop-in replacement for every Macintosh SE bus condition.

## Target

- Computer: Apple Macintosh SE
- Bus: direct connection at the original Motorola 68000 CPU socket
- CPLD: Altera/Intel MAX II **EPM240T100C5**
- Verified installed device: JTAG IDCODE `0x020A10DD`
- Device package: TQFP-100
- HDL: Verilog
- Build tool: Quartus Prime Lite 25.1std.0 Build 1129
- Simulation: Icarus Verilog

The EPM240 target is based on live JTAG identification. A supplied Gerber/BOM archive labels one board component `EPM570T100C5`; that conflicting BOM entry is documented as evidence, not silently treated as the installed-device identity.

## What is implemented

The RTL preserves the existing PiStorm transaction and peripheral timing paths while adding direct-socket bus-ownership behavior:

- Synchronization of asynchronous `/BR` and `/BGACK` inputs.
- Bus grant sequencing at an idle/boundary condition rather than in the middle of a Pi-generated transaction.
- `/BG` assertion for a motherboard bus-master request.
- Release tracking after `/BGACK` acknowledgement.
- High impedance on CPU control outputs during external bus ownership:
  - `FC[2:0]`
  - `/AS`
  - `/UDS`
  - `/LDS`
  - `R/W`
  - `/VMA`
- Deterministic initialization of clock, reset, synchronizer, interrupt, and transaction state.
- Existing E-clock and `/VPA` to `/VMA` paths retained for simulation and later hardware validation.
- Optional function-code transport through `PI_D[12:10]` during the high address phase.

This is not a claim that every electrical enable path on the assembled board has been proven. External latch/transceiver output-enable behavior still requires instrumented hardware testing.

## Repository map

| Path | Purpose |
|---|---|
| `pistorm.v` | Main direct-socket RTL |
| `pistorm_epm240.qsf` | EPM240T100C5 Quartus project assignments |
| `pistorm_epm240.qpf` | Quartus project descriptor |
| `pistorm.sdc` | Timing constraints inherited/adapted for the design |
| `tb_arbitration.v` | Bus request/grant/acknowledge and tri-state testbench |
| `tb_timing.v` | E-clock, `/VPA`, `/VMA`, and transaction timing testbench |
| `run_tests.sh` | Repeatable Icarus test runner |
| `epm240_candidate_pinout.*` | Candidate logical-to-physical reconstruction |
| `provisional_u4_*` | Gerber-derived physical evidence and limitations |
| `epm240_epm570_t100_comparison.md` | Official pin-function comparison |
| `release/epm240_build/` | Verified Quartus build outputs and reports |
| `release/macse_epm240_programming_artifact.zip` | Packaged POF/SVF and build evidence |
| `docs/` | Design, build, validation, and reconstruction documentation |

## Reproduce the RTL tests

On a system with Icarus Verilog:

```sh
./run_tests.sh
```

The tests cover:

1. Pi-side transaction behavior and generated E-clock activity.
2. `/VPA` response and generated `/VMA` activity.
3. `/BR` request, `/BG` grant, `/BGACK` acknowledgement, grant release, and CPU control-output high impedance.

Passing simulation does not establish electrical correctness, metastability margins, or compatibility with an unmodified Macintosh SE motherboard.

## Reproduce the Quartus build

Use an x86 Linux machine with Quartus Prime Lite 25.1 and MAX II device support installed. The exact build used for the checked-in artifact was:

```text
Quartus Prime Lite 25.1std.0 Build 1129
Device: EPM240T100C5
```

The source project must contain `pistorm.v`, `pistorm.sdc`, `pistorm_epm240.qpf`, and `pistorm_epm240.qsf`. A typical command is:

```sh
quartus_map pistorm_epm240
quartus_fit pistorm_epm240
quartus_asm pistorm_epm240
quartus_cpf -c -q 10.0MHz -g 3.3 -n p \
   output_files/pistorm_epm240.pof \
   output_files/pistorm_epm240.svf
```

The SVF conversion requires `-n p` to request the programming operation. Do not infer successful programming-file creation from a wrapper command alone: verify that the `.pof` and `.svf` exist and inspect their device headers.

## Programming warning

Do **not** program the CPLD solely because this repository contains an SVF. Before hardware programming:

1. Confirm the board revision and actual CPLD identity with JTAG.
2. Preserve the known-good recovery SVF.
3. Confirm the physical pin map and external latch/transceiver topology.
4. Compare the generated SVF header and chain assumptions with the live JTAG chain.
5. Use current-limited, observable hardware testing and capture reset, bus grant, `/AS`, `/DTACK`, `/VPA`, `/VMA`, E-clock, and transceiver-enable signals.

The checked-in SVF is a programming artifact, not a guarantee that the direct-socket hardware will boot.

## Build result

The checked-in artifact was generated from the actual RTL with the EPM240 project:

```text
Map:       successful
Fitter:    successful
Assembler: successful
Errors:    0
SVF:       generated
```

Quartus reported two warnings that remain documented rather than hidden:

- `M68K_BERR_n` is unused by the synthesized logic.
- Derived clock `c7m_sync[2]` has no direct timing assignment.

These warnings need engineering review before treating the design as production-ready.

## Scope and limitations

This project is a research/build artifact, not a certified Macintosh replacement. Still outstanding:

- Real SE oscilloscope or logic-analyzer captures.
- Full verification of VIA and SCC cycles on the physical motherboard.
- `/DTACK`, interrupt acknowledge, reset, halt, and bus-error behavior under all relevant conditions.
- Confirmation of `/BR` and `/BGACK` timing relative to actual motherboard arbitration.
- Verification of external latch and transceiver enable polarity and break-before-make behavior.
- Timing-constraint review for generated clocks and asynchronous crossings.
- Confirmation that the candidate QSF pin map matches the exact populated board revision.

## Provenance

The work proceeded in stages:

1. Separate the direct CPU-socket target from the PDS project.
2. Compile the existing RTL and establish repeatable simulation.
3. Add and test arbitration and CPU-control tri-state behavior.
4. Review Macintosh II/SE card and bus documentation.
5. Identify the physical CPLD over JTAG.
6. Reconstruct provisional board geometry and compare EPM240/EPM570 pin functions.
7. Build an EPM240-specific QSF rather than editing an existing SVF.
8. Install a usable x86 Quartus environment after diagnosing a failed filesystem/OOM installation.
9. Run map, fit, assembly, and explicit POF-to-SVF conversion.
10. Package reports, hashes, and warnings for review before any hardware programming.

See `docs/DESIGN.md`, `docs/BUILD.md`, `docs/VALIDATION.md`, and `docs/REVERSE_ENGINEERING.md` for the detailed record.

## License and upstream notice

No new license is asserted here until the upstream PiStorm source licensing and the provenance of each retained file are reviewed. The repository should be treated as a research archive until that review is complete.
