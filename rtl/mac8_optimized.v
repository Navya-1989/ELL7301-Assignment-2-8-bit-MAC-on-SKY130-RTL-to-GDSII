module mac8_optimized (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [7:0]  A,
    input  wire [7:0]  B,
    output reg  [19:0] Y
);

    // ---- Stage 1a: split multiply into two smaller partial products ----
    reg  [11:0] p_lo_reg, p_hi_reg;
    reg         en1a;
    wire [11:0] p_lo = A[3:0] * B;   // 4x8 -> 12 bit
    wire [11:0] p_hi = A[7:4] * B;   // 4x8 -> 12 bit

    always @(posedge clk) begin
        if (reset) begin
            p_lo_reg <= 12'd0;
            p_hi_reg <= 12'd0;
            en1a     <= 1'b0;
        end else begin
            p_lo_reg <= p_lo;
            p_hi_reg <= p_hi;
            en1a     <= enable;
        end
    end

    // ---- Stage 1b: combine partial products into full 16-bit product ----
    reg  [15:0] product_reg;
    reg         en1;
    wire [15:0] product = {4'b0, p_lo_reg} + {p_hi_reg, 4'b0};

    always @(posedge clk) begin
        if (reset) begin
            product_reg <= 16'd0;
            en1         <= 1'b0;
        end else begin
            product_reg <= product;
            en1         <= en1a;
        end
    end

    // ---- Stage 2: single-cycle carry-select accumulate ----
    // Replaces carry-save entirely: ONE 20-bit register, no resolve stage.
    // 20-bit add split into five 4-bit blocks. Each block computes its
    // sum assuming cin=0 AND assuming cin=1 in parallel (two small fast
    // adders), then selects the right answer once the real carry-in
    // from the previous block is known. This is much faster than one
    // continuous 20-bit ripple, without ever duplicating the accumulator.
    wire [19:0] X = {4'b0, product_reg};
    wire [19:0] cs_sum;
    wire        cs_cout;

    genvar g;
    generate
        wire [4:0] block_carry;
        assign block_carry[0] = 1'b0;
        for (g = 0; g < 5; g = g + 1) begin : csa_block
            wire [3:0] a4 = Y[g*4 +: 4];
            wire [3:0] b4 = X[g*4 +: 4];
            wire [4:0] sum_cin0 = {1'b0, a4} + {1'b0, b4} + 5'd0;
            wire [4:0] sum_cin1 = {1'b0, a4} + {1'b0, b4} + 5'd1;
            assign cs_sum[g*4 +: 4]  = block_carry[g] ? sum_cin1[3:0] : sum_cin0[3:0];
            if (g < 4)
                assign block_carry[g+1] = block_carry[g] ? sum_cin1[4] : sum_cin0[4];
            else
                assign cs_cout = block_carry[g] ? sum_cin1[4] : sum_cin0[4];
        end
    endgenerate

    always @(posedge clk) begin
        if (reset)
            Y <= 20'd0;
        else if (en1)
            Y <= cs_sum;    // cs_cout intentionally dropped: natural 20-bit wraparound
    end

endmodule
