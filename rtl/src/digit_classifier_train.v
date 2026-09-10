module digit_classifier_train #(
    parameter ACC_SHIFT = 11,
    parameter TRAIN_SHIFT = 18,
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
    input wire [3:0] label,
    output wire done,
    output wire [3:0] prediction,
    output wire [9:0] memory_address
);

    //controller signals

    wire clear;
    wire forward_enable;
    wire weight_write_enable;
    wire [9:0] write_address;

    training_controller controller_inst (
        .clk(clk),
        .rstn(rstn),
        .start(start),
        .clear(clear),
        .forward_enable(forward_enable),
        .weight_write_enable(weight_write_enable),
        .done(done),
        .read_address(memory_address),
        .write_address(write_address)
    );

    //rem the label to a register for the training datapath
    reg [3:0] label_reg;

    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            label_reg <= 4'd0;
        else if (start)
            label_reg <= label;
    end

    //im memory
    wire [7:0] pixel;
    image_memory #(
        .INIT_FILE(IMAGE_FILE)
    ) image_memory_inst (
        .clk(clk),
        .address(memory_address),
        .pixel(pixel)
    );

    //current 10 weights
    wire signed [7:0] weight0, weight1, weight2, weight3, weight4;
    wire signed [7:0] weight5, weight6, weight7, weight8, weight9;
    //new weights after training
    wire signed [7:0] new_weight0, new_weight1, new_weight2, new_weight3, new_weight4;
    wire signed [7:0] new_weight5, new_weight6, new_weight7, new_weight8, new_weight9;

    //weight bank
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
        .read_address(memory_address),
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
        .write_address(write_address),
        .write_enable0(weight_write_enable),
        .write_enable1(weight_write_enable),
        .write_enable2(weight_write_enable),
        .write_enable3(weight_write_enable),
        .write_enable4(weight_write_enable),
        .write_enable5(weight_write_enable),
        .write_enable6(weight_write_enable),
        .write_enable7(weight_write_enable),
        .write_enable8(weight_write_enable),
        .write_enable9(weight_write_enable),
        .weight_in0(new_weight0),
        .weight_in1(new_weight1),
        .weight_in2(new_weight2),
        .weight_in3(new_weight3),
        .weight_in4(new_weight4),
        .weight_in5(new_weight5),
        .weight_in6(new_weight6),
        .weight_in7(new_weight7),
        .weight_in8(new_weight8),
        .weight_in9(new_weight9)
    );

    //forward
    wire signed [31:0] accumulator0, accumulator1, accumulator2, accumulator3, accumulator4;
    wire signed [31:0] accumulator5, accumulator6, accumulator7, accumulator8, accumulator9;
    wire [5:0] activation0, activation1, activation2, activation3, activation4;
    wire [5:0] activation5, activation6, activation7, activation8, activation9;

    ten_neurons_forward #(
        .ACC_SHIFT(ACC_SHIFT)
    ) neurons_inst (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(forward_enable),
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

    //pred
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

    //training arifhmetic datapath
    training_datapath #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) training_datapath_inst (
        .label(label_reg),
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
        .pixel(pixel),
        .old_weight0(weight0),
        .old_weight1(weight1),
        .old_weight2(weight2),
        .old_weight3(weight3),
        .old_weight4(weight4),
        .old_weight5(weight5),
        .old_weight6(weight6),
        .old_weight7(weight7),
        .old_weight8(weight8),
        .old_weight9(weight9),
        .new_weight0(new_weight0),
        .new_weight1(new_weight1),
        .new_weight2(new_weight2),
        .new_weight3(new_weight3),
        .new_weight4(new_weight4),
        .new_weight5(new_weight5),
        .new_weight6(new_weight6),
        .new_weight7(new_weight7),
        .new_weight8(new_weight8),
        .new_weight9(new_weight9)
    );

endmodule