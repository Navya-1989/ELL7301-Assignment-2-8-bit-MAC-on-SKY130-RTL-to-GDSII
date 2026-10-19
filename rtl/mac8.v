module mac8 (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [7:0]  A,
    input  wire [7:0]  B,
    output reg  [19:0] Y
);

    wire [15:0] product;
    assign product = A * B;

    always @(posedge clk) begin
        if (reset)
            Y <= 20'd0;
        else if (enable)
            Y <= Y + {4'b0, product};
        else
            Y <= Y;
    end

endmodule

