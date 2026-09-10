module weight_update #(
    parameter TRAIN_SHIFT = 18
)(
    input wire signed [15:0] correction,
    input wire [7:0] pixel,
    input wire signed [7:0] old_weight,
    output wire signed [24:0] raw_delta,
    output wire signed [15:0] delta_weight,
    output reg signed [7:0] new_weight
);

    
    //extend operands before multiplication
    wire signed [24:0] correction_extended;
    wire signed [24:0] pixel_extended;

    assign correction_extended = {{9{correction[15]}}, correction};
    assign pixel_extended = {17'd0, pixel};

    //raw weight change
    //raw_delta = correction * pixel
    assign raw_delta = correction_extended * pixel_extended;


    // raw_delta >>> TRAIN_SHIFT
    // because for negative values arithmetic right shift rounds toward negative infinity.
    // abs(value) >> TRAIN_SHIFT

    wire [24:0] raw_magnitude;
    wire [24:0] shifted_magnitude;
    wire signed [15:0] shifted_magnitude_signed;
    assign raw_magnitude = raw_delta[24] ? (~raw_delta + 25'd1) : raw_delta;
    assign shifted_magnitude = raw_magnitude >> TRAIN_SHIFT;
    //the real delta is very small after >> 18, so 16 bits is more than sufficient.
    assign shifted_magnitude_signed = {1'b0, shifted_magnitude[14:0]};
    assign delta_weight = raw_delta[24] ? -shifted_magnitude_signed : shifted_magnitude_signed;

    //add delta to old weight
    wire signed [16:0] old_weight_extended;
    wire signed [16:0] delta_weight_extended;
    wire signed [16:0] updated_sum;

    assign old_weight_extended = {{9{old_weight[7]}}, old_weight};
    assign delta_weight_extended = {delta_weight[15], delta_weight};
    assign updated_sum = old_weight_extended + delta_weight_extended;

    //saturate -128 ... +127
    always @(*) begin
        if (updated_sum > 17'sd127)
            new_weight = 8'sd127;
        else if (updated_sum < -17'sd128) begin
            // 10000000 = -128 in signed 8-bit two's complement
            new_weight = 8'sh80;
        end
        else
            new_weight = updated_sum[7:0];
    end

endmodule