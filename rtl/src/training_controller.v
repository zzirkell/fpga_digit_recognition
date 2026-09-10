module training_controller (
    input wire clk,
    input wire rstn,
    input wire start,
    output reg clear,
    output reg forward_enable,
    output reg weight_write_enable,
    output reg done,
    output reg [9:0] read_address,
    output reg [9:0] write_address
);

    //states
    localparam IDLE = 3'd0;
    localparam CLEAR = 3'd1;
    localparam FORWARD = 3'd2;
    localparam UPDATE_PRIME = 3'd3;
    localparam UPDATE = 3'd4;
    localparam DONE = 3'd5;

    reg [2:0] state;
    reg [9:0] forward_count;
    reg [9:0] update_count;

    //seq remembers:
    //current phase/state
    //which forward pixel is being processed
    //which weight address is being updated
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= IDLE;
            forward_count <= 10'd0;
            update_count <= 10'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    forward_count <= 10'd0;
                    update_count <= 10'd0;
                    if (start)
                        state <= CLEAR;
                end
                //one complete clock with clear asserted
                CLEAR: begin
                    forward_count <= 10'd0;
                    state <= FORWARD;
                end
                //784 MAC operations.
                FORWARD: begin
                    if (forward_count == 10'd783) begin
                        update_count <= 10'd0;
                        state <= UPDATE_PRIME;
                    end
                    else
                        forward_count <= forward_count + 1'b1;
                end

                //one cycle to fetch the first old weight and pixel for the update
                UPDATE_PRIME: begin
                    update_count <= 10'd0;
                    state <= UPDATE;
                end

                //update ten weights in parallel
                UPDATE: begin
                    if (update_count == 10'd783)
                        state <= DONE;
                    else
                        update_count <= update_count + 1'b1;
                end

                DONE: begin
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    forward_count <= 10'd0;
                    update_count <= 10'd0;
                end
            endcase
        end
    end

    //comb outputs based on state
    always @(*) begin
        clear = 1'b0;
        forward_enable = 1'b0;
        weight_write_enable = 1'b0;
        done = 1'b0;
        read_address = 10'd0;
        write_address = 10'd0;

        case (state)
            IDLE: begin
                read_address = 10'd0;
            end

            CLEAR: begin
                clear = 1'b1;
                read_address = 10'd0;
            end

            FORWARD: begin
                forward_enable = 1'b1;
                //current pixel is already available
                //while MAC consumes it, prefetch next one
                if (forward_count < 10'd783)
                    read_address = forward_count + 1'b1;
                else
                    read_address = 10'd783;
            end

            UPDATE_PRIME: begin
                //fetch old weight[0] and pixel[0]
                //no write
                read_address = 10'd0;
            end

            UPDATE: begin
                weight_write_enable = 1'b1;

                //the synchronous RAM output currently corresponds to update_count
                write_address = update_count;
                //at the same clock, prefetch
                if (update_count < 10'd783)
                    read_address = update_count + 1'b1;
                else
                    read_address = 10'd783;
            end
            DONE: begin
                done = 1'b1;
            end
        endcase
    end
endmodule