#!/usr/bin/env python3
"""Static contract checks for the MC68000 asynchronous bus phase."""
from pathlib import Path

rtl = Path(__file__).with_name("pistorm.v").read_text()
start = rtl.index("3'd3: begin // S3")
end = rtl.index("3'd4: begin // S4", start)
s3 = rtl[start:end]
assert "if(c7m_falling)" in s3, "S3 must sample DTACK/BERR/VPA on c7m_falling"
assert "if(c7m_rising)" not in s3, "S3 still samples bus responses on c7m_rising"
assert "vpa_pending" in rtl, "VPA recognition must have an E-low pending path"
print("PASS: MC68000 falling-edge response timing contract")
