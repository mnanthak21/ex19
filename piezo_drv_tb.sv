module piezo_drv_tb();

	input logic clk, rst_n, batt_low, fanfare;
	output logic piezo, piezo_n;

	piezo_drv iDUT(.clk(clk), .rst_n(rst_n), .batt_low(batt_low), .fanfare(fanfare), .piezo(piezo), .piezo_n(piezo_n));

	initial begin

		

	end

	always #20 clk = ~clk;

endmodule