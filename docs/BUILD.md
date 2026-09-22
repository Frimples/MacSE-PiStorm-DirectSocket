# Build process and evidence

## Toolchain recovery

The original development host and Raspberry Pi did not have a usable Quartus installation. An x86_64 Ubuntu laptop was used because the MAX II Lite device support and fitter require an appropriate Quartus installation.

The first installer attempts failed after exposing two independent environmental problems: the laptop root filesystem entered `ext4 emergency_ro` after an I/O error, and available swap was exhausted during installation. Installation was not repeated until the filesystem was writable and memory/swap were adequate.

A reduced Quartus Prime Lite 25.1 installation was then completed with MAX II support retained. The Quartus shell reported:

```text
Quartus Prime Lite 25.1std.0 Build 1129
```

## Project correction

An earlier wrapper invocation appeared to succeed without producing programming output because the copied QSF lacked source-file assignments. The project was corrected to explicitly include:

```text
set_global_assignment -name TOP_LEVEL_ENTITY pistorm
set_global_assignment -name VERILOG_FILE pistorm.v
set_global_assignment -name SDC_FILE pistorm.sdc
```

Map was then run directly to prove that the RTL was actually compiled before fitting.

## Build stages

```sh
quartus_map pistorm_epm240
quartus_fit pistorm_epm240
quartus_asm pistorm_epm240
quartus_cpf -c -q 100.0kHz -g 3.3 -n p \
   output_files/pistorm_epm240.pof \
   output_files/pistorm_epm240.svf
```

The explicit `-n p` option is required for Quartus CPF to create a programming SVF from the POF. Use `100.0kHz`, matching the repository's known-good EPM240 SVFs; generating at 10 MHz produces approximately 100x larger `RUNTEST` waits and can make `pistormflash` appear to hang.

The direct-socket RTL must retain `FC=000` with the current Pi-side protocol. The Pi-side address-high write carries the upper address byte in `PI_D[15:8]`; `PI_D[12:10]` are address bits, not spare function-code fields. Do not transport FC through those bits unless the Pi-side protocol is changed at the same time.

## Recorded result

```text
Device:    EPM240T100C5
Map:       0 errors
Fitter:    0 errors, 2 warnings
Assembler: 0 errors, 0 warnings
POF:       generated
SVF:       generated
```

The release directory contains the POF, SVF, `.pin` report, map report, fitter report, and the QSF used for the build. The SVF begins with an EPM240 device declaration and uses a 10-bit instruction register, consistent with the verified MAX II device family.

## Rebuild discipline

Always verify all of the following after a rebuild:

- target device is `EPM240T100C5`;
- source file is `pistorm.v`;
- map, fit, and assembly actually ran;
- no error appears in the reports;
- `.pof` and `.svf` exist and have nonzero size;
- SVF header names the expected device;
- hashes are recorded before transfer or programming.

Do not edit an SVF by hand to change RTL behavior. Change Verilog/QSF, rerun Quartus, and regenerate the SVF.
