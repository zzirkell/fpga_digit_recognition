`timescale 1ns / 1ps

module tb_weight_update;

    reg signed [15:0] correction;
    reg [7:0] pixel;
    reg signed [7:0] old_weight;
    wire signed [24:0] raw_delta;
    wire signed [15:0] delta_weight;
    wire signed [7:0] new_weight;
    integer errors;

    weight_update #(
        .TRAIN_SHIFT(18)
    ) dut (
        .correction(correction),
        .pixel(pixel),
        .old_weight(old_weight),
        .raw_delta(raw_delta),
        .delta_weight(delta_weight),
        .new_weight(new_weight)
    );

    initial begin
        errors = 0;
        //4096 * 64 = 262144
        //262144 >> 18 = 1
        //10 + 1 = 11
        correction = 16'sd4096;
        pixel = 8'd64;
        old_weight = 8'sd10;
        #10;

        if (raw_delta !== 25'sd262144 || delta_weight !== 16'sd1 || new_weight !== 8'sd11) begin
            $display("FAIL 1: raw=%0d delta=%0d new=%0d", raw_delta, delta_weight, new_weight);
            errors = errors + 1;
        end
        else begin
            $display("PASS 1");
        end

        //neg
        //-4096 * 64 = -262144
        //toward-zero shift = -1
        //10 - 1 = 9
        correction = -16'sd4096;
        pixel = 8'd64;
        old_weight = 8'sd10;
        #10;

        if (raw_delta !== -25'sd262144 || delta_weight !== -16'sd1 || new_weight !== 8'sd9) begin
            $display("FAIL 2: raw=%0d delta=%0d new=%0d", raw_delta, delta_weight, new_weight);
            errors = errors + 1;
        end
        else begin
            $display("PASS 2");
        end

        //TOWARD-ZERO behavior
        //-1536 * 64 = -98304
        //magnitude is smaller than 2^18, delta must be ZERO
        correction = -16'sd1536;
        pixel = 8'd64;
        old_weight = 8'sd10;
        #10; 
        if (raw_delta !== -25'sd98304 || delta_weight !== 16'sd0 || new_weight !== 8'sd10) begin
            $display("FAIL 3: raw=%0d delta=%0d new=%0d", raw_delta, delta_weight, new_weight);
            errors = errors + 1;
        end
        else begin
            $display("PASS 3");
        end
        
        //Positive saturation
        //old = 127
        //delta = +1
        correction = 16'sd4096;
        pixel = 8'd64;
        old_weight = 8'sd127;
        #10;

        if (delta_weight !== 16'sd1 || new_weight !== 8'sd127) begin
            $display("FAIL 4: delta=%0d new=%0d", delta_weight, new_weight);
            errors = errors + 1;
        end
        else begin
            $display("PASS 4");
        end

        //neg saturation
        correction = -16'sd4096;
        pixel = 8'd64;
        old_weight = 8'sh80;
        #10;
        if (delta_weight !== -16'sd1 || new_weight !== 8'sh80) begin
            $display("FAIL 5: delta=%0d new=%0d", delta_weight, new_weight);
            errors = errors + 1;
        end
        else begin
            $display("PASS 5");
        end

        // 8192 * 127 = 1040384
        // >> 18 = 3
        // -5 + 3 = -2
        correction = 16'sd8192;
        pixel = 8'd127;
        old_weight = -8'sd5;
        #10;

        if (raw_delta !== 25'sd1040384 || delta_weight !== 16'sd3 || new_weight !== -8'sd2) begin
            $display("FAIL 6: raw=%0d delta=%0d new=%0d", raw_delta, delta_weight, new_weight);
            errors = errors + 1;
        end
        else begin
            $display("PASS 6");
        end

        $display("");
        if (errors == 0)
            $display("ALL WEIGHT UPDATE TESTS PASSED");
        else
            $display("%0d WEIGHT UPDATE TESTS FAILED", errors);
        $finish;
    end

endmodule