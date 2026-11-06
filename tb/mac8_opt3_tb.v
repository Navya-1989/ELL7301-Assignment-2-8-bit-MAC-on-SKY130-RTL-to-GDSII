`timescale 1ns/1ps
module mac8_opt3_tb;
    reg clk = 0, reset = 1, enable = 0;
    reg [7:0] A = 0, B = 0;
    wire [19:0] Y;
    mac8_opt3 dut (.clk(clk), .reset(reset), .enable(enable), .A(A), .B(B), .Y(Y));
    always #2 clk = ~clk;

    // golden model: spec behaviour with the design's fixed 1-cycle input delay
    reg [19:0] exp_Y = 0;
    reg [15:0] g_prod = 0;
    reg        g_en = 0;
    integer checks = 0, fails = 0, i;

    always @(posedge clk) begin
        if (reset) begin exp_Y <= 0; g_prod <= 0; g_en <= 0; end
        else begin
            if (g_en) exp_Y <= exp_Y + g_prod;
            g_prod <= A * B;
            g_en   <= enable;
        end
    end

    task check; begin
        checks = checks + 1;
        if (Y !== exp_Y) begin fails = fails + 1;
            $display("FAIL t=%0t A=%0d B=%0d en=%b Y=%0d exp=%0d", $time, A, B, enable, Y, exp_Y); end
    end endtask

    task step(input r, input e, input [7:0] a, input [7:0] b); begin
        @(negedge clk); reset = r; enable = e; A = a; B = b;
        @(posedge clk); #1; check;
    end endtask

    initial begin
        step(1,0,0,0); step(1,0,5,5);                       // reset
        step(0,1,3,4); step(0,1,10,10); step(0,0,7,7);      // accumulate then hold
        step(0,0,200,200); step(0,0,0,0);
        step(0,1,0,0); step(0,1,0,255); step(0,1,255,0);    // boundaries
        step(0,1,255,255); step(0,1,255,255); step(0,1,1,1);
        step(1,0,9,9); step(0,1,2,3); step(0,0,0,0); step(0,0,0,0);
        for (i = 0; i < 1000; i = i + 1)
            step(($random % 50) == 0, $random, $random, $random);
        step(0,0,0,0); step(0,0,0,0); step(0,0,0,0);
        $display("TEST SUMMARY: %0d checks, %0d PASS, %0d FAIL", checks, checks - fails, fails);
        if (fails == 0) $display("ALL TESTS PASSED"); else $display("TESTS FAILED");
        $finish;
    end
endmodule
