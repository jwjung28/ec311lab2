`timescale 1ns/1ps

module tb_counter;

  reg        clk = 0;
  reg        reset = 0;     // ACTIVE-LOW: start held in reset (0)
  reg        increment = 0;
  wire [7:0] count;

  // 100 MHz clock (10 ns period)
  always #5 clk = ~clk;

  // DUT
  counter dut (
    .clk      (clk),
    .reset    (reset),      // ACTIVE-LOW
    .increment(increment),
    .count    (count)
  );

  // Waveform dump
  initial begin
    $dumpfile("tb_counter.vcd");
    $dumpvars(0, tb_counter);
  end

  // Stimulus
  initial begin
    // keep reset low for a few cycles, then release to 1
    repeat (5) @(posedge clk);
    reset = 0;

    // one increment pulse -> count = 1
    @(posedge clk); increment = 1;
    @(posedge clk); increment = 0;
    repeat (2) @(posedge clk);

    // two more pulses -> count = 3
    @(posedge clk); increment = 1;
    @(posedge clk); increment = 0;
    @(posedge clk); increment = 1;
    @(posedge clk); increment = 0;
    repeat (2) @(posedge clk);

    // assert reset again (active-low) -> count = 0
    reset = 1;
    @(posedge clk);
    reset = 0;
    repeat (2) @(posedge clk);

    // another pulse -> count = 1
    @(posedge clk); increment = 1;
    @(posedge clk); increment = 0;
    repeat (3) @(posedge clk);
    
    @(posedge clk); increment = 1;
    @(posedge clk); increment = 0;
    
    reset = 1;
    
    @(posedge clk); increment = 1;
    @(posedge clk); increment = 0;
    
    @(posedge clk); increment = 1;
    @(posedge clk); increment = 0;
    
    reset = 0;
    
    @(posedge clk); increment = 1;
    @(posedge clk); increment = 0;
    
    @(posedge clk); increment = 1;
    @(posedge clk); increment = 0;

    $finish;
  end

endmodule
