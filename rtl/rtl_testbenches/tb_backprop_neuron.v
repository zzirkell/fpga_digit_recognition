`timescale 1ns / 1ps

module tb_backprop_neuron;

    reg [5:0] activation;
    reg [5:0] target;
    wire signed [6:0] error;
    wire [8:0] gradient;
    wire signed [15:0] correction;
    integer errors;

    backprop_neuron dut (
        .activation(activation),
        .target(target),
        .error(error),
        .gradient(gradient),
        .correction(correction)
    );

    initial begin
        errors = 0;
        activation = 6'd16;
        target = 6'd32;
        #10;
        if (error !== 7'sd16 || gradient !== 9'd256 || correction !== 16'sd4096) begin
            $display("FAIL 1: error=%0d gradient=%0d correction=%0d", error, gradient, correction);
            errors = errors + 1;
        end
        else begin
            $display("PASS 1");
        end

        activation = 6'd16;
        target = 6'd0;
        #10;
        if (error !== -7'sd16 || gradient !== 9'd256 || correction !== -16'sd4096) begin
            $display("FAIL 2: error=%0d gradient=%0d correction=%0d", error, gradient, correction);
            errors = errors + 1;
        end
        else begin
            $display("PASS 2");
        end

        activation = 6'd32;
        target = 6'd32;
        #10;
        if (error !== 7'sd0 || gradient !== 9'd0 || correction !== 16'sd0) begin
            $display("FAIL 3");
            errors = errors + 1;
        end
        else begin
            $display("PASS 3");
        end

        activation = 6'd8;
        target = 6'd0;
        #10;
        if (error !== -7'sd8 || gradient !== 9'd192 || correction !== -16'sd1536) begin
            $display("FAIL 4: error=%0d gradient=%0d correction=%0d", error, gradient, correction);
            errors = errors + 1;
        end
        else begin
            $display("PASS 4");
        end

        $display("");

        if (errors == 0) begin
            $display("ALL BACKPROP NEURON TESTS PASSED");
        end
        else begin
            $display("%0d TESTS FAILED", errors);
        end

        $finish;
    end

endmodule