#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
iverilog -g2012 -Wall -s tb -o "$ROOT/macse_arbitration_test.vvp" "$ROOT/pistorm.v" "$ROOT/tb_arbitration.v"
vvp "$ROOT/macse_arbitration_test.vvp"
iverilog -g2012 -Wall -s tb_timing -o "$ROOT/macse_timing_test.vvp" "$ROOT/pistorm.v" "$ROOT/tb_timing.v"
vvp "$ROOT/macse_timing_test.vvp"
iverilog -g2012 -Wall -s tb_safety -o "$ROOT/macse_safety_test.vvp" "$ROOT/pistorm.v" "$ROOT/tb_safety.v"
vvp "$ROOT/macse_safety_test.vvp"
printf '%s\n' 'ALL RTL TESTS PASSED'
