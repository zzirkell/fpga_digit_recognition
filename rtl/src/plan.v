module plan (
    input  wire signed [8:0] a,
    output reg         [5:0] y
);
    reg [8:0] abs_a;
    reg [5:0] positive_result;

    always @(*) begin

        //absolute value of a
        if (a[8] == 1'b1) begin
            abs_a = (~a) + 1'b1;
        end
        else begin
            abs_a = a;
        end

        //positive plan
        if (abs_a >= 9'd160) begin
            positive_result = 6'd32;
        end
        else if (abs_a >= 9'd76) begin
            positive_result = (abs_a >> 5) + 6'd27;
        end
        else if (abs_a >= 9'd32) begin
            positive_result = (abs_a >> 3) + 6'd20;
        end
        else begin
            positive_result = (abs_a >> 2) + 6'd16;
        end


        //handle negative a
        if (a[8] == 1'b1) begin
            y = 6'd32 - positive_result;
        end
        else begin
            y = positive_result;
        end
    end
endmodule