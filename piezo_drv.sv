module piezo_drv(clk, rst_n, batt_low, fanfare, piezo, piezo_n);

input logic clk, rst_n, batt_low, fanfare;
output logic piezo, piezo_n;

typedef enum logic [2:0] {IDLE, N1, N2, N3, N4, N5, N6} state_t;
state_t state, nxt_state;

localparam clk_speed = 50000000;
parameter FAST_SIM = 0;

localparam note_dur = 8388608;
logic [4:0] note_dur_inc;

// note frequencies in Hz
localparam G6_HALF = 50000000 / (2 * 1568);  // ~15943
localparam C7_HALF = 50000000 / (2 * 2093);  // ~11944
localparam E7_HALF = 50000000 / (2 * 2637);  //  ~9482
localparam G7_HALF = 50000000 / (2 * 3136);  //  ~7972

logic [14:0] curr_half_period;


generate if (FAST_SIM) begin
		assign note_dur_inc = 16;
	end else begin
		assign note_dur_inc = 1;
	end
endgenerate

logic batt_low_run;
logic [24:0] curr_note_dur;


// note frequency counter
logic [24:0] freq_cnt;
logic freq_done;
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		freq_cnt <= 0;
	else if (state == IDLE || freq_done)
		freq_cnt <= 0;
	else
		freq_cnt <= freq_cnt + 1;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		freq_done <= 0;
	else if (freq_cnt >= curr_half_period) freq_done <= 1;
	else freq_done <= 0;
end

// note duration counter
logic [24:0] note_cnt;
logic note_done;
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		note_cnt <= 0;
	else if (note_cnt >= curr_note_dur)
		note_cnt <= 0;
	else if (!note_done)
		note_cnt <= note_cnt + note_dur_inc;
	else
		note_cnt <= note_cnt;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		note_done <= 0;
	else if (note_cnt >= curr_note_dur) begin
		note_done <= 1;
	end else note_done <= 0;
end

// batt_low_run FF
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		batt_low_run <= 0;
	else if (state == IDLE)
		batt_low_run <= batt_low;
end

// FSM update
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
end

// FSM comb logic
always_comb begin
	curr_half_period = 0;
	curr_note_dur = 0;
	nxt_state = state;
	
	case (state)
		IDLE: begin
			if (batt_low) begin
				nxt_state = N1;
			end else if (fanfare) begin
				nxt_state = N1;
			end
		end
		N1: begin
			curr_note_dur = note_dur;
			curr_half_period = G6_HALF;
			if (note_done) nxt_state = N2;
		end
		N2: begin
			curr_note_dur = note_dur;
			curr_half_period = C7_HALF;
			if (note_done) nxt_state = N3;
		end
		N3: begin
			curr_note_dur = note_dur;
			curr_half_period = E7_HALF;
			if (note_done) begin
				if (batt_low_run) nxt_state = N1;
				else nxt_state = N4;
			end
		end
		N4: begin
			curr_note_dur = note_dur + note_dur / 2;
			curr_half_period = G7_HALF;
			if (note_done) nxt_state = N5;
		end
		N5: begin
			curr_note_dur = note_dur / 2;
			curr_half_period = E7_HALF;
			if (note_done) nxt_state = N6;
		end
		N6: begin
			curr_note_dur = note_dur * 2;
			curr_half_period = G7_HALF;
			if (note_done) nxt_state = IDLE;
		end
		default: nxt_state = IDLE;
	endcase
end

logic piezo_out;
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		piezo_out <= 0;
	else if (state == IDLE)
		piezo_out <= 0;
	else if (freq_done)
		piezo_out <= ~piezo_out;
	else
		piezo_out <= piezo_out;
end

assign piezo = (state == IDLE) ? 1'b0 : piezo_out;
assign piezo_n = (state == IDLE) ? 1'b0 : ~piezo_out;

endmodule
