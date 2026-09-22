# EPM240T100C5 / EPM570T100C5 package comparison

Sources:

- DigiKey EPM240T100C5 product page: https://www.digikey.com/en/products/detail/altera/EPM240T100C5/703853
- Altera, *Pin Information for the MAX II EPM240 / EPM240G Devices*, version 1.4
- Altera, *Pin Information for the MAX II EPM570 / EPM570G Devices*, version 1.4

## EPM240T100C5

- MAX II CPLD
- 100-pin TQFP
- 80 user I/O pins
- 192 macrocells / 240 logic elements family designation
- C5 speed grade
- EPM240 VCCINT: pins 13 and 63
- EPM240 GNDINT: pins 11 and 65
- VCCIO1: pins 9, 31, 45
- VCCIO2: pins 59, 80, 94
- GNDIO: pins 10, 32, 46, 60, 79, 93
- GCLK0: pin 12
- GCLK1: pin 14
- GCLK2: pin 62
- GCLK3: pin 64
- DEV_OE: pin 43
- DEV_CLRn: pin 44
- TMS: pin 22
- TDI: pin 23
- TCK: pin 24
- TDO: pin 25

## EPM570T100C5

- 100-pin TQFP
- 76 user I/O pins
- VCCINT: pins 13, 39, 63, 88
- GNDINT: pins 11, 37, 65, 90
- VCCIO1: pins 9, 31, 45
- VCCIO2: pins 59, 80, 94
- GNDIO: pins 10, 32, 46, 60, 79, 93
- GCLK0/GCLK1/GCLK2/GCLK3: pins 12, 14, 62, 64
- DEV_OE/DEV_CLRn: pins 43, 44
- TMS/TDI/TCK/TDO: pins 22, 23, 24, 25

## Consequence for the Gerber set

The EPM240 and EPM570 share the same 100-pin package and the listed dedicated
JTAG/clock/control pin numbers. They do **not** have the same power pinout:

```text
EPM240 pin 37 = user I/O; EPM570 pin 37 = GNDINT
EPM240 pin 39 = user I/O; EPM570 pin 39 = VCCINT
EPM240 pin 88 = user I/O; EPM570 pin 88 = VCCINT
EPM240 pin 90 = user I/O; EPM570 pin 90 = GNDINT
```

Therefore the Gerber BOM's `EPM570T100C5` designation is electrically important,
not merely a capacity label. If the PCB routes pins 37/39/88/90 as EPM570 power,
it cannot be treated as an EPM240 pin map without proving the actual assembled
part and power routing.

The current EPM240 QSF uses shared dedicated-capable pins consistently:

```text
PI_CLK       -> pin 12 (GCLK0)
M68K_CLK     -> pin 62 (GCLK2)
M68K_FC[1]   -> pin 64 (GCLK3)
LTCH_A_OE_n  -> pin 43 (DEV_OE-capable)
LTCH_A_0     -> pin 44 (DEV_CLRn-capable)
JTAG         -> pins 22..25 (left for programming)
```

This establishes device-level constraints, but it does not prove that the
Gerber's U4 copper connects to the same logical signals.
