module piezo_drv(clk, rst_n, batt_low, fanfare, piezo, piezo_n);

input logic clk, rst_n, batt_low, fanfare;
output logic piezo, piezo_logic;

typedef enum logic [2:0] {IDLE, N1, N2, N3, N4, N5, N6} state_t;
state_t state, nxt_state;

logic clk_speed = 50'000'000;
parameter FAST_SIM = 0;

logic note_dur;
generate if (FAST_SIM) begin
	note_dur = 524288;
end else begin
	note_dur = 8388608;
end

// note frequency counter
logic note_cnt;
logic note_done;
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		note_cnt <= 0;
	else if (!note_done)
		note_cnt <= note_cnt + 1;
	else
		note_cnt <= note_cnt;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		note_done <= 0;
	else if (note_cnt == curr_note_dur) note_done <= 1;
	else note_done <= 0;
end

// note duration counter
logic note_cnt;
logic note_done;
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		note_cnt <= 0;
	else if (!note_done)
		note_cnt <= note_cnt + 1;
	else
		note_cnt <= note_cnt;
end

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		note_done <= 0;
	else if (note_cnt == curr_note_dur) note_done <= 1;
	else note_done <= 0;
end

// FSM update
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_stste;
end

// FSM comb logic
logic batt_low_run;
logic curr_note_dur;
always_comb begin
	batt_low_run = 0;
	curr_note_dur = 0;
	note_done = 0;
	nxt_state = state;
	
	case (state)
		IDLE: begin
			if (batt_low) begin
				batt_low_run=1;
				nxt_state = N1;
			end else if (fanfare) begin
				batt_low_run=0;
				nxt_state = N1;
		end
		N1: begin
			curr_note_dur = note_dur;
			if (note_done) nxt_state = N2;
		end
		N2: begin
			curr_note_dur = note_dur;
			if (note_done) nxt_state = N3;
		end
		N3: begin
			curr_note_dur = note_dur;
			if (note_done) begin
				if (batt_low_run) nxt_state = N1;
				else nxt_state = N4;
			end
		end
		N4: begin
			curr_note_dur = note_dur + note_dur / 2;
			if (note_done) nxt_state = N5;
		end
		N5: begin
			curr_note_dur = note_dur / 2;
			if (note_done) nxt_state = N6;
		end
		N6: begin
			curr_note_dur = note_dur * 2;
			if (note_done) nxt_state = IDLE;
		end
		default: note_nxt_state = IDLE;
	endcase
end

endmodule
