module image_memory #(
    parameter INIT_FILE = ""
)(
    input  wire       clk,
    input  wire [9:0] address, //for 783 pixels enough

    output reg  [7:0] pixel
);
    // 784 pixels, each 8 bits.
    reg [7:0] memory [0:783];
    
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(
                INIT_FILE,
                memory
            );
        end
    end

    //synch read of pixel from memory
    always @(posedge clk) begin
        pixel <= memory[address];
    end
endmodule