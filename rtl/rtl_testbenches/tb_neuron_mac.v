`timescale 1ns / 1ps

module tb_neuron_mac;

    reg               clk;
    reg               rstn;
    reg               clear;
    reg               enable;

    reg        [7:0]  pixel;
    reg signed [7:0]  weight;

    wire signed [31:0] accumulator;
    reg signed [31:0] expected;

    integer errors;

    neuron_mac dut (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight),
        .accumulator(accumulator)
    );

    //period = 10 ns
    initial begin
        clk = 1'b0;
        forever begin
            #5 clk = ~clk;
        end
    end


    //apply 1 pixrl/weight pair
    task apply_term;
        input        [7:0] test_pixel;
        input signed [7:0] test_weight;
        input signed [31:0] expected_accumulator;

        begin
            @(negedge clk);
            pixel  = test_pixel;
            weight = test_weight;
            enable = 1'b1;
            @(posedge clk);
            #1;
            expected = expected_accumulator;
            if (accumulator !== expected_accumulator) begin
                $display(
                    "FAIL: pixel=%0d weight=%0d accumulator=%0d expected=%0d",
                    test_pixel,
                    test_weight,
                    accumulator,
                    expected_accumulator
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: pixel=%0d weight=%0d accumulator=%0d",
                    test_pixel,
                    test_weight,
                    accumulator
                );
            end
        end
    endtask


    //testing
    initial begin
        errors = 0;
        rstn   = 1'b0;
        clear  = 1'b0;
        enable = 1'b0;
        pixel  = 8'd0;
        weight = 8'sd0;


        //reset
        #12;
        rstn = 1'b1;

        //clear accumulator before new image
        @(negedge clk);
        clear = 1'b1;
        @(posedge clk);
        #1;
        clear = 1'b0;
        if (accumulator !== 32'sd0) begin
            $display(
                "FAIL: accumulator did not clear"
            );

            errors = errors + 1;
        end
        else begin
            $display(
                "PASS: accumulator cleared to 0"
            );
        end


        //10*3
        apply_term(
            8'd10,
            8'sd3,
            32'sd30
        );
        //20*-2
        apply_term(
            8'd20,
            -8'sd2,
            -32'sd10
        );
        //0*100
        apply_term(
            8'd0,
            8'sd100,
            -32'sd10
        );

        // 127 × (-128) = -16256
        // -10 + (-16256) = -16266
        apply_term(
            8'd127,
            -8'sd128,
            -32'sd16266
        );


        //disable
        @(negedge clk);
        enable =1'b0;
        pixel  = 8'd100;
        weight = 8'sd50;
        @(posedge clk);
        #1;

        if (accumulator !== -32'sd16266) begin
            $display(
                "FAIL: accumulator changed while enable=0"
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS: enable=0 holds accumulator"
            );
        end


        //clear again
        @(negedge clk);
        clear = 1'b1;
        @(posedge clk);
        #1;
        clear = 1'b0;

        if (accumulator !== 32'sd0) begin
            $display(
                "FAIL: second clear failed"
            );
            errors = errors + 1;
        end
        else begin
            $display("PASS: second clear returned accumulator to 0");
        end

        $display("");
        if (errors == 0) begin
            $display("ALL NEURON MAC TESTS PASSED");
        end
        else begin
            $display("%0d NEURON MAC TESTS FAILED", errors);
        end
        $display("DONE");
        $finish;
    end
endmodule