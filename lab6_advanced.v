module lab6_advanced(
    input clk,
    input rst,
    input start,
    input echo,
    input left_track,
    input right_track,
    input mid_track,
    output trig,
    output IN1,
    output IN2,
    output IN3, 
    output IN4,
    output left_pwm,
    output right_pwm,
    //Debug
    output reg [15:0] LED,
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY
);
    // We have connected the motor and sonic_top modules in the template file for you.
    // TODO: Control the motors with the information you get from ultrasonic sensor and 3-way track sensor.
    wire [2:0] mode;
    motor A(
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .pwm({left_pwm, right_pwm}),
        .l_IN({IN1, IN2}),
        .r_IN({IN3, IN4})
    );

    wire [19:0] distance;
    sonic_top B(
        .clk(clk), 
        .rst(rst), 
        .Echo(echo), 
        .Trig(trig),
        .distance(distance)
    );

    wire [2:0] track_mode;
    tracker_sensor C(
        .clk(clk),
        .reset(rst),
        .left_track(left_track),
        .right_track(right_track),
        .mid_track(mid_track),
        .state(track_mode)
    );

    wire start_op;
    buttons btn_start(.clk(clk), .btn(start), .btn_pulse(start_op));
    
    reg [1:0] state;
    localparam IDLE = 2'b00,
               GO = 2'b01,
               STOP = 2'b10;

/*FSM*/

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE: begin
                    if(start_op) state <= GO;
                    else state <= IDLE;
                end
                GO: begin
                    if(distance < 20) state <= STOP;
                    else state <= GO;
                end
                STOP: begin
                    if(distance >= 20) state <= GO;
                    else state <= STOP;
                end
            endcase
        end
    end

    assign mode = (state == GO) ? track_mode : 3'b000;

/*Debug*/
    reg [15:0] value;
    SevenSegment sevenseg_inst(
        .display(DISPLAY),
        .digit(DIGIT),
        .nums(value[15:0]),
        .rst(rst),
        .clk(clk)
    );

    //led
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            LED <= 16'b0;
            value <= 16'hffff;
        end else begin
            LED[15:13] <= {right_track, mid_track, left_track};
            LED[11:8] <= {IN1, IN2, IN3, IN4};
            value <= {4'b1111, {1'b0, mode}, 4'b1111, {2'b0, state}};
        end
    end


endmodule

/*helper modules*/
module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire rst,
	input wire clk
);
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
    	end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
    	end else begin
    		case (digit)
    			4'b1110 : begin
    					display_num <= nums[7:4];
    					digit <= 4'b1101;
    				end
    			4'b1101 : begin
						display_num <= nums[11:8];
						digit <= 4'b1011;
					end
    			4'b1011 : begin
						display_num <= nums[15:12];
						digit <= 4'b0111;
					end
    			4'b0111 : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end
    			default : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end				
    		endcase
    	end
    end
    
    always @ (*) begin
    	case (display_num)
    		0 : display = 7'b1000000;	//0000
			1 : display = 7'b1111001;   //0001
			2 : display = 7'b0100100;   //0010
			3 : display = 7'b0110000;   //0011
			4 : display = 7'b0011001;   //0100
			5 : display = 7'b0010010;   //0101
			6 : display = 7'b0000010;   //0110
			7 : display = 7'b1111000;   //0111
			8 : display = 7'b0000000;   //1000
			9 : display = 7'b0010000;	//1001
			15: display = 7'b0111111;   //-
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule