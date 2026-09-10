module weight_bank #(
    parameter INIT_FILE_0 = "",
    parameter INIT_FILE_1 = "",
    parameter INIT_FILE_2 = "",
    parameter INIT_FILE_3 = "",
    parameter INIT_FILE_4 = "",
    parameter INIT_FILE_5 = "",
    parameter INIT_FILE_6 = "",
    parameter INIT_FILE_7 = "",
    parameter INIT_FILE_8 = "",
    parameter INIT_FILE_9 = ""
)(
    input wire clk,

    input wire [9:0] read_address,

    output wire signed [7:0] weight0,
    output wire signed [7:0] weight1,
    output wire signed [7:0] weight2,
    output wire signed [7:0] weight3,
    output wire signed [7:0] weight4,
    output wire signed [7:0] weight5,
    output wire signed [7:0] weight6,
    output wire signed [7:0] weight7,
    output wire signed [7:0] weight8,
    output wire signed [7:0] weight9,

    input wire [9:0] write_address,

    input wire write_enable0,
    input wire write_enable1,
    input wire write_enable2,
    input wire write_enable3,
    input wire write_enable4,
    input wire write_enable5,
    input wire write_enable6,
    input wire write_enable7,
    input wire write_enable8,
    input wire write_enable9,

    input wire signed [7:0] weight_in0,
    input wire signed [7:0] weight_in1,
    input wire signed [7:0] weight_in2,
    input wire signed [7:0] weight_in3,
    input wire signed [7:0] weight_in4,
    input wire signed [7:0] weight_in5,
    input wire signed [7:0] weight_in6,
    input wire signed [7:0] weight_in7,
    input wire signed [7:0] weight_in8,
    input wire signed [7:0] weight_in9
);
    weight_memory #(
        .INIT_FILE(INIT_FILE_0)
    ) mem0 (
        .clk(clk),
        .read_address(read_address),
        .weight_out(weight0),
        .write_enable(write_enable0),
        .write_address(write_address),
        .weight_in(weight_in0)
    );

    weight_memory #(
        .INIT_FILE(INIT_FILE_1)
    ) mem1 (
        .clk(clk),
        .read_address(read_address),
        .weight_out(weight1),
        .write_enable(write_enable1),
        .write_address(write_address),
        .weight_in(weight_in1)
    );

    weight_memory #(
        .INIT_FILE(INIT_FILE_2)
    ) mem2 (
        .clk(clk),
        .read_address(read_address),
        .weight_out(weight2),
        .write_enable(write_enable2),
        .write_address(write_address),
        .weight_in(weight_in2)
    );

    weight_memory #(
        .INIT_FILE(INIT_FILE_3)
    ) mem3 (
        .clk(clk),
        .read_address(read_address),
        .weight_out(weight3),
        .write_enable(write_enable3),
        .write_address(write_address),
        .weight_in(weight_in3)
    );

    weight_memory #(
        .INIT_FILE(INIT_FILE_4)
    ) mem4 (
        .clk(clk),
        .read_address(read_address),
        .weight_out(weight4),
        .write_enable(write_enable4),
        .write_address(write_address),
        .weight_in(weight_in4)
    );

    weight_memory #(
        .INIT_FILE(INIT_FILE_5)
    ) mem5 (
        .clk(clk),
        .read_address(read_address),
        .weight_out(weight5),
        .write_enable(write_enable5),
        .write_address(write_address),
        .weight_in(weight_in5)
    );

    weight_memory #(
        .INIT_FILE(INIT_FILE_6)
    ) mem6 (
        .clk(clk),
        .read_address(read_address),
        .weight_out(weight6),
        .write_enable(write_enable6),
        .write_address(write_address),
        .weight_in(weight_in6)
    );

    weight_memory #(
        .INIT_FILE(INIT_FILE_7)
    ) mem7 (
        .clk(clk),
        .read_address(read_address),
        .weight_out(weight7),
        .write_enable(write_enable7),
        .write_address(write_address),
        .weight_in(weight_in7)
    );

    weight_memory #(
        .INIT_FILE(INIT_FILE_8)
    ) mem8 (
        .clk(clk),
        .read_address(read_address),
        .weight_out(weight8),
        .write_enable(write_enable8),
        .write_address(write_address),
        .weight_in(weight_in8)
    );

    weight_memory #(
        .INIT_FILE(INIT_FILE_9)
    ) mem9 (
        .clk(clk),
        .read_address(read_address),
        .weight_out(weight9),
        .write_enable(write_enable9),
        .write_address(write_address),
        .weight_in(weight_in9)
    );
endmodule