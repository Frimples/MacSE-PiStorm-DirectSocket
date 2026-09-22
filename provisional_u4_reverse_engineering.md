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

The provisional CSV records a 100-pad TQFP coordinate model centered on that
placement. The pad numbering and exact pad-center offset are **not yet verified**
from the Gerber geometry; the CSV intentionally leaves all logical nets as
`UNKNOWN`.

## What can be recovered from these Gerbers

The copper layers can be used to recover physical connectivity:

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
