# Firmware design notes

## Bus ownership

The direct-socket path must coexist with the Macintosh motherboard's 68000 bus arbitration. `/BR` is asynchronous to the CPLD logic, so it is synchronized before use. The design asserts `/BG` only at a transaction boundary and tracks the acknowledgement path through `/BGACK`.

While the motherboard owns the bus, the Pi-side CPU control outputs are released to high impedance rather than merely driven inactive. This matters because the original CPU and other motherboard logic may drive or observe those nets during ownership transfer.

The current RTL explicitly releases `FC`, `/AS`, `/UDS`, `/LDS`, `R/W`, and `/VMA`. Address, data, and latch/transceiver enables require separate electrical confirmation against the populated board.

## Clock and transaction paths

The existing design uses the Pi clock and generated/divided internal timing to service Pi-side accesses and Macintosh peripheral cycles. The testbench checks observable E-clock activity and the `/VPA` response path that produces `/VMA`.

The RTL is not a cycle-accurate replacement for a discrete 68000 until physical captures establish:

- phase relationship between E-clock and bus strobes;
- `/VPA` recognition window;
- `/VMA` assertion width and release;
- `/DTACK` response timing;
- interrupt-acknowledge behavior;
- reset and halt behavior.

## Function-code transport

The optional function-code transport uses `PI_D[12:10]` during `REG_ADDR_HI`. This preserves the existing low-level protocol for callers that leave those spare bits zero while making the 68000 function-code state available to the direct-socket path.

## Asynchronous inputs

Synchronizers reduce metastability risk but do not prove a safe board-level timing relationship. `/BR`, `/BGACK`, reset-related signals, and any other asynchronous control must be checked against the actual board's pullups, edge rates, and voltage levels.

## Design non-goals

- PDS card bus takeover.
- Amiga compatibility logic.
- Automatic programming of a physical CPLD.
- Claiming that RTL simulation proves motherboard compatibility.
