module mac8_pipelined4 (
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

    // ---- Stage 2: carry-save accumulate -- O(1) delay, no ripple ----
    reg  [19:0] S, C;
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
    end

    // ---- Stage 3: resolve LOW 10 bits, register carry into high half ----
    reg  [9:0]  sum_lo_reg;
    reg         carry_mid;
    reg  [9:0]  S_hi_reg, C_hi_reg;

    always @(posedge clk) begin
        if (reset) begin
            sum_lo_reg <= 10'd0;
            carry_mid  <= 1'b0;
            S_hi_reg   <= 10'd0;
            C_hi_reg   <= 10'd0;
        end else begin
            {carry_mid, sum_lo_reg} <= S[9:0] + C[9:0];
            S_hi_reg <= S[19:10];
            C_hi_reg <= C[19:10];
        end
    end

    // ---- Stage 4: resolve HIGH 10 bits using the registered carry-in ----
    always @(posedge clk) begin
        if (reset)
            Y <= 20'd0;
        else
            Y <= {(S_hi_reg + C_hi_reg + carry_mid), sum_lo_reg};
    end

endmodule

