create_clock -name clk -period 4.000 [get_ports clk]
set_clock_uncertainty 0.1 [get_clocks clk]
set_clock_transition 0.1 [get_clocks clk]

set_input_delay -clock clk 0.400 [get_ports reset]
set_input_delay -clock clk 0.400 [get_ports enable]
set_input_delay -clock clk 0.400 [get_ports A*]
set_input_delay -clock clk 0.400 [get_ports B*]

set_output_delay -clock clk 0.400 [get_ports Y*]
