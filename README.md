# 8-bit MAC Unit on SKY130 (RTL to GDSII)

ELL7301 / ELL734 Digital CMOS VLSI Design, Assignment 2
Author: Betha Navya (2025JID2497)

A synchronous 8x8 unsigned multiply-accumulate (MAC) unit, `Y <= Y + A*B`, with a 20-bit
accumulator, synchronous active-high reset and an enable input. The design is taken from RTL
through synthesis, timing analysis, floorplanning, placement, clock tree synthesis, routing,
DRC and LVS to a GDSII file, using only open-source tools and the SkyWater SKY130 PDK.

```verilog
module mac8 (
    input         clk, reset, enable,
    input  [7:0]  A, B,
    output [19:0] Y
);
// reset = 1        -> Y = 0
// else enable = 1  -> Y = Y + A*B
// else             -> Y unchanged
```

## Final result (`mac8_opt3`)

| Metric | Baseline (`mac8`) | Optimized (final) | Target |
|---|---|---|---|
| Area (um^2) | 3169.29 (cell area, synthesis) | 9594.2 (core area, post-layout) | <= 10,000 |
| Critical delay (ns) | 4.79 | ~3.03 (4.00 ns clock - 0.97 ns slack) | <= 4 |
| Frequency (MHz) | ~209 | 250 met (about 330 achievable) | >= 250 |
| Power (mW) | not measured | 1.90 (typical corner, default toggle rate) | <= 2 |
| Setup slack (ns) | -0.91 (violated) | +0.97 | >= 0 |
| Hold slack (ns) | not evaluated | +0.33 | >= 0 |
| DRC violations | n/a | 0 | 0 |
| LVS | n/a | clean (0 errors) | PASS |

All three constraints (clock period <= 4 ns, area <= 10,000 um^2, power <= 2 mW) are met in
one signed-off run. Other signoff data: die area 13,074.65 um^2, standard-cell area
6,732.71 um^2 (synthesis), 45 flip-flops, clock skew 0.03 ns, 0 routing violations,
0 antenna violations. Power breakdown: internal 1.11 mW, switching 0.792 mW, leakage 4.09 nW.

Power was estimated with OpenSTA default switching activity because no VCD/SAIF file was
supplied, so it is a tool estimate and not a measured silicon figure. The OpenSTA report prints
power in watts (1.90e-03 W).

## Architectures explored

Each step was driven by a measured timing, area or power problem in the previous one.

| # | Design | Pipeline stages | Flip-flops | Result |
|---|---|---|---|---|
| 1 | `mac8` baseline | 1 | 20 | slack -0.91 ns, fails 250 MHz |
| 2 | `mac8_pipelined` | 2 | 37 | slack -2.74 ns, worse: exposed a ripple-carry chain |
| 3 | `mac8_pipelined3` | 3 | 76 | carry-save accumulator, slow resolve adder |
| 4 | `mac8_pipelined4` | 4 | 107 | resolve adder split 10+10 |
| 5 | `mac8_pipelined5` | 5 | 133 | met timing at synthesis, not after routing |
| 6 | `mac8_pipelined6` | 6 | 158 | multiplier split, timing met, core area 23,262 um^2 |
| 7 | `mac8_optimized` | 3 | 62 | carry-select adder: timing and area met, power 2.07 mW (over) |
| 8 | `mac8_opt3` | 2 | 45 | **final: 3:2 compressor + carry-select, meets all three constraints** |

The final design registers two 4x8 partial products (stage 1), then a 3:2 compressor adds them
to the accumulator and a single-cycle carry-select adder (five 4-bit blocks) produces the
result (stage 2). There is no separate product register. Latency is 2 cycles and throughput
is one result per clock. A single-stage 8x8 multiply (`mac8_opt2`, 38 flip-flops, 1.78 mW)
was also tried and fails timing by 0.70 ns. Synthesis strategy and utilization were tuned
last: AREA 3 synthesis gave +0.98 ns slack at 1.88 mW (DELAY strategies met timing but pushed
power to 2.31 mW), and raising utilization from 65% to 70% brought the core area from
10,231 um^2 to 9,594 um^2.

## Repository layout

```
rtl/            Verilog: mac8.v (baseline), mac8_pipelined*.v, mac8_optimized.v, mac8_opt2.v,
                final_optimized.v (final, module mac8_opt3)
tb/             Self-checking testbenches for each design (final_optimized_tb.v is the final one)
constraints/    constraints.sdc (4.0 ns clock)
config/         Yosys scripts (synth_*.ys) and config.json (OpenLane config of the final run)
reports/        Synthesis, timing, area and power reports of the final run (synthesis.rpt,
                timing.rpt, area.rpt, power.rpt, metrics.csv) and earlier synthesis reports
layout/         mac8.gds (final GDSII) and rendered layout images
verification/   drc.rpt and lvs.rpt of the final run
results/        Screenshots used as evidence in the report
docs/           report.pdf (final report, 38 pages, 2.76 MB)
```

## Tools

- Simulation: Icarus Verilog, GTKWave
- Synthesis: Yosys (ABC, SKY130 `sky130_fd_sc_hd` liberty)
- Timing and power: OpenSTA
- Physical design: OpenLane 1.0.2 (OpenROAD), SKY130A PDK
- Physical verification: Magic (DRC), Netgen (LVS)
- Layout rendering: KLayout

## Reproducing

Functional simulation. The testbench prints a pass/fail summary:

```bash
iverilog -o sim_final.out rtl/final_optimized.v tb/final_optimized_tb.v && vvp sim_final.out
# expected: TEST SUMMARY: 1020 checks, 1020 PASS, 0 FAIL
iverilog -o sim.out rtl/mac8.v tb/mac8_tb.v && vvp sim.out      # baseline
```

Physical design. Copy `rtl/final_optimized.v` (module `mac8_opt3`) into `designs/<name>/src/` of a classic OpenLane
1.0.2 install, use `config/config.json` as that design's config (`SYNTH_STRATEGY "AREA 3"`,
`FP_CORE_UTIL 70`, `PL_TARGET_DENSITY 0.75`, `MAX_FANOUT_CONSTRAINT 10`), and run
`./flow.tcl -design <name> -tag r1` inside the OpenLane container.

The SKY130 liberty file is not stored in this repo because of its size (12 MB). To run the
baseline Yosys scripts, download it into `config/`:

```bash
curl -L -o config/sky130_fd_sc_hd__tt_025C_1v80.lib \
  https://raw.githubusercontent.com/efabless/skywater-pdk-libs-sky130_fd_sc_hd/master/timing/sky130_fd_sc_hd__tt_025C_1v80.lib
```

## Notes

- Setup slack is +0.97 ns and hold slack +0.33 ns in the final run, so both are met with margin.
- Max-fanout warnings are reported by OpenLane (structural, on input buffers); max slew and
  max capacitance violations are 0.
- The full written report is in `docs/report.pdf`; it covers all architectures, run-by-run evidence and the signoff screenshots.
- `*.out` and `*.vcd` simulation outputs are ignored by `.gitignore` and can be regenerated.
