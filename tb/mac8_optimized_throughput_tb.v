`timescale 1ns/1ps

module mac8_optimized_throughput_tb;

    reg         clk, reset, enable;
    reg  [7:0]  A, B;
    wire [19:0] Y;

    mac8_optimized dut (
        .clk(clk), .reset(reset), .enable(enable),
        .A(A), .B(B), .Y(Y)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Golden model -- identical structure, used only to compute expected Y
    reg  [11:0] g_p_lo_reg, g_p_hi_reg;
    reg         g_en1a;
    reg  [15:0] g_product_reg;
    reg         g_en1;
    reg  [19:0] g_Y;

    always @(posedge clk) begin
        if (reset) begin
            g_p_lo_reg <= 12'd0; g_p_hi_reg <= 12'd0; g_en1a <= 1'b0;
        end else begin
            g_p_lo_reg <= A[3:0] * B;
            g_p_hi_reg <= A[7:4] * B;
            g_en1a     <= enable;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            g_product_reg <= 16'd0; g_en1 <= 1'b0;
        end else begin
            g_product_reg <= {4'b0, g_p_lo_reg} + {g_p_hi_reg, 4'b0};
            g_en1         <= g_en1a;
        end
    end

    always @(posedge clk) begin
        if (reset)
            g_Y <= 20'd0;
        else if (g_en1)
            g_Y <= g_Y + {4'b0, g_product_reg};
    end

    integer i;
    integer pass_count, fail_count, check_count;
    integer NUM_CYCLES;
    reg [7:0] a_hist [0:999];
    reg [7:0] b_hist [0:999];

    initial begin
        NUM_CYCLES = 500;
        pass_count = 0; fail_count = 0; check_count = 0;
        reset = 1; enable = 0; A = 0; B = 0;
        g_p_lo_reg=0; g_p_hi_reg=0; g_en1a=0; g_product_reg=0; g_en1=0; g_Y=0;

        @(negedge clk); reset = 0;

        // ---- THE ACTUAL THROUGHPUT TEST ----
        // enable = 1 on EVERY single cycle, no gaps, no stalls, for
        // NUM_CYCLES consecutive cycles -- if the pipeline needed even
        // one bubble anywhere, this would desynchronize DUT vs golden
        // model and show up as a mismatch.
        for (i = 0; i < NUM_CYCLES; i = i + 1) begin
            @(negedge clk);
            enable = 1;
            A = $random;
            B = $random;
            @(posedge clk);
            #1;
            check_count = check_count + 1;
            if (Y !== g_Y) begin
                fail_count = fail_count + 1;
                $display("[FAIL] cycle=%0d DUT_Y=%0d EXPECTED_Y=%0d", i, Y, g_Y);
            end else
                pass_count = pass_count + 1;
        end

        $display("THROUGHPUT TEST: %0d cycles, enable held HIGH every cycle, 0 bubbles inserted", NUM_CYCLES);
        $display("TEST SUMMARY: %0d checks, %0d PASS, %0d FAIL", check_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("RESULT: FULL THROUGHPUT CONFIRMED -- 1 new result accepted AND correctly accumulated every clock cycle");
        else
            $display("RESULT: THROUGHPUT FAILURE -- %0d mismatches, pipeline is NOT hazard-free at full rate", fail_count);
        $finish;
    end

endmodule
