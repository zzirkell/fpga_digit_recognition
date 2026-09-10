`timescale 1ns / 1ps

module tb_plan;

    reg  signed [8:0] a;
    wire        [5:0] y;

    integer errors;

    plan dut (
        .a(a),
        .y(y)
    );

    task check_plan;
        input signed [8:0] test_input;
        input        [5:0] expected_output;
        begin
            a = test_input;
            #10;
            if (y !== expected_output) begin
                $display("FAIL: PLAN(%0d) = %0d, expected %0d", test_input, y, expected_output);
                errors = errors + 1;
            end
            else begin
                $display("PASS: PLAN(%0d) = %0d", test_input, y);
            end
        end
    endtask


    //tests
    initial begin
        errors = 0;
        //zero
        check_plan(
            9'sd0,
            6'd16
        );

        //pos 1st region
        check_plan(
            9'sd16,
            6'd20
        );
        check_plan(
            9'sd31,
            6'd23
        );


        //pos 2nd region
        check_plan(
            9'sd32,
            6'd24
        );
        check_plan(
            9'sd48,
            6'd26
        );
        check_plan(
            9'sd75,
            6'd29
        );


        //pos 3rd region
        check_plan(
            9'sd76,
            6'd29
        );
        check_plan(
            9'sd100,
            6'd30
        );
        check_plan(
            9'sd159,
            6'd31
        );

        //pos saturation
        check_plan(
            9'sd160,
            6'd32
        );
        check_plan(
            9'sd200,
            6'd32
        );
        check_plan(
            9'sd255,
            6'd32
        );


        //neg vals
        check_plan(
            -9'sd16,
            6'd12
        );
        check_plan(
            -9'sd48,
            6'd6
        );
        check_plan(
            -9'sd100,
            6'd2
        );
        check_plan(
            -9'sd160,
            6'd0
        );
        check_plan(
            -9'sd200,
            6'd0
        );


        //most negative-negative
        check_plan(
            -9'sd256,
            6'd0
        );
        $display("");
        if (errors == 0) begin
            $display("ALL PLAN TESTS PASSED");
        end
        else begin
            $display("%0d PLAN TESTS FAILED",errors  );

        end 
        $display("DONE");
        $finish;
    end
endmodule