module Project(
	input        CLOCK_50,
	input        RESET_N,
	input  [3:0] KEY,
	input  [9:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [9:0] LEDR
);

  // The reset signal comes from the reset button on the DE0-CV board
  // RESET_N is active-low, so we flip its value ("reset" is active-high)
  wire clk,locked;
  
  
  // this is when the clock is in SET mode, the display blinks
  reg blinkMode;

	
  // The PLL is wired to produce clk and locked signals for our logic
  Pll myPll(
    .refclk(CLOCK_50),
	 .rst      (!RESET_N),
	 .outclk_0 (clk),
    .locked   (locked)
  );
  wire reset=!locked;
  wire clk = CLOCK_50;

	parameter
		CLOCK_DISP=1'b0,
		CLOCK_SET=1'b1,
		NO_TRANSITION = 1'b0, // if you're not adding
		TRANSITION = 1'b1;
		
		
		
	//this is the variable for current display mode
	reg mode = CLOCK_DISP;
	
	//setting keys for old and new keys for key pressed transition
	reg [3:0] oldKEY = 4'b0;
	wire [3:0] transKey;
	
	parameter
		TICKS_PER_CENTISEC=20'd600_000,
		CENTISECS_PER_SEC=7'd100;
	reg [19:0] ticks <= 20'd0;
	reg [6:0]  centisecs<=7'd0;
	reg [3:0] buttonSec<=4'd0;
	reg [3:0]  hrs_hi,hrs_lo,min_hi,min_lo,sec_hi,sec_lo;

	always @(posedge clk or posedge reset) begin
		if (clk) begin
			
		
			case(mode)
				CLOCK_SET: begin
					
				end
				CLOCK_DISP :begin
					blinkMode<=0;
				end
			default:;
			endcase
		end
		if(reset) begin
			mode<=CLOCK_DISP;
			ticks<=20'd0;
			centisecs<=7'd0;
			{hrs_hi,hrs_lo,min_hi,min_lo,sec_hi,sec_lo}<=24'h235949;
		end else begin
			ticks<=ticks+20'd1;
			if(ticks==TICKS_PER_CENTISEC-1) begin
				ticks<=0;
				centisecs<=centisecs+7'd1;
				if(centisecs==CENTISECS_PER_SEC-1) begin
					centisecs<=0;
					sec_lo<=sec_lo+4'd1; // now at 100 centisec, sec = 1;
					if(sec_lo==4'd9) begin
						sec_lo<=0; // reset the lower sec 
						sec_hi<=sec_hi+4'd1;// increase the higher sec, examplpe from 9 ->10
						if(sec_hi==5) begin
							sec_hi<=0;
							min_lo<= min_lo+4'd1;
							if (min_lo == 9) begin
								min_lo<= 0;
								min_hi<=min_hi+4'd1;
								if (min_hi == 5) begin
									min_hi<=0;
									hrs_lo<=hrs_lo+4'd1;
									if (hrs_hi < 2 && hrs_lo == 9) begin
										hrs_hi<=hrs_hi+4'd1;
										hrs_lo<=0;
									end else if(hrs_hi ==2 && hrs_lo==3) begin
										mode<=CLOCK_DISP;
										ticks<=20'd0;
										centisecs<=7'd0;
										{hrs_hi,hrs_lo,min_hi,min_lo,sec_hi,sec_lo}<=24'h000000;
									end
								end
							end
								
						end
					end
				end
			end
		end
	end
	SevenSeg ss0(.IN(sec_lo),.OFF(1'b0),.OUT(HEX0));
	SevenSeg ss1(.IN(sec_hi),.OFF(1'b0),.OUT(HEX1));
	SevenSeg ss2(.IN(min_lo),.OFF(1'b0),.OUT(HEX2));
	SevenSeg ss3(.IN(min_hi),.OFF(1'b0),.OUT(HEX3));
	SevenSeg ss4(.IN(hrs_lo),.OFF(1'b0),.OUT(HEX4));
	SevenSeg ss5(.IN(hrs_hi),.OFF(1'b0),.OUT(HEX5));
	assign LEDR=SW^{~KEY,~KEY};
endmodule
