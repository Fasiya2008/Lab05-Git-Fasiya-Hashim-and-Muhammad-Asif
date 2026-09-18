`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Muddassir Ali

// Module Name: top_fsm_system
// Project Name: Counter
// Target Devices: Baasys 3
// 
//////////////////////////////////////////////////////////////////////////////////

module top_fsm_system (
    input wire clk,
    input wire pbin,
    input wire [15:0] physical_sw,
    output wire [15:0] physical_leds
);

    // DEBOUNCER (Cleans up the physical reset button signal)
    wire rst_clean;
  	wire [31:0] switch_data; // hold the value read from the switches
  	reg [31:0] led_write_data = 32'd0; // counter value here
  	wire slow_clk;
  
    debouncer rst_db (
      			.clk(clk),
        		.pbin(pbin), 
      				.pbout(rst_clean)	//generated a clean signal
    ); 

    
    
    leds switch_reader (
      			.clk(clk), .rst(rst_clean),
                    .btns(16'd0),			// Not used for this FSM
                    .writeData(32'd0),			// We don't write to switches
                    .writeEnable(1'b0),			// Disabled
                    .readEnable(1'b1),			// Always ON so we can monitor switches
                    .memAddress(30'd0),       
                    .switches(physical_sw),		// Plug in the physical switches
                    .readData(switch_data)		// output data 
    );
    
    switches led_writer (
                    .clk(clk), .rst(rst_clean),
                    .writeData(led_write_data),
                    .writeEnable(1'b1),         	// Always ON so LEDs update instantly
                    .readEnable(1'b0), .memAddress(30'd0),
                    .readData(),                	// Ignored
                    .leds(physical_leds)      
    );
    
    clock_divider ticker (
                    .clk_in(clk),          		// Feed it the 100MHz fast clock
                    .rst(rst_clean),       		// Feed it the clean reset signal
                    .clk_out(slow_clk)     		// It spits out the 1Hz slow clock!
    );

    // YOUR FSM AND COUNTER LOGIC
	// YOUR CODE HERE
	localparam IDLE  = 2'b00;
    localparam COUNT = 2'b01;
    localparam RESET = 2'b10;
    
    reg [1:0]  state   = IDLE;
    reg [15:0] counter = 16'd0;
    
    reg slow_clk_d = 1'b0;
    always @(posedge clk) slow_clk_d <= slow_clk;
    wire tick = slow_clk & ~slow_clk_d;
    
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                // self-loop: if switch = 0, nothing changes, stay here
                if (switch_data[15:0] != 16'd0) begin
                    counter <= switch_data[15:0];
                    led_write_data <= switch_data;
                    state <= COUNT;
                end
            end
             COUNT: begin
                if (rst_clean) begin
                    state <= RESET;
                end else if (tick) begin
                    if (counter == 16'd0) begin
                        state <= IDLE;
                    end else begin
                        counter        <= counter - 1'b1;
                        led_write_data <= {16'd0, counter - 1'b1};
                    end
                end
            end

            RESET: begin
                counter        <= 16'd0;
                led_write_data <= 32'd0;
                state          <= IDLE;   // count = 0, back to waiting
            end

            default: state <= IDLE;
        endcase
    end

endmodule