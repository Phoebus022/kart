// This module take "mode" input and control two motors accordingly.
// clk should be 100MHz for PWM_gen module to work correctly.
// You can modify or add more inputs and outputs by yourself.
module motor(
    input clk,
    input rst,
    input [2:0]mode,
    output [1:0]pwm,
    output [1:0]r_IN,
    output [1:0]l_IN
);

    reg [9:0]left_motor, right_motor;
    wire left_pwm, right_pwm;

    motor_pwm m0(clk, rst, left_motor, left_pwm);
    motor_pwm m1(clk, rst, right_motor, right_pwm);

    assign pwm = {left_pwm,right_pwm};

    // TODO: control the speed
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            left_motor <= 10'd0;
            right_motor <= 10'd0;
        end else begin
            casez  (mode)
                3'b000: begin //stop
                    left_motor <= 10'd0;
                    right_motor <= 10'd0;
                end
                3'b001: begin //forward
                    left_motor <= 10'd200;
                    right_motor <= 10'd200;
                end
                3'b?10: begin //left
                    left_motor <= 10'd150;
                    right_motor <= 10'd200;
                end
                3'b?11: begin //right
                    left_motor <= 10'd200;
                    right_motor <= 10'd150;
                end
                default: begin
                    left_motor <= 10'd0;
                    right_motor <= 10'd0;
                end
            endcase
        end
    end

    assign l_IN = (mode == 3'b000) ? 2'b00 : (mode[2]) ? 2'b01 : 2'b10;
    assign r_IN = (mode == 3'b000) ? 2'b00 : (mode[2]) ? 2'b01 : 2'b10;

    
endmodule

module motor_pwm (
    input clk,
    input reset,
    input [9:0]duty,
	output pmod_1 //PWM
);
        
    PWM_gen pwm_0 ( 
        .clk(clk), 
        .reset(reset), 
        .freq(32'd25000),
        .duty(duty), 
        .PWM(pmod_1)
    );

endmodule

//generte PWM by input frequency & duty cycle
module PWM_gen (
    input wire clk,
    input wire reset,
	input [31:0] freq,
    input [9:0] duty,
    output reg PWM
);
    wire [31:0] count_max = 100_000_000 / freq;
    wire [31:0] count_duty = count_max * duty / 1024;
    reg [31:0] count;
        
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            PWM <= 0;
        end else if (count < count_max) begin
            count <= count + 1;
            // TODO: Set <PWM> accordingly
            if (count < count_duty)
                PWM <= 1;
            else
                PWM <= 0;
        end else begin
            count <= 0;
            PWM <= 0;
        end
    end
endmodule

