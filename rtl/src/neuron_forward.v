module neuron_forward #(
    parameter ACC_SHIFT = 10 //empirically found for exp 1
)(
    input  wire               clk,
    input  wire               rstn,

    input  wire               clear,
    input  wire               enable,

    input  wire        [7:0]  pixel,
    input  wire signed [7:0]  weight,
    output wire signed [31:0] accumulator,
    output reg  signed [8:0]  plan_input,
    output wire        [5:0]  activation
);
    wire signed [31:0] scaled_accumulator;

    neuron_mac mac_inst (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight),
        .accumulator(accumulator)
    );

    //accumulator scaling >>> for signed shift
    assign scaled_accumulator = accumulator >>> ACC_SHIFT; 

    //saturation to signed 9-bit PLAN range
    always @(*) begin
        if (scaled_accumulator > 32'sd255) begin
            plan_input = 9'sd255;
        end
        else if (scaled_accumulator < -32'sd256) begin
            plan_input = 9'sb100000000; 
        end
        else begin
            plan_input = scaled_accumulator[8:0];
        end
    end

    //combinational plan fire
    plan plan_inst (
        .a(plan_input),
        .y(activation) //output final of 1 neuron
    );
endmodule