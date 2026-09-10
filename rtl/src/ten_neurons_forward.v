module ten_neurons_forward #(
    parameter ACC_SHIFT = 11
)(
    input  wire               clk,
    input  wire               rstn,

    input  wire               clear,
    input  wire               enable,

    //same image pixel goes to all 10 neurons.
    input  wire        [7:0]  pixel,

    //one weight for each neuron.
    input  wire signed [7:0]  weight0,
    input  wire signed [7:0]  weight1,
    input  wire signed [7:0]  weight2,
    input  wire signed [7:0]  weight3,
    input  wire signed [7:0]  weight4,
    input  wire signed [7:0]  weight5,
    input  wire signed [7:0]  weight6,
    input  wire signed [7:0]  weight7,
    input  wire signed [7:0]  weight8,
    input  wire signed [7:0]  weight9,

    //accumulators are exposed for debugging
    output wire signed [31:0] accumulator0,
    output wire signed [31:0] accumulator1,
    output wire signed [31:0] accumulator2,
    output wire signed [31:0] accumulator3,
    output wire signed [31:0] accumulator4,
    output wire signed [31:0] accumulator5,
    output wire signed [31:0] accumulator6,
    output wire signed [31:0] accumulator7,
    output wire signed [31:0] accumulator8,
    output wire signed [31:0] accumulator9,

    //final PLAN outputs.
    output wire        [5:0]  activation0,
    output wire        [5:0]  activation1,
    output wire        [5:0]  activation2,
    output wire        [5:0]  activation3,
    output wire        [5:0]  activation4,
    output wire        [5:0]  activation5,
    output wire        [5:0]  activation6,
    output wire        [5:0]  activation7,
    output wire        [5:0]  activation8,
    output wire        [5:0]  activation9
);


    //PLAN inputs are internal here (debug_only)
    wire signed [8:0] plan_input0;
    wire signed [8:0] plan_input1;
    wire signed [8:0] plan_input2;
    wire signed [8:0] plan_input3;
    wire signed [8:0] plan_input4;
    wire signed [8:0] plan_input5;
    wire signed [8:0] plan_input6;
    wire signed [8:0] plan_input7;
    wire signed [8:0] plan_input8;
    wire signed [8:0] plan_input9;


    //0
    neuron_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neuron0 (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight0),
        .accumulator(accumulator0),
        .plan_input(plan_input0),
        .activation(activation0)
    );

    //1
    neuron_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neuron1 (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight1),
        .accumulator(accumulator1),
        .plan_input(plan_input1),
        .activation(activation1)
    );


    //2
    neuron_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neuron2 (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight2),
        .accumulator(accumulator2),
        .plan_input(plan_input2),
        .activation(activation2)
    );


    //3
    neuron_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neuron3 (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight3),
        .accumulator(accumulator3),
        .plan_input(plan_input3),
        .activation(activation3)
    );


    //4
    neuron_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neuron4 (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight4),
        .accumulator(accumulator4),
        .plan_input(plan_input4),
        .activation(activation4)
    );


    //5
    neuron_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neuron5 (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight5),
        .accumulator(accumulator5),
        .plan_input(plan_input5),
        .activation(activation5)
    );


    //6
    neuron_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neuron6 (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight6),
        .accumulator(accumulator6),
        .plan_input(plan_input6),
        .activation(activation6)
    );


    //7
    neuron_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neuron7 (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight7),
        .accumulator(accumulator7),
        .plan_input(plan_input7),
        .activation(activation7)
    );


    //8
    neuron_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neuron8 (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight8),
        .accumulator(accumulator8),
        .plan_input(plan_input8),
        .activation(activation8)
    );


    //9
    neuron_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neuron9 (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight9),
        .accumulator(accumulator9),
        .plan_input(plan_input9),
        .activation(activation9)
    );
endmodule