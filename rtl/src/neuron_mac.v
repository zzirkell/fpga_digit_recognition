module neuron_mac (
    input  wire               clk,
    input  wire               rstn,

    input  wire               clear, //after each image got precessed
    input  wire               enable, //enable summing up to accumulator
    input  wire        [7:0]  pixel, //
    input  wire signed [7:0]  weight,
    output reg signed [31:0]  accumulator
);
    wire signed [8:0] pixel_signed;
    wire signed [8:0] weight_signed;

    //9 x 9 multiplication may need 18 bit
    wire signed [17:0] product;
    //pixel is always positive: 0 ... 127.
    assign pixel_signed = {1'b0, pixel};
    //sign extend weight
    assign weight_signed = {weight[7], weight};

    //combinational part: multiplication
    assign product =pixel_signed * weight_signed;


    //synchron part: accumulator register
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            accumulator <= 32'sd0;
        end
        else if (clear) begin
            accumulator <= 32'sd0;
        end
        else if (enable) begin
            accumulator <= accumulator + product;
        end
    end
endmodule