/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

`default_nettype none

module tt_um_uart_tx (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,

    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,

    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire tx;
    wire busy;

    // ---------------------------------------------------------
    // UART transmitter
    //
    // ui_in[7:0]  = parallel data
    // uio_in[0]   = start pulse
    //
    // 10 MHz clock
    // 115200 baud
    // ---------------------------------------------------------

    uart_tx #(
        .BAUD_DIV(87)
    ) uart_tx_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .enable   (ena),

        .data_in  (ui_in),
        .start    (uio_in[0]),

        .tx       (tx),
        .busy     (busy)
    );

    // ---------------------------------------------------------
    // Dedicated outputs
    //
    // uo_out[0] = UART TX
    // uo_out[1] = BUSY
    // uo_out[7:2] unused
    // ---------------------------------------------------------

    assign uo_out[0] = tx;
    assign uo_out[1] = busy;

    assign uo_out[7:2] = 6'b000000;

    // ---------------------------------------------------------
    // Bidirectional pins are inputs only.
    // ---------------------------------------------------------

    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

endmodule

`default_nettype wire
