module piezo_drv(clk, rst_n, batt_low, fanfare, piezo, piezo_n);

input logic clk, rst_n, batt_low, fanfare;
output logic piezo, piezo_n;

typedef enum logic [2:0] {IDLE, N1, N2, N3, N4, N5, N6} state_t;
state_t state, nxt_state;

localparam clk_speed = 50000000;
parameter FAST_SIM = 0;

localparam note_dur = 8388608;
logic [4:0] note_dur_inc;


generate if (FAST_SIM) begin
		assign note_dur_inc = 16;
	end else begin
		assign note_dur_inc = 1;
	end
endgenerate

logic batt_low_run;
logic [24:0] curr_note_dur;
logic [12:0] curr_freq;

// note frequency counter
logic [12:0] freq_cnt;
logic freq_done;
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		freq_cnt <= 0;
	else if (freq_done)
		freq_cnt <= 0;
	else
		freq_cnt <= freq_cnt + 1;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		freq_done <= 0;
	else if (freq_cnt == (clk_speed / curr_freq)) freq_done <= 1;
	else freq_done <= 0;
end

// note duration counter
logic [24:0] note_cnt;
logic note_done;
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		note_cnt <= 0;
	else if (!note_done)
		note_cnt <= note_cnt + note_dur_inc;
	else
		note_cnt <= note_cnt;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		note_done <= 0;
	else if (note_cnt == curr_note_dur) begin
		note_done <= 1;
		note_cnt <= 0;
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
	curr_freq = 0;
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
			curr_freq = 1568;
			if (note_done) nxt_state = N2;
		end
		N2: begin
			curr_note_dur = note_dur;
			curr_freq = 2093;
			if (note_done) nxt_state = N3;
		end
		N3: begin
			curr_note_dur = note_dur;
			curr_freq = 2637;
			if (note_done) begin
				if (batt_low_run) nxt_state = N1;
				else nxt_state = N4;
			end
		end
		N4: begin
			curr_note_dur = note_dur + note_dur / 2;
			curr_freq = 3136;
			if (note_done) nxt_state = N5;
		end
		N5: begin
			curr_note_dur = note_dur / 2;
			curr_freq = 2637;
			if (note_done) nxt_state = N6;
		end
		N6: begin
			curr_note_dur = note_dur * 2;
			curr_freq = 3136;
			if (note_done) nxt_state = IDLE;
		end
		default: nxt_state = IDLE;
	endcase
end

endmodule
