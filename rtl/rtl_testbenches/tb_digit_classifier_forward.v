`timescale 1ns / 1ps

module tb_digit_classifier_forward;

    reg clk;
    reg rstn;
    reg start;
    wire done;
    wire [3:0] prediction;
    wire [9:0] pixel_index;

    //experiment A: Float-trained -> quantized integer inference.
    //ACC_SHIFT = 10
    //exp B: ACC_SHIFT =11

    digit_classifier_forward #(
        .ACC_SHIFT(11),
        .IMAGE_FILE("expB_image_0.mem"),
        .WEIGHT_FILE_0("expB_weights_0.mem"),
        .WEIGHT_FILE_1("expB_weights_1.mem"),
        .WEIGHT_FILE_2("expB_weights_2.mem"),
        .WEIGHT_FILE_3("expB_weights_3.mem"),
        .WEIGHT_FILE_4("expB_weights_4.mem"),
        .WEIGHT_FILE_5("expB_weights_5.mem"),
        .WEIGHT_FILE_6("expB_weights_6.mem"),
        .WEIGHT_FILE_7("expB_weights_7.mem"),
        .WEIGHT_FILE_8("expB_weights_8.mem"),
        .WEIGHT_FILE_9("expB_weights_9.mem")
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .start(start),
        .done(done),
        .prediction(prediction),
        .pixel_index(pixel_index)
    );

    //clock forController, memories, and MAC accumulators
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    // Test
    initial begin
        rstn = 1'b0;
        start = 1'b0;
        //reset system.
        #20;
        rstn = 1'b1;
        //give one start pulse.
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        //wait until all 784 pixels have been processed.
        wait(done == 1'b1);
        #1;

        $display("");
        $display("END-TO-END EXPERIMENT A");
        $display("RTL prediction = %0d", prediction);
        $display("Expected label = 7");

        if (prediction == 4'd7) begin
            $display("PASS: RTL classified MNIST image 0 as 7");
        end
        else begin
            $display("FAIL: expected 7, RTL predicted %0d", prediction);
        end

        //internal debug output: accumulators and PLAN activations
        $display("");
        $display("Accumulators:");
        $display("%0d %0d %0d %0d %0d", dut.accumulator0, dut.accumulator1, dut.accumulator2, dut.accumulator3, dut.accumulator4);
        $display("%0d %0d %0d %0d %0d", dut.accumulator5, dut.accumulator6, dut.accumulator7, dut.accumulator8, dut.accumulator9);
        $display("");
        $display("PLAN activations:");
        $display("%0d %0d %0d %0d %0d", dut.activation0, dut.activation1, dut.activation2, dut.activation3, dut.activation4);
        $display("%0d %0d %0d %0d %0d", dut.activation5, dut.activation6, dut.activation7, dut.activation8, dut.activation9);
        #20;
        $finish;
    end
endmodule