`timescale 1ns / 1ps

module tb_accuracy_expA;

    //configuration
    localparam NUM_IMAGES = 10000;
    localparam NUM_PIXELS = 784;
    integer image_file;
    integer scan_result;
    integer pixel_value;

    //DUT signals
    reg clk;
    reg rstn;
    reg start;
    wire done;
    wire [3:0] prediction;
    wire [9:0] pixel_index;

    //complete test dataset - testbench memory only
    reg [3:0] all_labels [0:NUM_IMAGES-1];
    reg [3:0] python_predictions [0:NUM_IMAGES-1];

    //counters
    integer image_number;
    integer pixel_number;
    integer correct_count;
    integer python_mismatch_count;

    //experiment B: integer-trained weights, ACC_SHIFT = 11
    digit_classifier_forward #(
        .ACC_SHIFT(10),
        .IMAGE_FILE(""),
        .WEIGHT_FILE_0("expA_weights_0.mem"),
        .WEIGHT_FILE_1("expA_weights_1.mem"),
        .WEIGHT_FILE_2("expA_weights_2.mem"),
        .WEIGHT_FILE_3("expA_weights_3.mem"),
        .WEIGHT_FILE_4("expA_weights_4.mem"),
        .WEIGHT_FILE_5("expA_weights_5.mem"),
        .WEIGHT_FILE_6("expA_weights_6.mem"),
        .WEIGHT_FILE_7("expA_weights_7.mem"),
        .WEIGHT_FILE_8("expA_weights_8.mem"),
        .WEIGHT_FILE_9("expA_weights_9.mem")
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .start(start),
        .done(done),
        .prediction(prediction),
        .pixel_index(pixel_index)
    );

    //clock: 10 ns period = 100 MHz
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //load complete test dataset
    initial begin
        $readmemh("expA_test_labels_10000.mem", all_labels);
        $readmemh("expA_python_predictions_10000.mem", python_predictions);

        image_file = $fopen("expA_test_images_10000.mem", "r");

        if (image_file == 0) begin
            $display("ERROR: could not open image file");
            $finish;
        end
    end

    //main accuracy test
    initial begin
        rstn = 1'b0;
        start = 1'b0;
        correct_count = 0;
        python_mismatch_count = 0;

        //reset
        #20;
        rstn = 1'b1;

        //run every test image
        for (image_number = 0; image_number < NUM_IMAGES; image_number = image_number + 1) begin

            //copy this image's 784 pixels into the classifier's image memory
            for (pixel_number = 0; pixel_number < NUM_PIXELS; pixel_number = pixel_number + 1) begin
                scan_result = $fscanf(image_file, "%h\n", pixel_value);

                if (scan_result != 1) begin
                    $display("ERROR reading image %0d pixel %0d", image_number, pixel_number);
                    $finish;
                end

                dut.image_memory_inst.memory[pixel_number] = pixel_value[7:0];
            end

            //start one complete forward pass
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            //wait until all 784 pixels are processed
            wait(done == 1'b1);
            #1;

            //accuracy against real MNIST label
            if (prediction == all_labels[image_number])
                correct_count = correct_count + 1;

            //exact equivalence against Python
            if (prediction != python_predictions[image_number]) begin
                python_mismatch_count = python_mismatch_count + 1;

                //print only first 10 mismatches
                if (python_mismatch_count <= 10) begin
                    $display("MISMATCH image=%0d RTL=%0d Python=%0d label=%0d",
                             image_number, prediction,
                             python_predictions[image_number],
                             all_labels[image_number]);
                end
            end

            //progress every 1000 images
            if (((image_number + 1) % 1000) == 0) begin
                $display("Processed %0d / %0d | correct=%0d | mismatches=%0d",
                         image_number + 1, NUM_IMAGES,
                         correct_count, python_mismatch_count);
            end
        end

        //final results
        $fclose(image_file);
        $display("");
        $display("EXPERIMENT A - FULL RTL TEST");
        $display("Images tested: %0d", NUM_IMAGES);
        $display("Correct:       %0d / %0d", correct_count, NUM_IMAGES);
        $display("RTL accuracy:  %0d.%02d%%", correct_count / 100, correct_count % 100);
        $display("RTL/Python prediction mismatches: %0d", python_mismatch_count);

        if (python_mismatch_count == 0) begin
            $display("");
            $display("PASS: RTL MATCHES PYTHON FOR ALL 10000 IMAGES");
        end
        else begin
            $display("");
            $display("FAIL: RTL AND PYTHON DIFFER");
        end
        $finish;
    end

endmodule
