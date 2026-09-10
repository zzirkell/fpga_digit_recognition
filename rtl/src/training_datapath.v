module training_datapath #(
    parameter TRAIN_SHIFT = 18
)(
    input wire [3:0] label,

    input wire [5:0] activation0,
    input wire [5:0] activation1,
    input wire [5:0] activation2,
    input wire [5:0] activation3,
    input wire [5:0] activation4,
    input wire [5:0] activation5,
    input wire [5:0] activation6,
    input wire [5:0] activation7,
    input wire [5:0] activation8,
    input wire [5:0] activation9,

    input wire [7:0] pixel,

    input wire signed [7:0] old_weight0,
    input wire signed [7:0] old_weight1,
    input wire signed [7:0] old_weight2,
    input wire signed [7:0] old_weight3,
    input wire signed [7:0] old_weight4,
    input wire signed [7:0] old_weight5,
    input wire signed [7:0] old_weight6,
    input wire signed [7:0] old_weight7,
    input wire signed [7:0] old_weight8,
    input wire signed [7:0] old_weight9,

    output wire signed [7:0] new_weight0,
    output wire signed [7:0] new_weight1,
    output wire signed [7:0] new_weight2,
    output wire signed [7:0] new_weight3,
    output wire signed [7:0] new_weight4,
    output wire signed [7:0] new_weight5,
    output wire signed [7:0] new_weight6,
    output wire signed [7:0] new_weight7,
    output wire signed [7:0] new_weight8,
    output wire signed [7:0] new_weight9
);

    //TARGET VECTOR 0...32
    wire [5:0] target0;
    wire [5:0] target1;
    wire [5:0] target2;
    wire [5:0] target3;
    wire [5:0] target4;
    wire [5:0] target5;
    wire [5:0] target6;
    wire [5:0] target7;
    wire [5:0] target8;
    wire [5:0] target9;


    assign target0 = (label == 4'd0) ? 6'd32 : 6'd0;
    assign target1 = (label == 4'd1) ? 6'd32 : 6'd0;
    assign target2 = (label == 4'd2) ? 6'd32 : 6'd0;
    assign target3 = (label == 4'd3) ? 6'd32 : 6'd0;
    assign target4 = (label == 4'd4) ? 6'd32 : 6'd0;
    assign target5 = (label == 4'd5) ? 6'd32 : 6'd0;
    assign target6 = (label == 4'd6) ? 6'd32 : 6'd0;
    assign target7 = (label == 4'd7) ? 6'd32 : 6'd0;
    assign target8 = (label == 4'd8) ? 6'd32 : 6'd0;
    assign target9 = (label == 4'd9) ? 6'd32 : 6'd0;

    // correction = (target - activation)*activation*(32 - activation)
    wire signed [15:0] correction0;
    wire signed [15:0] correction1;
    wire signed [15:0] correction2;
    wire signed [15:0] correction3;
    wire signed [15:0] correction4;
    wire signed [15:0] correction5;
    wire signed [15:0] correction6;
    wire signed [15:0] correction7;
    wire signed [15:0] correction8;
    wire signed [15:0] correction9;

    backprop_neuron bp0 (
        .activation(activation0),
        .target(target0),
        .error(),
        .gradient(),
        .correction(correction0)
    );
    backprop_neuron bp1 (
        .activation(activation1),
        .target(target1),
        .error(),
        .gradient(),
        .correction(correction1)
    );
    backprop_neuron bp2 (
        .activation(activation2),
        .target(target2),
        .error(),
        .gradient(),
        .correction(correction2)
    );
    backprop_neuron bp3 (
        .activation(activation3),
        .target(target3),
        .error(),
        .gradient(),
        .correction(correction3)
    );
    backprop_neuron bp4 (
        .activation(activation4),
        .target(target4),
        .error(),
        .gradient(),
        .correction(correction4)
    );
    backprop_neuron bp5 (
        .activation(activation5),
        .target(target5),
        .error(),
        .gradient(),
        .correction(correction5)
    );
    backprop_neuron bp6 (
        .activation(activation6),
        .target(target6),
        .error(),
        .gradient(),
        .correction(correction6)
    );
    backprop_neuron bp7 (
        .activation(activation7),
        .target(target7),
        .error(),
        .gradient(),
        .correction(correction7)
    );
    backprop_neuron bp8 (
        .activation(activation8),
        .target(target8),
        .error(),
        .gradient(),
        .correction(correction8)
    );
    backprop_neuron bp9 (
        .activation(activation9),
        .target(target9),
        .error(),
        .gradient(),
        .correction(correction9)
    );



    //TEN WEIGHT UPDATES
    weight_update #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) update0 (
        .correction(correction0),
        .pixel(pixel),
        .old_weight(old_weight0),
        .raw_delta(),
        .delta_weight(),
        .new_weight(new_weight0)
    );
    weight_update #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) update1 (
        .correction(correction1),
        .pixel(pixel),
        .old_weight(old_weight1),
        .raw_delta(),
        .delta_weight(),
        .new_weight(new_weight1)
    );
    weight_update #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) update2 (
        .correction(correction2),
        .pixel(pixel),
        .old_weight(old_weight2),
        .raw_delta(),
        .delta_weight(),
        .new_weight(new_weight2)
    );
    weight_update #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) update3 (
        .correction(correction3),
        .pixel(pixel),
        .old_weight(old_weight3),
        .raw_delta(),
        .delta_weight(),
        .new_weight(new_weight3)
    );
    weight_update #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) update4 (
        .correction(correction4),
        .pixel(pixel),
        .old_weight(old_weight4),
        .raw_delta(),
        .delta_weight(),
        .new_weight(new_weight4)
    );
    weight_update #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) update5 (
        .correction(correction5),
        .pixel(pixel),
        .old_weight(old_weight5),
        .raw_delta(),
        .delta_weight(),
        .new_weight(new_weight5)
    );
    weight_update #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) update6 (
        .correction(correction6),
        .pixel(pixel),
        .old_weight(old_weight6),
        .raw_delta(),
        .delta_weight(),
        .new_weight(new_weight6)
    );
    weight_update #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) update7 (
        .correction(correction7),
        .pixel(pixel),
        .old_weight(old_weight7),
        .raw_delta(),
        .delta_weight(),
        .new_weight(new_weight7)
    );
    weight_update #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) update8 (
        .correction(correction8),
        .pixel(pixel),
        .old_weight(old_weight8),
        .raw_delta(),
        .delta_weight(),
        .new_weight(new_weight8)
    );
    weight_update #(
        .TRAIN_SHIFT(TRAIN_SHIFT)
    ) update9 (
        .correction(correction9),
        .pixel(pixel),
        .old_weight(old_weight9),
        .raw_delta(),
        .delta_weight(),
        .new_weight(new_weight9)
    );

endmodule