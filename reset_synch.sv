module reset_synch(clk, RST_n, rst_n);
 
    input  logic clk;    // 50MHz system clock
    input  logic RST_n;  // Asynchronous active-low reset from push button
    output logic rst_n;  // Synchronous active-low reset to rest of design
 
    logic flop1;
 
    // First flop: asserts async (RST_n low drives output low immediately)
    // Deasserts sync (1 propagates on rising clock edge)
    always_ff @(posedge clk, negedge RST_n) begin
        if (!RST_n)
            flop1 <= 1'b0;
        else
            flop1 <= 1'b1;
    end
 
    // Second flop: further synchronizes deassertion to eliminate metastability
    always_ff @(posedge clk, negedge RST_n) begin
        if (!RST_n)
            rst_n <= 1'b0;
        else
            rst_n <= flop1;
    end
 
endmodule
