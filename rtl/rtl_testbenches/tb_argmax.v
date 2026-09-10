`timescale 1ns / 1ps

module tb_argmax;

    reg [5:0] activation0;
    reg [5:0] activation1;
    reg [5:0] activation2;
    reg [5:0] activation3;
    reg [5:0] activation4;
    reg [5:0] activation5;
    reg [5:0] activation6;
    reg [5:0] activation7;
    reg [5:0] activation8;
    reg [5:0] activation9;

    wire [3:0] prediction;

    integer errors;

    argmax dut (
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


    initial begin
        errors = 0;


        //5
        activation0 = 6'd3;
        activation1 = 6'd5;
        activation2 = 6'd2;
        activation3 = 6'd7;
        activation4 = 6'd4;
        activation5 = 6'd26;
        activation6 = 6'd6;
        activation7 = 6'd2;
        activation8 = 6'd8;
        activation9 = 6'd3;

        #10;

        if (prediction !== 4'd5) begin
            $display(
                "FAIL test 1: expected 5, got %0d",
                prediction
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS test 1: prediction = 5"
            );
        end


        //9
        activation0 = 6'd1;
        activation1 = 6'd2;
        activation2 = 6'd3;
        activation3 = 6'd4;
        activation4 = 6'd5;
        activation5 = 6'd6;
        activation6 = 6'd7;
        activation7 = 6'd8;
        activation8 = 6'd9;
        activation9 = 6'd30;
        #10;
        if (prediction !== 4'd9) begin
            $display(
                "FAIL test 2: expected 9, got %0d",
                prediction
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS test 2: prediction = 9"
            );
        end


        //tie 2 6
        activation0 = 6'd4;
        activation1 = 6'd8;
        activation2 = 6'd30;
        activation3 = 6'd5;
        activation4 = 6'd10;
        activation5 = 6'd15;
        activation6 = 6'd6;
        activation7 = 6'd30;
        activation8 = 6'd7;
        activation9 = 6'd3;
        #10;
        if (prediction !== 4'd2) begin
            $display(
                "FAIL tie test: expected 2, got %0d",
                prediction
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS tie test: first maximum wins"
            );
        end


        //0
        activation0 = 6'd16;
        activation1 = 6'd16;
        activation2 = 6'd16;
        activation3 = 6'd16;
        activation4 = 6'd16;
        activation5 = 6'd16;
        activation6 = 6'd16;
        activation7 = 6'd16;
        activation8 = 6'd16;
        activation9 = 6'd16;
        #10;
        if (prediction !== 4'd0) begin
            $display(
                "FAIL equal test: expected 0, got %0d",
                prediction
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS equal test: prediction = 0"
            );
        end

        $display("");

        if (errors == 0) begin
            $display(
                "ALL ARGMAX TESTS PASSED"
            );
        end
        else begin
            $display(
                "%0d ARGMAX TESTS FAILED",
                errors
            );
        end
        $display("DONE");
        $finish;
    end
endmodule