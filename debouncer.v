module debouncer #(
    parameter integer COUNT_MAX = 8
)(
    input  wire clk,
    input  wire reset,      // triggers on negedge (1->0)
    input  wire button_in,
    output reg  button_out
);

    reg [$clog2(COUNT_MAX)-1:0] count = 0;
    reg prev_in = 0;

    always @(posedge clk or negedge reset) begin
        if (reset) begin
            count      <= 0;
            prev_in    <= 0;
            button_out <= 0;
        end else begin
            // If button changed, restart counter
            if (button_in != prev_in) begin
                prev_in <= button_in;
                count   <= 0;
            end else begin
                // Input stable -> increment counter
                if (count < COUNT_MAX)
                    count <= count + 1;
                else
                    count <= count;
            end

            // Update output after stable input held long enough
            if (count == COUNT_MAX - 1)
                button_out <= button_in;

            // If button released (goes low), turn off immediately
            if (button_in == 0)
                button_out <= 0;
        end
    end

endmodule
