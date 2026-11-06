module mac8_pipelined3 (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [7:0]  A,
    input  wire [7:0]  B,
    output reg  [19:0] Y
);

    // ---- Stage 1: multiply ----
    reg  [15:0] product_reg;
    reg         en1;
    wire [15:0] product = A * B;

    always @(posedge clk) begin
        if (reset) begin
            product_reg <= 16'd0;
            en1         <= 1'b0;
        end else begin
            product_reg <= product;
            en1         <= enable;
        end
    end

    // ---- Stage 2: carry-save accumulate -- O(1) delay, NO ripple ----
    reg  [19:0] S, C;   // true accumulator value = S + C (redundant form)
    wire [19:0] X = {4'b0, product_reg};

    wire [19:0] S_next;
    wire [19:0] C_next;

    genvar i;
    generate
        for (i = 0; i < 20; i = i + 1) begin : csa_gen
            assign S_next[i] = S[i] ^ C[i] ^ X[i];
            if (i == 0)
                assign C_next[i] = 1'b0;
            else
                assign C_next[i] = (S[i-1] & C[i-1]) | (S[i-1] & X[i-1]) | (C[i-1] & X[i-1]);
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            S <= 20'd0;
            C <= 20'd0;
        end else if (en1) begin
            S <= S_next;
            C <= C_next;
        end
        // else: hold S, C unchanged (no new term this cycle)
    end

    // ---- Stage 3: resolve true binary value -- feed-forward only, never loops back ----
    always @(posedge clk) begin
        if (reset)
            Y <= 20'd0;
        else
            Y <= S + C;   // one real carry-propagate add, but it does NOT feed the next accumulation
    end

endmodule

