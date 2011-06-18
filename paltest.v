module paltest(
	input clk50,
	
	output led1,
	output led2,
	
	// VGA
	output vga_psave_n,
	output vga_hsync_n,
	output vga_vsync_n,
	output [7:0] vga_r,
	output [7:0] vga_g,
	output [7:0] vga_b,
	output vga_clk,
	inout vga_sda,
	output vga_sdc
);

/* unneeded signals */
assign vga_psave_n = 1'b1;
assign vga_hsync_n = 1'b1;
assign vga_vsync_n = 1'b1;
assign vga_sda = 1'bz;
assign vga_sdc = 1'b1;
assign vga_g = 8'd0;
assign vga_b = 8'd0;

/* blink LEDs */
reg [22:0] r;
always @(posedge clk50)
	r <= r + 23'd1;
assign led1 = r[22];
assign led2 = r[22];

assign vga_clk = 1'b0;
assign vga_r = 8'd0;

endmodule
