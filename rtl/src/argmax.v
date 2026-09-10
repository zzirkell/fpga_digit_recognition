module argmax (
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

    output reg [3:0] prediction
);

    reg [5:0] max_activation;

    always @(*) begin
        //assume 0 winner (we do not have bias in the model)
        max_activation = activation0;
        prediction     = 4'd0;

        //1
        if (activation1 > max_activation) begin
            max_activation = activation1;
            prediction     = 4'd1;
        end

        //2
        if (activation2 > max_activation) begin
            max_activation = activation2;
            prediction     = 4'd2;
        end

        //3
        if (activation3 > max_activation) begin
            max_activation = activation3;
            prediction     = 4'd3;
        end

        //4
        if (activation4 > max_activation) begin
            max_activation = activation4;
            prediction     = 4'd4;
        end

        //5
        if (activation5 > max_activation) begin
            max_activation = activation5;
            prediction     = 4'd5;
        end

        //6
        if (activation6 > max_activation) begin
            max_activation = activation6;
            prediction     = 4'd6;
        end

        //7
        if (activation7 > max_activation) begin
            max_activation = activation7;
            prediction     = 4'd7;
        end

        //8
        if (activation8 > max_activation) begin
            max_activation = activation8;
            prediction     = 4'd8;
        end

        //9
        if (activation9 > max_activation) begin
            max_activation = activation9;
            prediction     = 4'd9;
        end
    end
endmodule