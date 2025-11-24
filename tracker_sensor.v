module tracker_sensor(clk, reset, left_track, right_track, mid_track, state);
    input clk;
    input reset;
    input left_track, right_track, mid_track;
    output reg [2:0] state;

    localparam STOP  = 3'b000;
    localparam FORWARD = 3'b001;
    localparam BACKWARD = 3'b101;
    localparam LEFT  = 3'b010;
    localparam BACKLEFT = 3'b110;
    localparam RIGHT = 3'b011;
    localparam BACKRIGHT = 3'b111;
    /*
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= STOP;
        end else begin
            state <= FORWARD;
        end
    end
    */

    wire [2:0] dir = {left_track, mid_track, right_track};

    reg [2:0] last_dir; 
    wire ms_clk;
    clock_divider #(16) clk_div_inst(.clk(clk), .clk_div(ms_clk));

    //recovery system
    //如果過了3000ms(3s)還沒找到線，就進入recovery模式
    reg [11:0] recovery_cnt;
    always @(posedge ms_clk or posedge reset) begin
        if (reset) begin
            recovery_cnt <= 0;
        end else begin
            if (dir == 3'b111) begin
                if (recovery_cnt < 12'd3000) begin
                    recovery_cnt <= recovery_cnt + 1;
                end
            end else begin
                recovery_cnt <= 0;
            end
        end
    end

    always @(posedge ms_clk or posedge reset) begin
        if (reset) begin
            state    <= STOP;
            last_dir <= 3'b111;
        end else begin
            if (dir != 3'b111) begin
                last_dir <= dir;
            end

            //find the direction
            if (dir == 3'b111) begin
                if(recovery_cnt >= 12'd3000) begin
                    casez  (last_dir)
                        3'b0??:  state <= BACKLEFT;
                        3'b??0:  state <= BACKRIGHT;
                        3'b101:  state <= BACKWARD;
                        default: state <= STOP;
                    endcase
                end else begin
                    casez (last_dir)
                        3'b0??:  state <= LEFT;
                        3'b??0:  state <= RIGHT;
                        3'b101:  state <= FORWARD;
                        default: state <= STOP;
                    endcase
                end
            end else begin
                // line tracking
                case (dir)
                    3'b101, 
                    3'b000:     
                        state <= FORWARD;

                    3'b011,    
                    3'b001:  
                        state <= LEFT; 

                    3'b110,
                    3'b100:    
                        state <= RIGHT;

                    default:
                        state <= FORWARD;
                endcase
            end
        end
    end

endmodule
