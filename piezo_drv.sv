module maze_solve(clk, rst_n, cmd_md, cmd0, lft_opn, rght_opn, mv_cmplt, sol_cmplt, strt_hdng, dsrd_hdng, strt_mv, stp_lft, stp_rght);

input logic clk, rst_n;
input logic cmd_md, cmd0;
input logic lft_opn, rght_opn;
input logic mv_cmplt, sol_cmplt;
output logic strt_hdng; 
output logic [11:0] dsrd_hdng;
output logic strt_mv;
output logic stp_lft, stp_rght;

//localparam clk_speed = 50000000;

// direction values
localparam hdng_north = 12'h000;
localparam hdng_west = 12'h3FF;
localparam hdng_south = 12'h7FF;
localparam hdng_east = 12'hC00;

logic lft_affn;
logic sensor1_opn;
logic sensor2_opn;
logic [11:0] current_hdg;


logic current_turning;

// if cmd[0] is high system is left affinty otherwise right affinity
assign lft_affn = cmd0;
assign current_hdg = hdng_north;

// sensor 1 and sesor 2 are based on if it is left or right affinity
assign sensor1_opn = (lft_affn) ? lft_opn : rght_opn;
assign sensor2_opn = (lft_affn) ? rght_opn : lft_opn;


// state declaraions
typedef enum logic [3:0] {IDLE, MV_FRWD, DONE, TURN_S1, TURN_S2, TURN_180} state_t;
state_t state, nxt_state;

// state machine flip flop
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
end

// state machine logic
always_comb begin
	// default outputs
    strt_hdng = 0;
	case (state)
        IDLE: begin
            if ((!cmd_md) && (mv_cmplt || !lft_opn || !rght_opn))begin
                nxt_state = MV_FRWD;
            end
        end

        MV_FRWD: begin
            if (sol_cmplt) begin
                nxt_state = DONE;
            end
            else if ((!sol_cmplt) && (sensor1_opn)) begin
                
                strt_hdng = 1;
                nxt_state = TURN_S1;
            end
            else if ((!sol_cmplt) && (!sensor1_opn) && (sensor2_opn)) begin
                strt_hdng = 1;
                nxt_state = TURN_S2;
            end
            else if ((!sol_cmplt) && (!sensor1_opn) && (!sensor2_opn)) begin
                // strt_hdng = 1;
                nxt_state = TURN_180;
            end
            else nxt_state = MV_FRWD;
            
        end

        TURN_S1: begin 
        
            if (lft_affn) begin 
                if (dsrd_hdng == hdng_north) current_hdg = hdng_west;
                if (dsrd_hdng == hdng_west) current_hdg = hdng_south;
                if (dsrd_hdng == hdng_south) current_hdg = hdng_east;
                if (dsrd_hdng == hdng_east) current_hdg = hdng_north;
            end
            else if (!lft_affn) begin
                if (dsrd_hdng == hdng_north) current_hdg = hdng_east;
                if (dsrd_hdng == hdng_east) current_hdg = hdng_south;
                if (dsrd_hdng == hdng_south) current_hdg = hdng_west;
                if (dsrd_hdng == hdng_west) current_hdg = hdng_north;
            end
            
        end

        TURN_S2: begin
            if (lft_affn) begin 
                if (dsrd_hdng == hdng_north) current_hdg = hdng_east;
                if (dsrd_hdng == hdng_east) current_hdg = hdng_south;
                if (dsrd_hdng == hdng_south) current_hdg = hdng_west;
                if (dsrd_hdng == hdng_west) current_hdg = hdng_north; 
            end
            else if (!lft_affn) begin
                if (dsrd_hdng == hdng_north) current_hdg = hdng_west;
                if (dsrd_hdng == hdng_west) current_hdg = hdng_south;
                if (dsrd_hdng == hdng_south) current_hdg = hdng_east;
                if (dsrd_hdng == hdng_east) current_hdg = hdng_north;   
            end

        end


        TURN_180: begin
            if (dsrd_hdng == hdng_north) current_hdg = hdng_south;
            if (dsrd_hdng == hdng_south) current_hdg = hdng_north;
            if (dsrd_hdng == hdng_west) current_hdg = hdng_east;
            if (dsrd_hdng == hdng_east) current_hdg = hdng_west; 
        end


        DONE: nxt_state = DONE;
		




        default: nxt_state = IDLE;
	endcase
end



// updates dsrd_hdng with current_hdg based on FSM outputs
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) dsrd_hdng = hdng_north;
	else if (strt_hdng == 1) dsrd_hdng = current_hdg;
	else dsrd_hdng = dsrd_hdng;
end




endmodule
