`timescale 1ns/1ps

module mac8_tb;
    initial begin
        $dumpfile("mac8_tb.vcd");
        $dumpvars(0, mac8_tb);
    end

    reg         clk, reset, enable;
    reg  [7:0]  A, B;
    wire [19:0] Y;

    integer pass_count, fail_count, check_count;
    reg [19:0] golden_Y;

    mac8 dut (
        .clk(clk), .reset(reset), .enable(enable),
        .A(A), .B(B), .Y(Y)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (reset)
            golden_Y <= 20'd0;
        else if (enable)
            golden_Y <= golden_Y + (A * B);
    end

    task check_result;
        begin
            check_count = check_count + 1;
            if (Y !== golden_Y) begin
                fail_count = fail_count + 1;
                $display("[FAIL] time=%0t A=%0d B=%0d DUT_Y=%0d EXPECTED_Y=%0d",
                          $time, A, B, Y, golden_Y);
            end else
                pass_count = pass_count + 1;
        end
    endtask

    task do_cycle(input r, input e, input [7:0] a, input [7:0] b);
        begin
            @(negedge clk);
            reset = r; enable = e; A = a; B = b;
            @(posedge clk);
            #1;
            check_result;
        end
    endtask

    integer i;
    reg [7:0] ra, rb;
    reg re, rr;

    initial begin
        pass_count = 0; fail_count = 0; check_count = 0;
        reset = 1; enable = 0; A = 0; B = 0; golden_Y = 0;

        // (a) reset
        do_cycle(1, 0, 0,   0);
        do_cycle(1, 1, 12,  34);   // reset must dominate even if enable=1

        // (b) accumulation
        do_cycle(0, 1, 3,   4);
        do_cycle(0, 1, 5,   6);
        do_cycle(0, 1, 10,  10);
        do_cycle(0, 1, 7,   8);

        // (c) hold
        do_cycle(0, 0, 99,  99);
        do_cycle(0, 0, 1,   1);
        do_cycle(0, 1, 2,   2);    // resume accumulation

        // (d) various A,B combinations
        do_cycle(1, 0, 0,   0);
        do_cycle(0, 1, 13,  17);
        do_cycle(0, 1, 200, 3);
        do_cycle(0, 1, 45,  67);
        do_cycle(0, 1, 128, 128);
        do_cycle(0, 0, 1,   1);    // hold in the middle
        do_cycle(0, 1, 99,  101);

        // (e) boundary cases
        do_cycle(1, 0, 0,   0);
        do_cycle(0, 1, 0,   0);
        do_cycle(0, 1, 0,   255);
        do_cycle(0, 1, 255, 0);
        do_cycle(0, 1, 255, 255);
        do_cycle(0, 1, 255, 255);
        do_cycle(0, 1, 255, 255);

        // (f) 1000+ randomized cases
        do_cycle(1, 0, 0, 0);
        for (i = 0; i < 1000; i = i + 1) begin
            ra = $random; rb = $random;
            re = $random % 2;
            rr = ((i % 137) == 0) ? 1'b1 : 1'b0;
            do_cycle(rr, re, ra, rb);
        end

        $display("TEST SUMMARY: %0d checks, %0d PASS, %0d FAIL", check_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: %0d TEST(S) FAILED", fail_count);
        $finish;
    end

endmodule


