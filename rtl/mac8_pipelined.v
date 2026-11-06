module mac8_pipelined (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [7:0]  A,
    input  wire [7:0]  B,
    output reg  [19:0] Y
);
    // ---- Stage 1: multiply ----
    reg  [15:0] product_reg;
    reg         enable_stage2;
    wire [15:0] product = A * B;

    always @(posedge clk) begin
        if (reset) begin
            product_reg   <= 16'd0;
            enable_stage2 <= 1'b0;
        end else begin
            product_reg   <= product;
            enable_stage2 <= enable;
        end
    end

    // ---- Stage 2: accumulate (plain ripple-carry add) ----
    always @(posedge clk) begin
        if (reset)
            Y <= 20'd0;
        else if (enable_stage2)
            Y <= Y + {4'b0, product_reg};
        else
            Y <= Y;
    end
endmodule
