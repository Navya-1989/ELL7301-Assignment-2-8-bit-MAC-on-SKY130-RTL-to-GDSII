// 8-bit MAC, 2-stage pipeline: partial products registered, 3:2 compressor + carry-select accumulate.
// Stage 1: p_lo <= A[3:0]*B, p_hi <= A[7:4]*B (registered), en1 <= enable
// Stage 2: Y <= Y + p_lo + (p_hi << 4) when en1, via a 3:2 compressor then a 20-bit
//          carry-select adder (five 4-bit blocks). No separate product register.
// Latency: 2 cycles from A,B,enable to Y. Throughput: one result per cycle.
module mac8_opt3 (
    input         clk,
    input         reset,
    input         enable,
    input  [7:0]  A,
    input  [7:0]  B,
    output reg [19:0] Y
);
    reg [11:0] p_lo, p_hi;
    reg        en1;

    always @(posedge clk) begin
        if (reset) begin
            p_lo <= 12'd0;
            p_hi <= 12'd0;
            en1  <= 1'b0;
        end else begin
            p_lo <= A[3:0] * B;
            p_hi <= A[7:4] * B;
            en1  <= enable;
        end
    end

    // 3:2 compressor on Y, p_lo and (p_hi << 4)
    wire [19:0] x = {8'b0, p_lo};
    wire [19:0] z = {4'b0, p_hi, 4'b0};
    wire [19:0] csum = Y ^ x ^ z;
    // carry-select adder for csum + carry vector (carry vector shifted left by 1)
    wire [19:0] maj = (Y & x) | (Y & z) | (x & z);
    wire [19:0] cvec = {maj[18:0], 1'b0};

    wire [4:0]  s0 [0:4];
    wire [4:0]  s1 [0:4];
    wire [4:0]  carry;
    wire [19:0] cs_sum;
    assign carry[0] = 1'b0;

    genvar g;
    generate
        for (g = 0; g < 5; g = g + 1) begin : blk
            assign s0[g] = csum[4*g +: 4] + cvec[4*g +: 4];
            assign s1[g] = csum[4*g +: 4] + cvec[4*g +: 4] + 5'd1;
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
