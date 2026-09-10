`timescale 1ns / 1ps

module tb_neuron_forward;
    reg               clk;
    reg               rstn;
    reg               clear;
    reg               enable;

    reg        [7:0]  pixel;
    reg signed [7:0]  weight;
    wire signed [31:0] accumulator;
    wire signed  [8:0] plan_input;
    wire         [5:0] activation;

    integer i;
    integer errors;

    // Experiment A forward scaling:
    // ACC_SHIFT = 10

    neuron_forward #(
        .ACC_SHIFT(10)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .clear(clear),
        .enable(enable),
        .pixel(pixel),
        .weight(weight),
        .accumulator(accumulator),
        .plan_input(plan_input),
        .activation(activation)
    );

    initial begin
        clk = 1'b0;
        forever begin
            #5 clk = ~clk;
        end
    end


    //clear acc
    task clear_accumulator;
        begin
            @(negedge clk);
            clear  = 1'b1;
            enable = 1'b0;
            @(posedge clk);
            #1;
            clear = 1'b0;
        end
    endtask

    //main test sequence
    initial begin
        errors = 0;
        rstn   = 1'b0;
        clear  = 1'b0;
        enable = 1'b0;
        pixel  = 8'd0;
        weight = 8'sd0;
        //release reset.
        #12;
        rstn = 1'b1;

        //TEST 1
        //build accumulator = +49152
        //64 × 96 = 6144
        //6144 × 8 = 49152
        //49152 >> 10 = 48
        //PLAN(48) = 26
        clear_accumulator();

        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            pixel  = 8'd64;
            weight = 8'sd96;
            enable = 1'b1;
            @(posedge clk);
        end
        #1;
        enable = 1'b0;

        if (
            accumulator !== 32'sd49152 ||
            plan_input   !== 9'sd48    ||
            activation   !== 6'd26
        ) begin
            $display(
                "FAIL positive forward test"
            );
            $display(
                "acc=%0d plan_input=%0d activation=%0d",
                accumulator,
                plan_input,
                activation
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS: acc=49152 -> shifted=48 -> PLAN=26"
            );
        end

        //TEST 2
        //build accumulator = -49152
        //64 × (-96) = -6144
        //-6144 × 8 = -49152
        //-49152 >>> 10 = -48
        //PLAN(-48) = 6
        clear_accumulator();

        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            pixel  = 8'd64;
            weight = -8'sd96;
            enable = 1'b1;
            @(posedge clk);
        end
        #1;
        enable = 1'b0;

        if (
            accumulator !== -32'sd49152 ||
            plan_input   !== -9'sd48    ||
            activation   !== 6'd6
        ) begin
            $display(
                "FAIL negative forward test"
            );
            $display(
                "acc=%0d plan_input=%0d activation=%0d",
                accumulator,
                plan_input,
                activation
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS: acc=-49152 -> shifted=-48 -> PLAN=6"
            );
        end

        //positive saturation test
        //accumulator >> 10 > 255
        //plan_input = 255
        //PLAN = 32

        clear_accumulator();
        for (i = 0; i < 17; i = i + 1) begin
            @(negedge clk);
            pixel  = 8'd127;
            weight = 8'sd127;
            enable = 1'b1;
            @(posedge clk);
        end
        #1;
        enable = 1'b0;

        if (
            plan_input !== 9'sd255 ||
            activation !== 6'd32
        ) begin
            $display(
                "FAIL positive saturation test"
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS: positive value saturates to 255 -> PLAN=32"
            );
        end


        //neg saturation test
        clear_accumulator();
        for (i = 0; i < 17; i = i + 1) begin
            @(negedge clk);
            pixel  = 8'd127;
            weight = -8'sd128;
            enable = 1'b1;
            @(posedge clk);
        end
        #1;
        enable = 1'b0;

        if (
            plan_input !== 9'sb100000000 ||
            activation !== 6'd0
        ) begin
            $display(
                "FAIL negative saturation test"
            );
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS: negative value saturates to -256 -> PLAN=0"
            );
        end

        $display("");
        if (errors == 0) begin
            $display(
                "ALL NEURON FORWARD TESTS PASSED"
            );
        end
        else begin
            $display(
                "%0d NEURON FORWARD TESTS FAILED",
                errors
            );
        end
        $finish;
    end
endmodule