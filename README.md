# 8-bit MAC Unit on SKY130 (RTL to GDSII)

ELL7301 / ELL734 Digital CMOS VLSI Design, Assignment 2
Author: Betha Navya (2025JID2497)

A synchronous 8x8 unsigned multiply-accumulate unit, `Y <= Y + A*B`, with a 20-bit accumulator,
synchronous active-high reset and an enable input. The design is taken from RTL through
synthesis, timing analysis, place and route, DRC and LVS to a GDSII file using only
open-source tools and the SkyWater SKY130 PDK.

## Final result (`mac8_optimized`)

| Metric | Baseline | Final | Target |
|---|---|---|---|
| Area (um^2) | 3169.29 (cell area, pre-layout) | 9594.2 (core, post-layout) | <= 10,000 |
| Critical path (ns) | 4.79 (pre-route) | 2.93 (post-route) | <= 4 |
| Frequency (MHz) | ~205 (estimated) | 250 | >= 250 |
| Setup slack (ns) | -0.91 (violated) | 0.0 (met, post-route) | >= 0 |
| Hold violations | not evaluated | none | none |
| Power | not measured | ~2.1 nW (typical corner, default toggle rate) | <= 2 mW |
| DRC violations | n/a | 0 | 0 |
| LVS | n/a | clean (710/710 nets) | pass |

The power figure uses OpenSTA's default switching activity because no VCD/SAIF file was
supplied, so it is probably an underestimate of real power.

## Architectures explored

Each step was driven by a measured timing or area problem in the previous one.

| # | Design | Stages | Flip-flops | Slack (ns) | Note |
|---|---|---|---|---|---|
| 1 | `mac8` baseline | 1 | 20 | -0.91 | multiply and accumulate in one cycle |
| 2 | `mac8_pipelined` | 2 | 37 | -2.74 | worse: exposed a 14-gate ripple-carry chain |
| 3 | `mac8_pipelined3` | 3 | 76 | -2.91 | carry-save accumulator, slow resolve adder |
| 4 | `mac8_pipelined4` | 4 | 107 | -0.21 | resolve adder split 10+10 |
| 5 | `mac8_pipelined5` | 5 | 133 | +0.10 | split 5+5+10, met pre-route only |
| 6 | `mac8_pipelined6` | 6 | 158 | met post-route | multiplier split, but core area 23,262 um^2 |
| 7 | `mac8_optimized` | 3 | 62 | met | carry-select adder, single accumulator register (**final**) |

The final design splits the multiplier into two 4x8 partial products (stages 1a and 1b) and
uses a single-cycle carry-select adder (five 4-bit blocks) for the accumulate stage. It accepts
one new A,B pair every clock cycle (a 500-cycle full-throughput test passes).

## Repository layout

```
rtl/            Verilog for all 7 architectures
tb/             Self-checking testbenches (golden-model comparison) and the throughput test
constraints/    constraints.sdc (4.0 ns clock)
config/         Yosys scripts (synth_*.ys) and the OpenLane config.json
reports/        Synthesis, timing, area and signoff reports
layout/         mac8.gds (final GDSII) and rendered layout images
verification/   drc.rpt and lvs.rpt
results/        Screenshots used as evidence in the report
docs/           Report and learning guide
```

## Tools

Icarus Verilog (simulation), GTKWave (waveforms), Yosys 0.33 (synthesis), OpenSTA 2.4.0
(timing and power), OpenLane 1.0.2 / OpenROAD (floorplan, placement, CTS, routing),
Magic (DRC, GDS), Netgen (LVS), KLayout (layout rendering). PDK: SKY130A, `sky130_fd_sc_hd`.

## Reproducing

Functional simulation:

```bash
iverilog -o sim.out rtl/mac8_optimized.v tb/mac8_optimized_tb.v && vvp sim.out
# expected: TEST SUMMARY: 1009 checks, 1009 PASS, 0 FAIL
iverilog -o sim_tp.out rtl/mac8_optimized.v tb/mac8_optimized_throughput_tb.v && vvp sim_tp.out
# expected: TEST SUMMARY: 500 checks, 500 PASS, 0 FAIL
```

Synthesis. The SKY130 liberty file is not stored in this repo because of its size:

```bash
mkdir -p config
curl -L -o config/sky130_fd_sc_hd__tt_025C_1v80.lib \
  https://raw.githubusercontent.com/efabless/skywater-pdk-libs-sky130_fd_sc_hd/master/timing/sky130_fd_sc_hd__tt_025C_1v80.lib
yosys -s config/synth_optimized.ys
```

Physical design: copy `rtl/mac8_optimized.v` into `designs/mac8_final/src/` of a classic
OpenLane install, use `config/config.json` as that design's config, then run
`./flow.tcl -design mac8_final -tag run1` inside the OpenLane container.

## Notes

- Floorplan, placement and CTS renders use KLayout's default palette (no SKY130 layer
  properties file was set up), so those three images look similar to each other. The routing
  and final GDS renders show distinct content.
- An AI assistant was used during development for explanations and drafting. Add your
  course's required disclosure here if one applies.
