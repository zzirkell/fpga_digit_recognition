`timescale 1ns / 1ps

module tb_digit_classifier_train;

    //confogs
    localparam NUM_IMAGES = 10000;
    localparam NUM_PIXELS = 784;

    reg clk;
    reg rstn;
    reg start;
    reg [3:0] label;

    wire done;
    wire [3:0] prediction;
    wire [9:0] memory_address;

    //tr labels
    reg [3:0] train_labels [0:NUM_IMAGES-1];

    //pyth expected final weights
    reg signed [7:0] expected0 [0:783];
    reg signed [7:0] expected1 [0:783];
    reg signed [7:0] expected2 [0:783];
    reg signed [7:0] expected3 [0:783];
    reg signed [7:0] expected4 [0:783];
    reg signed [7:0] expected5 [0:783];
    reg signed [7:0] expected6 [0:783];
    reg signed [7:0] expected7 [0:783];
    reg signed [7:0] expected8 [0:783];
    reg signed [7:0] expected9 [0:783];

    //file streaming variables
    integer image_file;
    integer scan_result;
    integer pixel_value;
    integer image_number;
    integer pixel_number;
    integer mismatch_count;

    //as in exp b
    digit_classifier_train #(
        .ACC_SHIFT(11),
        .TRAIN_SHIFT(18),

        //the image memory will be filled directly by the testbench before each training operation.
        .IMAGE_FILE(""),

        .WEIGHT_FILE_0("expB_train_initial_0.mem"),
        .WEIGHT_FILE_1("expB_train_initial_1.mem"),
        .WEIGHT_FILE_2("expB_train_initial_2.mem"),
        .WEIGHT_FILE_3("expB_train_initial_3.mem"),
        .WEIGHT_FILE_4("expB_train_initial_4.mem"),
        .WEIGHT_FILE_5("expB_train_initial_5.mem"),
        .WEIGHT_FILE_6("expB_train_initial_6.mem"),
        .WEIGHT_FILE_7("expB_train_initial_7.mem"),
        .WEIGHT_FILE_8("expB_train_initial_8.mem"),
        .WEIGHT_FILE_9("expB_train_initial_9.mem")
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .start(start),
        .label(label),
        .done(done),
        .prediction(prediction),
        .memory_address(memory_address)
    );
    //10ns

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //load ref
    initial begin

        $readmemh("expB_train_labels_10000.mem", train_labels);
        //expected final Python weights after training on all 10,000 images

        $readmemh("expB_train_final_expected_0.mem", expected0);
        $readmemh("expB_train_final_expected_1.mem", expected1);
        $readmemh("expB_train_final_expected_2.mem", expected2);
        $readmemh("expB_train_final_expected_3.mem", expected3);
        $readmemh("expB_train_final_expected_4.mem", expected4);
        $readmemh("expB_train_final_expected_5.mem", expected5);
        $readmemh("expB_train_final_expected_6.mem", expected6);
        $readmemh("expB_train_final_expected_7.mem", expected7);
        $readmemh("expB_train_final_expected_8.mem", expected8);
        $readmemh("expB_train_final_expected_9.mem", expected9);
    end

    //full train
    initial begin
        rstn = 1'b0;
        start = 1'b0;
        label = 4'd0;
        mismatch_count = 0;

        image_file = $fopen("expB_train_images_10000.mem", "r");

        if (image_file == 0) begin
            $display("ERROR: could not open expB_train_images_10000.mem");
            $finish;
        end

        //reset

        #20;
        rstn = 1'b1;

        //train on all 10k

        for (image_number = 0; image_number < NUM_IMAGES; image_number = image_number + 1) begin
            for (pixel_number = 0; pixel_number < NUM_PIXELS; pixel_number = pixel_number + 1) begin
                scan_result = $fscanf(image_file, "%h\n", pixel_value);

                if (scan_result != 1) begin
                    $display(
                        "ERROR reading training image %0d pixel %0d",
                        image_number,
                        pixel_number
                    );
                    $finish;
                end
                dut.image_memory_inst.memory[pixel_number] = pixel_value[7:0];
            end

            //give dut the correct label
            label = train_labels[image_number];

            // Start ONE complete training operation
            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            //wait until image completed
            wait(done == 1'b1);
            @(posedge clk);
            #1;

            //every 1000 images
            if (((image_number + 1) % 1000) == 0) begin
                $display(
                    "Trained %0d / %0d images",
                    image_number + 1,
                    NUM_IMAGES
                );
            end

        end

        $fclose(image_file);

        $display("");
        $display("FULL EXPERIMENT B HARDWARE TRAINING TEST");
        $display("Training images processed: %0d", NUM_IMAGES);
        //compare ALL 7,840 final RTL weights with Python
        mismatch_count = 0;
        for (pixel_number = 0; pixel_number < NUM_PIXELS; pixel_number = pixel_number + 1) begin

            //0
            if (dut.weight_bank_inst.mem0.memory[pixel_number] !== expected0[pixel_number]) begin
                mismatch_count = mismatch_count + 1;

                if (mismatch_count <= 20)
                    $display(
                        "Mismatch N0[%0d]: RTL=%0d Python=%0d",
                        pixel_number,
                        dut.weight_bank_inst.mem0.memory[pixel_number],
                        expected0[pixel_number]
                    );
            end

            //1
            if (dut.weight_bank_inst.mem1.memory[pixel_number] !== expected1[pixel_number]) begin
                mismatch_count = mismatch_count + 1;

                if (mismatch_count <= 20)
                    $display(
                        "Mismatch N1[%0d]: RTL=%0d Python=%0d",
                        pixel_number,
                        dut.weight_bank_inst.mem1.memory[pixel_number],
                        expected1[pixel_number]
                    );
            end

            //2

            if (dut.weight_bank_inst.mem2.memory[pixel_number] !== expected2[pixel_number]) begin
                mismatch_count = mismatch_count + 1;

                if (mismatch_count <= 20)
                    $display(
                        "Mismatch N2[%0d]: RTL=%0d Python=%0d",
                        pixel_number,
                        dut.weight_bank_inst.mem2.memory[pixel_number],
                        expected2[pixel_number]
                    );
            end

            //3

            if (dut.weight_bank_inst.mem3.memory[pixel_number] !== expected3[pixel_number]) begin
                mismatch_count = mismatch_count + 1;

                if (mismatch_count <= 20)
                    $display(
                        "Mismatch N3[%0d]: RTL=%0d Python=%0d",
                        pixel_number,
                        dut.weight_bank_inst.mem3.memory[pixel_number],
                        expected3[pixel_number]
                    );
            end

            //4

            if (dut.weight_bank_inst.mem4.memory[pixel_number] !== expected4[pixel_number]) begin
                mismatch_count = mismatch_count + 1;

                if (mismatch_count <= 20)
                    $display(
                        "Mismatch N4[%0d]: RTL=%0d Python=%0d",
                        pixel_number,
                        dut.weight_bank_inst.mem4.memory[pixel_number],
                        expected4[pixel_number]
                    );
            end

            //5

            if (dut.weight_bank_inst.mem5.memory[pixel_number] !== expected5[pixel_number]) begin
                mismatch_count = mismatch_count + 1;

                if (mismatch_count <= 20)
                    $display(
                        "Mismatch N5[%0d]: RTL=%0d Python=%0d",
                        pixel_number,
                        dut.weight_bank_inst.mem5.memory[pixel_number],
                        expected5[pixel_number]
                    );
            end

            //6

            if (dut.weight_bank_inst.mem6.memory[pixel_number] !== expected6[pixel_number]) begin
                mismatch_count = mismatch_count + 1;

                if (mismatch_count <= 20)
                    $display(
                        "Mismatch N6[%0d]: RTL=%0d Python=%0d",
                        pixel_number,
                        dut.weight_bank_inst.mem6.memory[pixel_number],
                        expected6[pixel_number]
                    );
            end

            //7

            if (dut.weight_bank_inst.mem7.memory[pixel_number] !== expected7[pixel_number]) begin
                mismatch_count = mismatch_count + 1;

                if (mismatch_count <= 20)
                    $display(
                        "Mismatch N7[%0d]: RTL=%0d Python=%0d",
                        pixel_number,
                        dut.weight_bank_inst.mem7.memory[pixel_number],
                        expected7[pixel_number]
                    );
            end

            //8

            if (dut.weight_bank_inst.mem8.memory[pixel_number] !== expected8[pixel_number]) begin
                mismatch_count = mismatch_count + 1;

                if (mismatch_count <= 20)
                    $display(
                        "Mismatch N8[%0d]: RTL=%0d Python=%0d",
                        pixel_number,
                        dut.weight_bank_inst.mem8.memory[pixel_number],
                        expected8[pixel_number]
                    );
            end

            //9

            if (dut.weight_bank_inst.mem9.memory[pixel_number] !== expected9[pixel_number]) begin
                mismatch_count = mismatch_count + 1;

                if (mismatch_count <= 20)
                    $display(
                        "Mismatch N9[%0d]: RTL=%0d Python=%0d",
                        pixel_number,
                        dut.weight_bank_inst.mem9.memory[pixel_number],
                        expected9[pixel_number]
                    );
            end

        end

        //fin

        $display("");
        $display("Weights compared: 7840");
        $display("RTL/Python weight mismatches: %0d", mismatch_count);

        if (mismatch_count == 0) begin
            $display("");
            $display("PASS: FULL RTL TRAINING MATCHES PYTHON");
            $display("ALL 7840 FINAL WEIGHTS MATCH EXACTLY");
        end
        else begin
            $display("");
            $display("FAIL: RTL TRAINING DIFFERS FROM PYTHON");
        end

        #20;
        $finish;
    end
endmodule