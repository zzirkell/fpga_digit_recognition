module forward_controller (
    input  wire       clk,
    input  wire       rstn,

    input  wire       start,

    output reg        clear,
    output reg        enable,
    output reg        done,

    output reg [9:0]  pixel_index
);

    //states
    localparam IDLE = 2'd0; //start
    localparam CLEAR = 2'd1; //1cycle
    localparam RUN = 2'd2; //784 pixel cycles
    localparam DONE = 2'd3; //1 cycle, to Idle

    reg [1:0] state;


    //state and pixel remembered
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state       <= IDLE;
            pixel_index <= 10'd0;
            clear       <= 1'b0;
            enable      <= 1'b0;
            done        <= 1'b0;
        end
        else begin
            case (state)

                //wait for start
                IDLE: begin
                    clear  <= 1'b0;
                    enable <= 1'b0;
                    done   <= 1'b0;
                    pixel_index <= 10'd0; //reset here of index
                    if (start) begin
                        state <= CLEAR;
                    end
                end

                //clear accumulator before starting to process pixels
                CLEAR: begin
                    clear  <= 1'b1;
                    enable <= 1'b0;
                    done   <= 1'b0;
                    pixel_index <= 10'd0;
                    state <= RUN;
                end


                //process 784 pixels, one per cycle
                RUN: begin
                    clear  <= 1'b0;
                    enable <= 1'b1;
                    done   <= 1'b0;
                    if (pixel_index == 10'd783) begin
                        state <= DONE;
                    end
                    else begin
                        pixel_index <= pixel_index + 1'b1;
                    end

                end

                DONE: begin
                    clear  <= 1'b0;
                    enable <= 1'b0;
                    done   <= 1'b1;
                    state <= IDLE;
                end


                //safety
                default: begin
                    state       <= IDLE;
                    pixel_index <= 10'd0;

                    clear       <= 1'b0;
                    enable      <= 1'b0;
                    done        <= 1'b0;
                end
            endcase
        end
    end
endmodule