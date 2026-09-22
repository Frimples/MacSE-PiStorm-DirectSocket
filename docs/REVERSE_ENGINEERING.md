# Board and pin-map reconstruction

## Evidence sources

The candidate pinout was reconstructed from four sources:

1. Quartus logical pin assignments.
2. TQFP-100 pad geometry extracted from the supplied Gerbers.
3. U4 pin-1 orientation resolved from the silkscreen marker.
4. Official EPM240/EPM570 T100 pin-function documentation.

The Gerber archive contains copper, solder-mask, paste, silkscreen, drill, BOM, and placement information, but no schematic, netlist, logical net names, or QSF. Therefore the result is a candidate map, not a schematic-equivalent proof.

## Device conflict

The archive BOM identifies U4 as `EPM570T100C5`, while live JTAG identified the installed CPLD as:

```text
IDCODE:      0x020A10DD
Manufacturer: Altera
Part:        0x20A1
IR length:   11 reported by the scan configuration
```

The live identification is the stronger evidence for the populated device. The EPM570 BOM entry remains documented because it may describe a different board revision or an assembly/documentation mismatch.

## Geometry

The measured U4 footprint has 100 pads, 25 per side, at 0.5 mm pitch. Pin orientation is:

- left side, low-to-high Y: pins 1–25;
- high-Y row, low-to-high X: pins 26–50;
- right side, high-to-low Y: pins 51–75;
- low-Y row, high-to-low X: pins 76–100.

The detailed measurements and candidate mapping are retained in the root CSV/Markdown files.

## Limitations

Copper continuity can establish that a pad reaches a via or another pad, but without logical net names it cannot by itself prove the intended RTL signal. Power-plane joins and shared footprints can also make a visually plausible route misleading. The candidate QSF must therefore be checked against the exact assembled board before programming.
