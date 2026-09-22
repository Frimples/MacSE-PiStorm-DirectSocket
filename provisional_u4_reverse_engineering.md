# PiStorm Rev B Gerber reverse-engineering notes

## Source archive

Input:

```text
PiStorm_RevB_EPM240_74LVC16373.zip
```

The archive contains:

- `BOM_Pistorm_rev_b.xls`
- `CPL_Pistorm_rev_b.xls`
- `PistormRevB_PCB_FAB.zip`

The inner fabrication archive contains four copper layers (`GTL`, `G1`, `G2`,
`GBL`), masks, silkscreen, paste, outline, and drill files.

## Important identification result

The BOM does **not** describe an EPM240/74LVC16373 board:

```text
U4       EPM570T100C5
U1,U7    SN74CBTD3384PWLE
U2,U3,U5,U6 SN74LVC16374DGGR
```

This is therefore a Rev-B EPM570 board export, or at least an export whose BOM
was generated for EPM570. It must not be used as proof of the EPM240 Quartus pin
assignment.

## U4 physical placement

From the pick-and-place file:

```text
Reference: U4
Center:    X=13.1000 mm, Y=50.3200 mm
Layer:     Top
Rotation:  0 degrees
Footprint: TQFP100_N (from BOM)
```

The top-paste Gerber (`GTP`) contains exactly 100 obround pad apertures in the U4 region:

- 25 pads on each side;
- 0.5 mm pitch;
- top row: X=7.10..19.10 mm, Y=42.77 mm;
- right row: X=20.65 mm, Y=44.32..56.32 mm;
- bottom row: X=19.10..7.10 mm, Y=57.82 mm;
- left row: X=5.55 mm, Y=56.32..44.32 mm.

These coordinates are measured from the Gerber pad apertures and are more reliable
than the earlier nominal model. The physical side/index labels in the CSV are
not yet assigned to manufacturer pin numbers because the pin-1 marker and package
orientation still need to be tied to the exact footprint definition.

## New Gerber observation: EPM240/EPM570 discriminator pads

Using the T100 top-view numbering and the measured U4 pad coordinates, pads 37,
39, 88, and 90 were inspected on all four copper layers and the drill file.
Each has a top-layer copper trace leaving the pad region in the Gerber export;
there is no nearby plated drill transition within 0.03 inch of the pad center.

This is evidence that the four positions are routed signal-style pads in this
PCB export, rather than an immediately obvious set of EPM570 power-pad
connections. It is **not proof** of the electrical net: a power trace can also
run on the top layer into a copper region, and the Gerber export has no net
names. Continuity must be followed to the destination copper region or measured
on a physical board.

The trace walk also found these physical transitions:

```text
EPM240/EPM570 pin 37 -> top copper -> via near (0.49606, 1.77933 in)
                       -> inner layer G1

EPM240/EPM570 pin 39 -> top copper -> via at (0.49606, 1.57362 in)
                       -> inner layer G2 and bottom copper

EPM240/EPM570 pin 88 -> top copper -> via near (0.51575, 2.22717 in)
                       -> bottom copper through a wider copper feature

EPM240/EPM570 pin 90 -> no separate via found at the pad center in this pass
```

The coordinates are Gerber coordinates, not component net names. The pin 39
and pin 88 paths clearly leave the U4 footprint and change layers; pin 37 also
changes to G1. Pin 90 needs a separate region/pour inspection because the absence
of a via does not distinguish a same-layer route from a copper pour or an
unconnected/unused pad.


## Physical copper join requiring orientation resolution

The Gerber walk found a continuous copper path:

```text
U4 pad center (0.51575, 2.27835 in)
  -> via (0.51575, 2.22717 in)
  -> bottom copper diagonal to (0.26969, 1.98110 in)
  -> top copper to the pad at (0.21850, 1.98110 in)
```

This is a real physical pad-to-pad copper connection in the exported artwork.
The logical pin numbers cannot be assigned until the Gerber/CAD Y orientation is
resolved against the U4 pin-1 marker:

- Under the unmirrored Altera top-view convention, the pair would be candidate
  pins 88 and 13.
- Under the vertically mirrored board-artwork convention indicated by the
  apparent lower-left silkscreen marker, the same physical pads would instead be
  candidate pins 38 and 13.

This distinction matters because EPM240 pin 88 is I/O while EPM570 pin 88 is
VCCINT; pin 38 is I/O in both devices. The copper join therefore cannot yet be
used to prove or disprove the BOM device until the pin-1 marker orientation is
settled. A clear photo of U4 pin 1, the original PCB footprint, or the Altium
source would resolve it immediately.


1. Locate the 100 U4 land pads from the top paste/solder-mask/copper layers.
2. Follow copper segments on each layer.
3. Join layer transitions through the plated drill coordinates.
4. Continue through the 74LVC/CBTD packages and connector pads.
5. Assign a physical connectivity ID to each U4 pad.

This can produce statements such as:

```text
U4 physical pad N -> U6 physical pad M -> connector pad P
```

It cannot, by itself, establish that a connectivity ID is `M68K_AS_n`,
`PI_CLK`, or another logical signal. The Gerber export has no net labels or
netlist.

## Current provisional artifact

```text
provisional_u4_physical_map.csv
```

This is a coordinate worksheet, not a CPLD pin map. It is suitable for recording
trace results but not for Quartus or SVF generation.

## Required evidence for logical signal names

At least one of the following is still required:

- Original schematic or PCB source with net names.
- Original EPM240/EPM570 Quartus QSF.
- Netlist export.
- Known connector pinout plus a complete copper trace reconstruction.
- Physical continuity measurements from U4 pads to labeled connector/test points.

## Safety conclusion

The Gerbers are useful for reconstructing physical routing and checking whether
external bus buffers exist. They do not resolve the EPM240 pin-map problem, and
their EPM570 BOM makes them unsuitable as the sole source for an EPM240 SVF.
