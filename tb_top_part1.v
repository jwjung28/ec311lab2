`timescale 1ns/1ps

module tb_top_part1;

  // -----------------------------
  // Testbench signals
  // -----------------------------
  reg         clk        = 1'b0;
  reg         reset      = 1'b0;   // ACTIVE-LOW: start held in reset
  reg         button_in  = 1'b0;
  wire [7:0]  count;

  // -----------------------------
  // DUT
  // -----------------------------
  top_part1 dut (
    .clk       (clk),
    .reset     (reset),
    .button_in (button_in),
    .count     (count)
  );

  // For quick simulation, shrink the debouncer window.
  // This overrides top_part1's debouncer instance parameter:
  //   debouncer db ( .COUNT_MAX(2_000_000) ... )
  // to a small value here in the TB.
  localparam integer TB_COUNT_MAX = 8;
  defparam dut.db.COUNT_MAX = TB_COUNT_MAX;

  // Optional: tap internal pulse (declared as a wire in top_part1)
  wire increment_pulse = dut.increment_pulse;

  // -----------------------------
  // 100 MHz clock (10 ns period)
  // -----------------------------
  always #5 clk = ~clk;

  // -----------------------------
  // Wave dump
  // -----------------------------
  initial begin
    $dumpfile("tb_top_part1.vcd");
    $dumpvars(0, tb_top_part1);
  end

  // -----------------------------
  // Helpers / Tasks
  // -----------------------------

  // Bounce the button around a target level for N edges
  task automatic bounce_around(input bit target_level, input int edges);
    int i;
    for (i = 0; i < edges; i++) begin
      @(posedge clk);
      button_in <= ~target_level;
      @(posedge clk);
      button_in <= target_level;
    end
  endtask

  // Hold button at level for N clock edges
  task automatic hold_level(input bit level, input int cycles);
    int i;
    for (i = 0; i < cycles; i++) begin
      @(posedge clk);
      button_in <= level;
    end
  endtask

  // One complete user press: press with bounce, hold long enough to pass debouncer,
  // then release with bounce.
  task automatic press_and_release(
      input int pre_bounce_edges,
      input int stable_press_cycles,
      input int post_bounce_edges,
      input int stable_release_cycles
  );
    // press + bounce near 1
    bounce_around(1'b1, pre_bounce_edges);
    // stable high
    hold_level(1'b1, stable_press_cycles);
    // release + bounce near 0
    bounce_around(1'b0, post_bounce_edges);
    // stable low
    hold_level(1'b0, stable_release_cycles);
  endtask

  // -----------------------------
  // Simple checks/monitors
  // -----------------------------
  reg [7:0] prev_count;
  always @(posedge clk) begin
    prev_count <= count;
    // When a debounced pulse is present, count should increment by 1
    if (increment_pulse) begin
      // Best-effort check on next cycle (counter increments on clk)
      @(posedge clk);
      if (count !== (prev_count + 1)) begin
        $display("[%0t] ERROR: Expected count=%0d but got %0d after pulse",
                 $time, prev_count + 1, count);
      end else begin
        $display("[%0t] OK: count incremented to %0d", $time, count);
      end
    end
  end

  // Optional pulse width check (expect 1-cycle pulse if your debouncer is pulse-type)
  // If your debouncer outputs a level instead, comment this out.
  always @(posedge clk) begin
    if (increment_pulse) begin
      // It is HIGH this cycle; ensure it is LOW next cycle (1-cycle pulse)
      @(posedge clk);
      if (increment_pulse !== 1'b0) begin
        $display("[%0t] WARN: increment_pulse wider than 1 cycle", $time);
      end
    end
  end

  // -----------------------------
  // Test sequence
  // -----------------------------
  initial begin
    // Initial values
    button_in = 1'b0;

    // Hold reset active (LOW) for a few cycles
    repeat (5) @(posedge clk);
    reset = 1'b1;           // deassert reset (ACTIVE-LOW)
    repeat (3) @(posedge clk);

    // 1) Clean press (with some bounce), enough stable time to pass debouncer
    //    Use stable_press_cycles >= TB_COUNT_MAX to guarantee a valid event.
    $display("[%0t] TEST: press #1", $time);
    press_and_release(
      /*pre_bounce_edges=*/3,
      /*stable_press_cycles=*/TB_COUNT_MAX + 2,
      /*post_bounce_edges=*/2,
      /*stable_release_cycles=*/TB_COUNT_MAX + 2
    );

    // 2) Short/too-bouncy press (should NOT increment if stable time < COUNT_MAX)
    $display("[%0t] TEST: short noisy press (should NOT count)", $time);
    bounce_around(1'b1, 4);              // bounce near 1
    hold_level(1'b1, TB_COUNT_MAX/2);    // not long enough
    bounce_around(1'b0, 3);              // bounce near 0
    hold_level(1'b0, TB_COUNT_MAX + 2);  // settle low

    // 3) Two valid presses back-to-back
    $display("[%0t] TEST: press #2", $time);
    press_and_release(2, TB_COUNT_MAX + 3, 2, TB_COUNT_MAX + 2);

    $display("[%0t] TEST: press #3", $time);
    press_and_release(1, TB_COUNT_MAX + 4, 1, TB_COUNT_MAX + 2);

    // 4) Long hold (should count only once)
    $display("[%0t] TEST: long hold (one increment only)", $time);
    bounce_around(1'b1, 2);
    hold_level(1'b1, TB_COUNT_MAX + 20);
    hold_level(1'b1, TB_COUNT_MAX + 20); // extra hold still one increment
    bounce_around(1'b0, 2);
    hold_level(1'b0, TB_COUNT_MAX + 5);

    // Finish
    repeat (20) @(posedge clk);
    $display("[%0t] DONE. Final count=%0d", $time, count);
    $finish;
  end

endmodule
