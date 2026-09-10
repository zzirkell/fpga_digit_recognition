module backprop_neuron (
    input wire [5:0] activation, //0...32
    input wire [5:0] target, //0...32
    output wire signed [6:0] error, //7th bit to fit 32
    output wire [8:0] gradient, //16*16 = 256
    output wire signed [15:0] correction //32 × 256 = 8192
);

    wire signed [6:0] activation_signed;
    wire signed [6:0] target_signed;
    wire [5:0] activation_inverse;
    wire [8:0] activation_extended;
    wire [8:0] inverse_extended;
    wire signed [9:0] error_extended;
    wire signed [9:0] gradient_signed;
    wire signed [19:0] correction_full;

    assign activation_signed = {1'b0, activation};
    assign target_signed = {1'b0, target};
    //error = target - activation
    assign error = target_signed - activation_signed;
    //gradient = activation * (32 - activation)
    assign activation_inverse = 6'd32 - activation;
    assign activation_extended = {3'b000, activation};
    assign inverse_extended = {3'b000, activation_inverse};
    assign gradient = activation_extended * inverse_extended;
    //correction = error * gradient
    assign error_extended = {{3{error[6]}}, error};
    assign gradient_signed = {1'b0, gradient};
    assign correction_full = error_extended * gradient_signed;
    assign correction = correction_full[15:0];

endmodule