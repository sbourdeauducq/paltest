module patgen(
	input pclk,
	output reg [7:0] sample_out
);

wire [7:0] sample_active;
reg [1:0] sample_sel;
parameter SAS_SYNC = 2'd0;
parameter SAS_BLACK = 2'd1;
parameter SAS_ACTIVE = 2'd2;
always @(posedge pclk) begin
	case(sample_sel)
		SAS_SYNC: sample_out <= 8'd0;
		SAS_BLACK: sample_out <= 8'd77;
		default: sample_out <= 8'd77 + sample_active;
	endcase
end

reg [9:0] hcount;
wire eol = hcount == 10'd913; /* 64 usec */
always @(posedge pclk) begin
	if(eol)
		hcount <= 10'd0;
	else
		hcount <= hcount + 10'd1;
end

reg [8:0] scount;
reg scount_done;
reg [2:0] scount_sel;
parameter SCS_SHORT = 3'd0;
parameter SCS_LONG = 3'd1;
parameter SCS_NORMAL = 3'd2;
parameter SCS_PORCH = 3'd3;
parameter SCS_COUNT = 3'd4;
always @(posedge pclk) begin
	scount_done <= 1'b0;
	case(scount_sel)
		SCS_SHORT: scount <= 9'd28; /* 2 usec */
		SCS_LONG: scount <= 9'd428; /* 30 usec */
		SCS_NORMAL: scount <= 9'd56; /* 4 usec */
		SCS_PORCH: scount <= 9'd113; /* 8 usec */
		SCS_COUNT: begin
			if(scount == 9'd0)
				scount_done <= 1'b1;
			else
				scount <= scount - 9'd1;
		end
	endcase
end

reg [8:0] vcount;
wire eof = vcount == 9'd311;
always @(posedge pclk) begin
	if(eol) begin
		if(eof)
			vcount <= 9'd0;
		else
			vcount <= vcount + 9'd1;
	end
end

assign sample_active = vcount[4] ^ hcount[5] ? 8'd100 : 8'd0;

reg [4:0] state;
reg [4:0] next_state;

parameter LONGSYNC1 = 5'd0;
parameter LONGSYNC2 = 5'd1;
parameter LONGSYNC3 = 5'd2;
parameter LONGSYNC4 = 5'd3;
parameter LONGSYNC5 = 5'd4;
parameter LONGSYNC6 = 5'd5;
parameter LONGSYNC7 = 5'd6;
parameter LONGSYNC8 = 5'd7;
parameter XLONGSYNC1 = 5'd8;
parameter XLONGSYNC2 = 5'd9;
parameter XLONGSYNC3 = 5'd10;
parameter XLONGSYNC4 = 5'd11;
parameter SHORTSYNC1 = 5'd12;
parameter SHORTSYNC2 = 5'd13;
parameter SHORTSYNC3 = 5'd14;
parameter SHORTSYNC4 = 5'd15;
parameter NSYNC1 = 5'd16;
parameter NSYNC2 = 5'd17;
parameter PORCH1 = 5'd18;
parameter PORCH2 = 5'd19;
parameter ACTIVE = 5'd20;

always @(posedge pclk) begin
	if(eof & eol)
		state <= LONGSYNC1;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;
	
	sample_sel = SAS_BLACK;
	scount_sel = SCS_COUNT;
	
	case(state)
		LONGSYNC1: begin
			sample_sel = SAS_SYNC;
			scount_sel = SCS_LONG;
			next_state = LONGSYNC2;
		end
		LONGSYNC2: begin
			sample_sel = SAS_SYNC;
			if(scount_done)
				next_state = LONGSYNC3;
		end
		LONGSYNC3: begin
			sample_sel = SAS_BLACK;
			scount_sel = SCS_SHORT;
			next_state = LONGSYNC4;
		end
		LONGSYNC4: begin
			sample_sel = SAS_BLACK;
			if(scount_done)
				next_state = LONGSYNC5;
		end
		LONGSYNC5: begin
			sample_sel = SAS_SYNC;
			scount_sel = SCS_LONG;
			next_state = LONGSYNC6;
		end
		LONGSYNC6: begin
			sample_sel = SAS_SYNC;
			if(scount_done)
				next_state = LONGSYNC7;
		end
		LONGSYNC7: begin
			sample_sel = SAS_BLACK;
			if(eol) begin
				if(vcount == 9'd2)
					next_state = XLONGSYNC1;
				else
					next_state = LONGSYNC1;
			end
		end
		
		XLONGSYNC1: begin
			sample_sel = SAS_SYNC;
			scount_sel = SCS_LONG;
			next_state = XLONGSYNC2;
		end
		XLONGSYNC2: begin
			sample_sel = SAS_SYNC;
			if(scount_done)
				next_state = XLONGSYNC3;
		end
		XLONGSYNC3: begin
			sample_sel = SAS_BLACK;
			scount_sel = SCS_SHORT;
			next_state = XLONGSYNC4;
		end
		XLONGSYNC4: begin
			sample_sel = SAS_BLACK;
			if(scount_done)
				next_state = SHORTSYNC1;
		end
		
		SHORTSYNC1: begin
			sample_sel = SAS_SYNC;
			scount_sel = SCS_SHORT;
			next_state = SHORTSYNC2;
		end
		SHORTSYNC2: begin
			sample_sel = SAS_SYNC;
			if(scount_done)
				next_state = SHORTSYNC3;
		end
		SHORTSYNC3: begin
			sample_sel = SAS_BLACK;
			scount_sel = SCS_LONG;
			next_state = SHORTSYNC4;
		end
		SHORTSYNC4: begin
			sample_sel = SAS_BLACK;
			if(eol) begin
				if(vcount == 9'd4)
					next_state = NSYNC1;
				else
					next_state = SHORTSYNC4;
			end else if(scount_done)
				next_state = SHORTSYNC1;
		end
		
		NSYNC1: begin
			sample_sel = SAS_SYNC;
			scount_sel = SCS_NORMAL;
			next_state = NSYNC2;
		end
		NSYNC2: begin
			sample_sel = SAS_SYNC;
			if(scount_done)
				next_state = PORCH1;
		end
		PORCH1: begin
			sample_sel = SAS_BLACK;
			scount_sel = SCS_PORCH;
			next_state = PORCH2;
		end
		PORCH2: begin
			sample_sel = SAS_BLACK;
			if(scount_done)
				next_state = ACTIVE;
		end
		
		ACTIVE: begin
			sample_sel = SAS_ACTIVE;
			if(eol) begin
				if(vcount == 9'd309)
					next_state = SHORTSYNC1;
				else
					next_state = NSYNC1;
			end
		end
	endcase
end

endmodule
