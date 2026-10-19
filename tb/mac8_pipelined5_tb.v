`timescale 1ns/1ps

module mac8_pipelined5_tb;

    reg         clk, reset, enable;
    reg  [7:0]  A, B;
    wire [19:0] Y;

    integer pass_count, fail_count, check_count, i;

    mac8_pipelined5 dut (
        .clk(clk), .reset(reset), .enable(enable),
        .A(A), .B(B), .Y(Y)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Golden model: mirrors all 5 stages exactly ----
    reg  [15:0] g_product_reg;
    reg         g_en1;
    reg  [19:0] g_S, g_C;
    wire [19:0] g_X = {4'b0, g_product_reg};
    reg  [19:0] g_S_next, g_C_next;
    integer     k;

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

    reg  [9:0] g_sum_lo_reg;
    reg        g_carry_mid;
    reg  [9:0] g_S_hi_reg, g_C_hi_reg;

    always @(posedge clk) begin
        if (reset) begin
            g_sum_lo_reg <= 10'd0;
            g_carry_mid  <= 1'b0;
            g_S_hi_reg   <= 10'd0;
            g_C_hi_reg   <= 10'd0;
        end else begin
            {g_carry_mid, g_sum_lo_reg} <= g_S[9:0] + g_C[9:0];
            g_S_hi_reg <= g_S[19:10];
            g_C_hi_reg <= g_C[19:10];
        end
    end

    reg  [4:0] g_sum_mid_reg;
    reg        g_carry_hi;
    reg  [4:0] g_S_hi2_reg, g_C_hi2_reg;
    reg  [9:0] g_sum_lo_reg2;

    always @(posedge clk) begin
        if (reset) begin
            g_sum_mid_reg <= 5'd0;
            g_carry_hi    <= 1'b0;
            g_S_hi2_reg   <= 5'd0;
            g_C_hi2_reg   <= 5'd0;
            g_sum_lo_reg2 <= 10'd0;
        end else begin
            {g_carry_hi, g_sum_mid_reg} <= g_S_hi_reg[4:0] + g_C_hi_reg[4:0] + g_carry_mid;
            g_S_hi2_reg   <= g_S_hi_reg[9:5];
            g_C_hi2_reg   <= g_C_hi_reg[9:5];
            g_sum_lo_reg2 <= g_sum_lo_reg;
        end
    end

    reg [19:0] g_Y;
    always @(posedge clk) begin
        if (reset)
            g_Y <= 20'd0;
        else
            g_Y <= {(g_S_hi2_reg + g_C_hi2_reg + g_carry_hi), g_sum_mid_reg, g_sum_lo_reg2};
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
        g_product_reg = 0; g_en1 = 0; g_S = 0; g_C = 0;
        g_sum_lo_reg = 0; g_carry_mid = 0; g_S_hi_reg = 0; g_C_hi_reg = 0;
        g_sum_mid_reg = 0; g_carry_hi = 0; g_S_hi2_reg = 0; g_C_hi2_reg = 0;
        g_sum_lo_reg2 = 0; g_Y = 0;

        do_cycle(1,0,0,0);
        do_cycle(1,1,12,34);
        do_cycle(0,1,3,4);
        do_cycle(0,1,5,6);
        do_cycle(0,0,99,99);
        do_cycle(0,1,255,255);
        do_cycle(0,1,255,255);
        do_cycle(0,1,255,255);
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

