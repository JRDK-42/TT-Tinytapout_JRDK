
`default_nettype none

module uart_tx #(
    parameter integer BAUD_DIV = 87
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,

    input  wire [7:0] data_in,
    input  wire       start,

    output reg        tx,
    output reg        busy
);

    // 10 bits total:
    //
    // bit 0 : start bit = 0
    // bits 1-8 : data bits, LSB first
    // bit 9 : stop bit = 1
    //
    reg [9:0] shift_reg;

    // 0..9
    reg [3:0] bit_count;

    // BAUD_DIV=87 for:
    //
    // 10 MHz / 87 = 114942.5 baud
    //
    // Error relative to 115200 baud is approximately -0.22%.
    reg [7:0] baud_count;

    always @(posedge clk) begin

        if (!rst_n) begin

            shift_reg <= 10'b1111111111;
            bit_count <= 4'd0;
            baud_count <= 8'd0;

            tx   <= 1'b1;
            busy <= 1'b0;

        end
        else if (enable) begin

            // -------------------------------------------------
            // IDLE
            // -------------------------------------------------
            if (!busy) begin

                tx         <= 1'b1;
                baud_count <= 8'd0;
                bit_count  <= 4'd0;

                // Start a new UART transmission.
                // start should be a one-clock pulse.
                if (start) begin

                    // UART frame:
                    //
                    // {stop, data[7:0], start}
                    //
                    // Sending LSB first.
                    shift_reg <= {1'b1, data_in, 1'b0};

                    tx   <= 1'b0;
                    busy <= 1'b1;

                    bit_count  <= 4'd0;
                    baud_count <= 8'd0;
                end

            end

            // -------------------------------------------------
            // TRANSMITTING
            // -------------------------------------------------
            else begin

                if (baud_count == BAUD_DIV-1) begin

                    baud_count <= 8'd0;

                    if (bit_count == 4'd9) begin

                        // Last bit (stop bit) has completed.
                        busy      <= 1'b0;
                        tx        <= 1'b1;
                        bit_count <= 4'd0;

                    end
                    else begin

                        bit_count <= bit_count + 1'b1;

                        // Move to next UART bit.
                        shift_reg <= {1'b1, shift_reg[9:1]};

                        tx <= shift_reg[1];

                    end

                end
                else begin

                    baud_count <= baud_count + 1'b1;
                end

            end
        end

    end

endmodule

`default_nettype wire
