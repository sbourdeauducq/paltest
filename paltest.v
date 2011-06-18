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

/* generate pixel clock (70ns period) */
wire pclk;
wire pclk_n;
wire pclk_dcm;
wire pclk_n_dcm;
DCM_SP #(
	.CLKDV_DIVIDE(2.0),		// 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5

	.CLKFX_DIVIDE(7),		// 1 to 32
	.CLKFX_MULTIPLY(2),		// 2 to 32

	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(20.0),
	.CLKOUT_PHASE_SHIFT("NONE"),
	.CLK_FEEDBACK("NONE"),
	.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("TRUE")
) clkgen_sys (
	.CLK0(),
	.CLK90(),
	.CLK180(),
	.CLK270(),

	.CLK2X(),
	.CLK2X180(),

	.CLKDV(),
	.CLKFX(pclk_dcm),
	.CLKFX180(pclk_n_dcm),
	.LOCKED(),
	.CLKFB(),
	.CLKIN(clk50),
	.RST(1'b0),
	.PSEN(1'b0)
);
BUFG b1(
	.I(pclk_dcm),
	.O(pclk)
);
BUFG b2(
	.I(pclk_n_dcm),
	.O(pclk_n)
);

/* forward pixel clock to DAC */
ODDR2 #(
	.DDR_ALIGNMENT("NONE"),
	.INIT(1'b0),
	.SRTYPE("SYNC")
) clock_forward (
	.Q(vga_clk),
	.C0(pclk),
	.C1(pclk_n),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0)
);

/* blink LEDs */
reg [21:0] r;
always @(posedge pclk)
	r <= r + 22'd1;
assign led1 = r[21];
assign led2 = r[21];

patgen patgen(
	.pclk(pclk),
	.sample_out(vga_r)
);

endmodule
