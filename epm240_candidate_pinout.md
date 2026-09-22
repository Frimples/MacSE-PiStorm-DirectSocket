# Candidate EPM240T100C5 pinout for PiStorm Rev B

This combines the corrected Gerber pad orientation, the official Altera EPM240 T100 pin table, and `pistorm_epm240.qsf`.

## Counts

- Device pins: 100
- QSF signal assignments: 59
- EPM240 power/JTAG/special pins: 20
- Unassigned user-I/O positions: 21

## Status

The QSF column is a candidate logical mapping from the RTL project; it is not independently proven by net-name data in the Gerbers. The physical pad and device special-function columns are grounded in the Gerber geometry and Altera pin table.

The full 100-pin CSV is `epm240_candidate_pinout.csv`.
