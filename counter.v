module counter (
    input  wire clk,
    input  wire reset,
    input  wire increment,
    output reg  [7:0] count
);


    always @(negedge reset) count <= 8'b00000000;

    always @(posedge clk) begin
        if (increment)
            count <= count + 1'b1;
    end
endmodule