module top_part1 (
    input  wire        clk,        // 100 MHz board clock
    input  wire        reset,      // ACTIVE-LOW reset (0 = reset)
    input  wire        button_in,  // raw (noisy) push-button
    output wire [7:0]  count       // drive LEDs in binary
);

    // One-clock pulse from debouncer to increment the counter
    wire increment_pulse;

    // Debouncer (Figure 1 algorithm). Adjust COUNT_MAX if needed.
    debouncer #(
        .COUNT_MAX(2_000_000)       // ~20 ms @ 100 MHz
    ) db (
        .clk       (clk),
        .reset     (reset),         // ACTIVE-LOW
        .button_in (button_in),
        .button_out(increment_pulse)
    );

    // 8-bit counter: increments once per debounced pulse
    counter cnt (
        .clk       (clk),
        .reset     (reset),         // ACTIVE-LOW
        .increment (increment_pulse),
        .count     (count)
    );

endmodule
