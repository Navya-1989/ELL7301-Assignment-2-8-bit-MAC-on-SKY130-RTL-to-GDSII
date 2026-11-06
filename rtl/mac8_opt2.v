// 8-bit MAC, 2-stage pipeline, carry-select accumulator.
// Stage 1: product_reg <= A*B (registered), en1 <= enable
// Stage 2: Y <= Y + product_reg when en1 (20-bit carry-select, five 4-bit blocks)
// Latency: 2 cycles from A,B,enable to Y. Throughput: one result per cycle.
module mac8_opt2 (
    input         clk,
    input         reset,
    input         enable,
    input  [7:0]  A,
    input  [7:0]  B,
    output reg [19:0] Y
);
    reg [15:0] product_reg;
    reg        en1;

    always @(posedge clk) begin
        if (reset) begin
            product_reg <= 16'd0;
            en1         <= 1'b0;
        end else begin
            product_reg <= A * B;
            en1         <= enable;
        end
    end

    wire [19:0] X = {4'b0, product_reg};

    // carry-select: per block compute sum for carry-in 0 and 1, pick by incoming carry
    wire [4:0]  s0 [0:4];
    wire [4:0]  s1 [0:4];
    wire [4:0]  carry;          // carry[g] = carry into block g
    wire [19:0] cs_sum;

    assign carry[0] = 1'b0;

    genvar g;
    generate
        for (g = 0; g < 5; g = g + 1) begin : blk
            assign s0[g] = Y[4*g +: 4] + X[4*g +: 4];
            assign s1[g] = Y[4*g +: 4] + X[4*g +: 4] + 5'd1;
            assign cs_sum[4*g +: 4] = carry[g] ? s1[g][3:0] : s0[g][3:0];
            if (g < 4) begin : nxt
                assign carry[g+1] = carry[g] ? s1[g][4] : s0[g][4];
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (reset)    Y <= 20'd0;
        else if (en1) Y <= cs_sum;
    end
endmodule
