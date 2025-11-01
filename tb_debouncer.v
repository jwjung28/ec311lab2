`timescale 1ns/1ps

module tb_debouncer;

  reg  clk        = 0;
  reg  reset      = 0;   // start low
  reg  button_in  = 0;
  wire button_out;

  // 100 MHz clock (10 ns period)
  always #5 clk = ~clk;

  // DUT (COUNT_MAX=8 for quick sim)
  debouncer #(
    .COUNT_MAX(8)
  ) dut (
    .clk       (clk),
    .reset     (reset),
    .button_in (button_in),
    .button_out(button_out)
  );

  initial begin
    $dumpfile("tb_debouncer.vcd");
    $dumpvars(0, tb_debouncer);
  end

  initial begin
    // --- Reset sequence (negedge reset)
    // Starts low, goes high, then low again to trigger reset
    repeat (5) @(posedge clk);
    reset = 1;
    repeat (3) @(posedge clk);
    reset = 0;   // falling edge (1->0) triggers reset

    // --- Simulate button press with debounce
    repeat (5) @(posedge clk);
    button_in = 1;   // press begins
    repeat (10) @(posedge clk);  // hold long enough -> output should go high

    // Hold longer (button_out stays high)
    repeat (10) @(posedge clk);

    // Release button
    button_in = 0;   // should return output to 0 quickly
    repeat (5) @(posedge clk);

    // Another press
    button_in = 1;
    repeat (10) @(posedge clk);
    button_in = 0;

    repeat (10) @(posedge clk);
    $finish;
  end

endmodule
