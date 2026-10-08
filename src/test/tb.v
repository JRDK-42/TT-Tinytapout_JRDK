
`timescale 1ns/1ps
`default_nettype none

module tb;

    reg  [7:0] ui_in;
    wire [7:0] uo_out;

    reg  [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    reg clk;
    reg rst_n;
    reg ena;

    // ---------------------------------------------------------
    // DUT
    // ---------------------------------------------------------

    tt_um_uart_tx dut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),

        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),

        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    // ---------------------------------------------------------
    // 10 MHz clock
    //
    // Period = 100 ns
    // ---------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever begin
            #50 clk = ~clk;
        end
    end

    // ---------------------------------------------------------
    // Test variables
    // ---------------------------------------------------------

    integer errors;
    integer i;

    reg [9:0] expected_frame;

    // ---------------------------------------------------------
    // Wait for N clock cycles
    // ---------------------------------------------------------

    task wait_cycles;
        input integer count;

        integer j;

        begin
            for (j = 0; j < count; j = j + 1)
                @(posedge clk);
        end
    endtask

    // ---------------------------------------------------------
    // UART receive/check task
    //
    // BAUD_DIV = 87
    //
    // We sample approximately in the center of each UART bit.
    // ---------------------------------------------------------

    task check_uart_byte;
        input [7:0] expected_data;

        integer bit_index;
        reg sampled_bit;

        begin

            expected_frame = {1'b1, expected_data, 1'b0};

            // Wait until transmitter becomes active.
            wait (uo_out[1] == 1'b1);

            $display("UART transmission started at time %0t", $time);

            // Move approximately to center of start bit.
            //
            // Start bit begins just after start command.
            // 87 clock cycles = one UART bit.
            //
            // 43 cycles puts us near the center.

            wait_cycles(43);

            for (bit_index = 0;
                 bit_index < 10;
                 bit_index = bit_index + 1) begin

                sampled_bit = uo_out[0];

                if (sampled_bit !== expected_frame[bit_index]) begin

                    $display(
                        "ERROR: UART bit %0d expected=%b got=%b time=%0t",
                        bit_index,
                        expected_frame[bit_index],
                        sampled_bit,
                        $time
                    );

                    errors = errors + 1;

                end
                else begin

                    $display(
                        "UART bit %0d OK = %b",
                        bit_index,
                        sampled_bit
                    );

                end

                // Move to approximately center of next bit.
                wait_cycles(87);

            end

            // Give transmitter time to return to idle.
            wait_cycles(10);

            if (uo_out[1] !== 1'b0) begin

                $display("ERROR: BUSY did not return low");

                errors = errors + 1;

            end
            else begin

                $display("BUSY returned LOW correctly");

            end

        end

    endtask

    // ---------------------------------------------------------
    // Main test
    // ---------------------------------------------------------

    initial begin

        errors = 0;

        ui_in  = 8'h00;
        uio_in = 8'h00;

        ena    = 1'b1;
        rst_n  = 1'b0;

        // Reset
        wait_cycles(5);

        rst_n = 1'b1;

        wait_cycles(5);

        $display("---------------------------------------");
        $display("Tiny Tapeout UART TX Test");
        $display("---------------------------------------");

        // -----------------------------------------------------
        // TEST 1
        // Data = 0xA5
        // Binary = 1010_0101
        // -----------------------------------------------------

        ui_in = 8'hA5;

        // Start pulse
        @(posedge clk);
        uio_in[0] = 1'b1;

        @(posedge clk);
        uio_in[0] = 1'b0;

        check_uart_byte(8'hA5);

        // -----------------------------------------------------
        // Wait before second test
        // -----------------------------------------------------

        wait_cycles(20);

        // -----------------------------------------------------
        // TEST 2
        // Data = 0x55
        // -----------------------------------------------------

        ui_in = 8'h55;

        @(posedge clk);
        uio_in[0] = 1'b1;

        @(posedge clk);
        uio_in[0] = 1'b0;

        check_uart_byte(8'h55);

        // -----------------------------------------------------
        // TEST 3
        // Data = 0x00
        // -----------------------------------------------------

        wait_cycles(20);

        ui_in = 8'h00;

        @(posedge clk);
        uio_in[0] = 1'b1;

        @(posedge clk);
        uio_in[0] = 1'b0;

        check_uart_byte(8'h00);

        // -----------------------------------------------------
        // TEST 4
        // Data = 0xFF
        // -----------------------------------------------------

        wait_cycles(20);

        ui_in = 8'hFF;

        @(posedge clk);
        uio_in[0] = 1'b1;

        @(posedge clk);
        uio_in[0] = 1'b0;

        check_uart_byte(8'hFF);

        // -----------------------------------------------------
        // Final result
        // -----------------------------------------------------

        $display("---------------------------------------");

        if (errors == 0) begin

            $display("TEST PASSED");
            $display("All UART frames transmitted correctly.");

        end
        else begin

            $display("TEST FAILED");
            $display("Number of errors = %0d", errors);

        end

        $display("---------------------------------------");

        #1000;

        $finish;

    end

endmodule

`default_nettype wire
