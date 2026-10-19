[33maf9a9f2[m[33m ([m[1;31morigin/main[m[33m)[m ELL7301 Assignment 2: 8-bit MAC on SKY130, RTL to GDSII
 .gitignore                                                    |   14 [32m+[m
 config/config.json                                            |   29 [32m+[m
 config/synth_baseline.ys                                      |   13 [32m+[m
 config/synth_optimized.ys                                     |   13 [32m+[m
 config/synth_pipelined.ys                                     |   26 [32m+[m
 config/synth_pipelined3.ys                                    |   13 [32m+[m
 config/synth_pipelined4.ys                                    |   13 [32m+[m
 config/synth_pipelined5.ys                                    |   12 [32m+[m
 constraints/constraints.sdc                                   |   10 [32m+[m
 docs/report.pdf                                               |  Bin [31m0[m -> [32m2704445[m bytes
 layout/mac8.gds                                               |  Bin [31m0[m -> [32m2233478[m bytes
 layout/mac8_layout_render.png                                 |  Bin [31m0[m -> [32m687471[m bytes
 layout/stage_cts.png                                          |  Bin [31m0[m -> [32m95671[m bytes
 layout/stage_floorplan.png                                    |  Bin [31m0[m -> [32m95671[m bytes
 layout/stage_placement.png                                    |  Bin [31m0[m -> [32m95671[m bytes
 layout/stage_routing.png                                      |  Bin [31m0[m -> [32m230906[m bytes
 reports/mac8_synth_baseline.v                                 | 2611 [32m+++++++++++++++++++++++++++++[m
 reports/mac8_synth_optimized.v                                | 3144 [32m++++++++++++++++++++++++++++++++++[m
 reports/mac8_synth_pipelined.v                                | 2198 [32m++++++++++++++++++++++++[m
 reports/mac8_synth_pipelined3.v                               | 3891 [32m++++++++++++++++++++++++++++++++++++++++++[m
 reports/mac8_synth_pipelined4.v                               | 4150 [32m+++++++++++++++++++++++++++++++++++++++++++++[m
 reports/mac8_synth_pipelined5.v                               | 4474 [32m+++++++++++++++++++++++++++++++++++++++++++++++++[m
 reports/sim_output.txt                                        |    3 [32m+[m
 reports/synthesis_baseline.rpt                                | 1020 [32m+++++++++++[m
 reports/synthesis_optimized.rpt                               | 1118 [32m++++++++++++[m
 reports/synthesis_pipelined.rpt                               |  789 [32m+++++++++[m
 reports/synthesis_pipelined3.rpt                              | 1051 [32m++++++++++++[m
 reports/synthesis_pipelined4.rpt                              | 1099 [32m++++++++++++[m
 reports/synthesis_pipelined5.rpt                              | 1131 [32m+++++++++++++[m
 reports/synthesis_pipelined_timed.rpt                         | 1001 [32m+++++++++++[m
 results/screenshots/FINAL_optimized_all_3_constraints_MET.png |  Bin [31m0[m -> [32m126451[m bytes
 results/screenshots/part1_sim_log.png                         |  Bin [31m0[m -> [32m49243[m bytes
 results/screenshots/part1_verification_1024_pass.png          |  Bin [31m0[m -> [32m49243[m bytes
 results/screenshots/part1_waveform_255_end_cursor.png         |  Bin [31m0[m -> [32m51679[m bytes
 results/screenshots/part1_waveform_255_result.png             |  Bin [31m0[m -> [32m52934[m bytes
 results/screenshots/part1_waveform_extra1.png                 |  Bin [31m0[m -> [32m56707[m bytes
 results/screenshots/part1_waveform_overview.png               |  Bin [31m0[m -> [32m56707[m bytes
 results/screenshots/part1_waveform_zoom1.png                  |  Bin [31m0[m -> [32m52934[m bytes
 results/screenshots/part1_waveform_zoom2_final.png            |  Bin [31m0[m -> [32m51679[m bytes
 results/screenshots/part2_sim_pipelined3_pass.png             |  Bin [31m0[m -> [32m52294[m bytes
 results/screenshots/part2_sim_pipelined4_pass.png             |  Bin [31m0[m -> [32m68542[m bytes
 results/screenshots/part2_synth_baseline_area.png             |  Bin [31m0[m -> [32m66877[m bytes
 results/screenshots/part2_synth_baseline_cells.png            |  Bin [31m0[m -> [32m112984[m bytes
 results/screenshots/part2_synth_pipelined2_area.png           |  Bin [31m0[m -> [32m128215[m bytes
 results/screenshots/part2_synth_pipelined2_cells.png          |  Bin [31m0[m -> [32m99014[m bytes
 results/screenshots/part2_synth_pipelined3_area.png           |  Bin [31m0[m -> [32m65350[m bytes
 results/screenshots/part2_synth_pipelined3_cells.png          |  Bin [31m0[m -> [32m95538[m bytes
 results/screenshots/part2_synth_pipelined4_area.png           |  Bin [31m0[m -> [32m80107[m bytes
 results/screenshots/part2_synth_pipelined4_cells.png          |  Bin [31m0[m -> [32m108333[m bytes
 results/screenshots/part2_synth_pipelined5_area.png           |  Bin [31m0[m -> [32m127963[m bytes
 results/screenshots/part2_synth_pipelined5_cells.png          |  Bin [31m0[m -> [32m145635[m bytes
 results/screenshots/part2_synthesis_log_1.png                 |  Bin [31m0[m -> [32m112984[m bytes
 results/screenshots/part2_synthesis_log_2.png                 |  Bin [31m0[m -> [32m66877[m bytes
 results/screenshots/part2_synthesis_log_3.png                 |  Bin [31m0[m -> [32m111605[m bytes
 results/screenshots/part2_timing_baseline_1.png               |  Bin [31m0[m -> [32m114731[m bytes
 results/screenshots/part2_timing_baseline_slack.png           |  Bin [31m0[m -> [32m136730[m bytes
 results/screenshots/part2_timing_baseline_violation.png       |  Bin [31m0[m -> [32m136730[m bytes
 results/screenshots/part2_timing_pipelined3_slack.png         |  Bin [31m0[m -> [32m129355[m bytes
 results/screenshots/part2_timing_pipelined4_slack.png         |  Bin [31m0[m -> [32m125285[m bytes
 results/screenshots/part2_timing_pipelined5_MET.png           |  Bin [31m0[m -> [32m143131[m bytes
 results/screenshots/rtl_mac8_pipelined6_multiplier_split.png  |  Bin [31m0[m -> [32m107659[m bytes
 rtl/mac8.v                                                    |   23 [32m+[m
 rtl/mac8_optimized.v                                          |   78 [32m+[m
 rtl/mac8_pipelined.v                                          |   33 [32m+[m
 rtl/mac8_pipelined3.v                                         |   63 [32m+[m
 rtl/mac8_pipelined4.v                                         |   79 [32m+[m
 rtl/mac8_pipelined5.v                                         |  100 [32m++[m
 rtl/mac8_pipelined6.v                                         |  117 [32m++[m
 tb/mac8_optimized_tb.v                                        |  112 [32m++[m
 tb/mac8_optimized_throughput_tb.v                             |   93 [32m+[m
 tb/mac8_pipelined3_tb.v                                       |  119 [32m++[m
 tb/mac8_pipelined4_tb.v                                       |  135 [32m++[m
 tb/mac8_pipelined5_tb.v                                       |  159 [32m++[m
 tb/mac8_pipelined6_tb.v                                       |  173 [32m++[m
 tb/mac8_pipelined_tb.v                                        |   94 [32m++[m
 tb/mac8_tb.v                                                  |  113 [32m++[m
 verification/drc.rpt                                          |    5 [32m+[m
 verification/lvs.rpt                                          | 2067 [32m+++++++++++++++++++++++[m
 78 files changed, 31386 insertions(+)
