module weight_memory #(
    parameter INIT_FILE = ""
)(
    input  wire               clk,

    input  wire [9:0]         read_address,
    output reg  signed [7:0]  weight_out,

    input  wire               write_enable,
    input  wire [9:0]         write_address,
    input  wire signed [7:0]  weight_in
);

    //784 signed 8-bit weights.
    reg signed [7:0] memory [0:783];

    //init from mem file
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(
                INIT_FILE,
                memory
            );
        end
    end

    // synch read and write of weight memory
    always @(posedge clk) begin
        weight_out <= memory[read_address];
        if (write_enable) begin
            memory[write_address] <= weight_in;
        end
    end
endmodule