`timescale 1ns/1ps

module mac8_pipelined3_tb;

    reg         clk, reset, enable;
    reg  [7:0]  A, B;
    wire [19:0] Y;

    integer pass_count, fail_count, check_count, i;

    mac8_pipelined3 dut (
        .clk(clk), .reset(reset), .enable(enable),
        .A(A), .B(B), .Y(Y)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Golden model: mirrors the SAME 3-stage carry-save structure ----
    reg  [15:0] g_product_reg;
    reg         g_en1;
    reg  [19:0] g_S, g_C;
    reg  [19:0] g_Y;

    wire [19:0] g_X = {4'b0, g_product_reg};
    integer     k;
    reg  [19:0] g_S_next, g_C_next;

    always @(*) begin
        g_S_next[0] = g_S[0] ^ g_C[0] ^ g_X[0];
        g_C_next[0] = 1'b0;
        for (k = 1; k < 20; k = k + 1) begin
            g_S_next[k] = g_S[k] ^ g_C[k] ^ g_X[k];
            g_C_next[k] = (g_S[k-1] & g_C[k-1]) | (g_S[k-1] & g_X[k-1]) | (g_C[k-1] & g_X[k-1]);
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            g_product_reg <= 16'd0;
            g_en1         <= 1'b0;
        end else begin
            g_product_reg <= A * B;
            g_en1         <= enable;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            g_S <= 20'd0;
            g_C <= 20'd0;
        end else if (g_en1) begin
            g_S <= g_S_next;
            g_C <= g_C_next;
        end
    end

    always @(posedge clk) begin
        if (reset)
            g_Y <= 20'd0;
        else
            g_Y <= g_S + g_C;
    end

    task check_result;
        begin
            check_count = check_count + 1;
            if (Y !== g_Y) begin
                fail_count = fail_count + 1;
                $display("[FAIL] time=%0t DUT_Y=%0d EXPECTED_Y=%0d", $time, Y, g_Y);
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

    reg [7:0] ra, rb;
    reg re, rr;

    initial begin
        pass_count = 0; fail_count = 0; check_count = 0;
        reset = 1; enable = 0; A = 0; B = 0;
        g_product_reg = 0; g_en1 = 0; g_S = 0; g_C = 0; g_Y = 0;

        do_cycle(1,0,0,0);
        do_cycle(1,1,12,34);
        do_cycle(0,1,3,4);
        do_cycle(0,1,5,6);
        do_cycle(0,0,99,99);
        do_cycle(0,1,255,255);
        do_cycle(0,1,255,255);
        do_cycle(0,1,255,255);   // three in a row -- stresses carry-save width
        do_cycle(1,0,0,0);

        for (i = 0; i < 1000; i = i + 1) begin
            ra = $random; rb = $random;
            re = $random % 2;
            rr = ((i % 151) == 0) ? 1'b1 : 1'b0;
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
