module digit_classifier_forward #(
    parameter ACC_SHIFT = 11, //empirically the best for experiment 2

    parameter IMAGE_FILE = "",

    parameter WEIGHT_FILE_0 = "",
    parameter WEIGHT_FILE_1 = "",
    parameter WEIGHT_FILE_2 = "",
    parameter WEIGHT_FILE_3 = "",
    parameter WEIGHT_FILE_4 = "",
    parameter WEIGHT_FILE_5 = "",
    parameter WEIGHT_FILE_6 = "",
    parameter WEIGHT_FILE_7 = "",
    parameter WEIGHT_FILE_8 = "",
    parameter WEIGHT_FILE_9 = ""
)(
    input wire clk,
    input wire rstn,
    input wire start,

    output wire       done,
    output wire [3:0] prediction,

    //debug output
    output wire [9:0] pixel_index
);


    //controller signals
    wire clear;
    wire enable;

    //current image pixel
    wire [7:0] pixel;

    //current weight: 1 for each neuron
    wire signed [7:0] weight0;
    wire signed [7:0] weight1;
    wire signed [7:0] weight2;
    wire signed [7:0] weight3;
    wire signed [7:0] weight4;
    wire signed [7:0] weight5;
    wire signed [7:0] weight6;
    wire signed [7:0] weight7;
    wire signed [7:0] weight8;
    wire signed [7:0] weight9;


    //neuron accumulators: 1 for each neuron
    wire signed [31:0] accumulator0;
    wire signed [31:0] accumulator1;
    wire signed [31:0] accumulator2;
    wire signed [31:0] accumulator3;
    wire signed [31:0] accumulator4;
    wire signed [31:0] accumulator5;
    wire signed [31:0] accumulator6;
    wire signed [31:0] accumulator7;
    wire signed [31:0] accumulator8;
    wire signed [31:0] accumulator9;


    //plan activations: 1 for each neuron
    wire [5:0] activation0;
    wire [5:0] activation1;
    wire [5:0] activation2;
    wire [5:0] activation3;
    wire [5:0] activation4;
    wire [5:0] activation5;
    wire [5:0] activation6;
    wire [5:0] activation7;
    wire [5:0] activation8;
    wire [5:0] activation9;


    //controller: manages the forward propagation process
    forward_controller controller_inst (
        .clk(clk),
        .rstn(rstn),
        .start(start),

        .clear(clear),
        .enable(enable),
        .done(done),

        .pixel_index(pixel_index)
    );

    //image memory: provides the current pixel to the neurons
    image_memory #(
        .INIT_FILE(IMAGE_FILE)
    ) image_memory_inst (
        .clk(clk),
        .address(pixel_index),
        .pixel(pixel)
    );


    //10 weight memories: one for each neuron, providing the current weight to the neurons
    weight_bank #(
        .INIT_FILE_0(WEIGHT_FILE_0),
        .INIT_FILE_1(WEIGHT_FILE_1),
        .INIT_FILE_2(WEIGHT_FILE_2),
        .INIT_FILE_3(WEIGHT_FILE_3),
        .INIT_FILE_4(WEIGHT_FILE_4),
        .INIT_FILE_5(WEIGHT_FILE_5),
        .INIT_FILE_6(WEIGHT_FILE_6),
        .INIT_FILE_7(WEIGHT_FILE_7),
        .INIT_FILE_8(WEIGHT_FILE_8),
        .INIT_FILE_9(WEIGHT_FILE_9)
    ) weight_bank_inst (
        .clk(clk),

        .read_address(pixel_index),

        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .weight4(weight4),
        .weight5(weight5),
        .weight6(weight6),
        .weight7(weight7),
        .weight8(weight8),
        .weight9(weight9),

        //no writing during forward
        .write_address(10'd0),

        .write_enable0(1'b0),
        .write_enable1(1'b0),
        .write_enable2(1'b0),
        .write_enable3(1'b0),
        .write_enable4(1'b0),
        .write_enable5(1'b0),
        .write_enable6(1'b0),
        .write_enable7(1'b0),
        .write_enable8(1'b0),
        .write_enable9(1'b0),

        .weight_in0(8'sd0),
        .weight_in1(8'sd0),
        .weight_in2(8'sd0),
        .weight_in3(8'sd0),
        .weight_in4(8'sd0),
        .weight_in5(8'sd0),
        .weight_in6(8'sd0),
        .weight_in7(8'sd0),
        .weight_in8(8'sd0),
        .weight_in9(8'sd0)
    );


    //10 neurons: each neuron receives the same pixel, but a different weight
    ten_neurons_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neurons_inst (
        .clk(clk),
        .rstn(rstn),

        .clear(clear),
        .enable(enable),

        .pixel(pixel),

        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .weight4(weight4),
        .weight5(weight5),
        .weight6(weight6),
        .weight7(weight7),
        .weight8(weight8),
        .weight9(weight9),

        .accumulator0(accumulator0),
        .accumulator1(accumulator1),
        .accumulator2(accumulator2),
        .accumulator3(accumulator3),
        .accumulator4(accumulator4),
        .accumulator5(accumulator5),
        .accumulator6(accumulator6),
        .accumulator7(accumulator7),
        .accumulator8(accumulator8),
        .accumulator9(accumulator9),

        .activation0(activation0),
        .activation1(activation1),
        .activation2(activation2),
        .activation3(activation3),
        .activation4(activation4),
        .activation5(activation5),
        .activation6(activation6),
        .activation7(activation7),
        .activation8(activation8),
        .activation9(activation9)
    );

    //argmax: takes the 10 activations and outputs the index of the max activation as the predicted digit
    argmax argmax_inst (
        .activation0(activation0),
        .activation1(activation1),
        .activation2(activation2),
        .activation3(activation3),
        .activation4(activation4),
        .activation5(activation5),
        .activation6(activation6),
        .activation7(activation7),
        .activation8(activation8),
        .activation9(activation9),

        .prediction(prediction)
    );

endmodule