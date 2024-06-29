`timescale 1ns/10ps

module  CED(
	input  clk,
	input  rst,
	input  enable,
	output reg ird,
	input  [7:0] idata,	
	output reg [13:0] iaddr,
	output reg cwr_mag_0,
	output reg [12:0] cdata_mag_wr0,
	output reg crd_mag_0,
	input  [12:0] cdata_mag_rd0,
	output reg [13:0] caddr_mag_0,
	output reg cwr_ang_0,
	output reg [12:0] cdata_ang_wr0,
	output reg crd_ang_0,
	input  [12:0] cdata_ang_rd0,
	output reg [13:0] caddr_ang_0,
	output reg cwr1,
	output reg [12:0] cdata_wr1,
	output reg crd1,
	input  [12:0] cdata_rd1,
	output reg [13:0] caddr_1,
	output reg cwr2,
	output reg [12:0] cdata_wr2,
	output reg [13:0] caddr_2,
	output reg done
);

localparam IDLE = 3'd0;
localparam LAYER0 = 3'd1;
localparam WB0 = 3'd2;
localparam LAYER1 = 3'd3;
localparam WB1 = 3'd4;
localparam LAYER2= 3'd5;
localparam WB2 = 3'd6;
localparam FINISH = 3'd7;

wire signed [2:0] kernel_x [1:9];
wire signed [2:0] kernel_y [1:9];
assign kernel_x[1] = 3'b111; assign kernel_x[2] = 3'b000; assign kernel_x[3] = 3'b001;
assign kernel_x[4] = 3'b110; assign kernel_x[5] = 3'b000; assign kernel_x[6] = 3'b010;
assign kernel_x[7] = 3'b111; assign kernel_x[8] = 3'b000; assign kernel_x[9] = 3'b001;

assign kernel_y[1] = 3'b111; assign kernel_y[2] = 3'b110; assign kernel_y[3] = 3'b111;
assign kernel_y[4] = 3'b000; assign kernel_y[5] = 3'b000; assign kernel_y[6] = 3'b000;
assign kernel_y[7] = 3'b001; assign kernel_y[8] = 3'b010; assign kernel_y[9] = 3'b001;

reg [2:0] currentState, nextState;
reg [3:0] counter;
reg [13:0] center; // Coordinate (row, column) = (center[13:7], center[6:0])
reg signed [12:0] convSum_x, convSum_y;

wire signed [12:0] gx, gy, mag;
reg signed [28:0] temp_result;
reg [12:0] angle;
reg [13:0] l0_addr, l1_addr, l2_addr;
reg [13:0] I, J;
reg zero_flag;
reg [13:0] pix1_addr, pix2_addr;
reg signed [12:0] pix0, pix1;
reg nms_compare, threshold, first;
reg [1:0] hysteresis;

always @(posedge clk) begin
	if (rst) currentState <= IDLE;
	else currentState <= nextState;
end

always @(*) begin
	case (currentState)
		IDLE: nextState = (enable)? LAYER0 : IDLE;
		LAYER0: nextState = (counter == 4'd10)? WB0 : LAYER0;
		WB0: nextState = (center == 14'd16254)? LAYER1 : LAYER0;
		LAYER1: nextState = (zero_flag || counter == 4'd5)? WB1 : LAYER1;
		WB1: nextState = (l1_addr == 14'd15875)? LAYER2 : LAYER1;
		LAYER2: nextState = (zero_flag || threshold || counter == 4'd10 || first)? WB2 : LAYER2;
		WB2: nextState = (l2_addr == 14'd15875)? FINISH : LAYER2;
		FINISH: nextState = FINISH;
		default: nextState = IDLE; 
	endcase
end


always @(posedge clk) begin
	if (rst) begin
		ird <= 0;
		iaddr <= 0;
		cwr_mag_0 <= 0;
		cdata_mag_wr0 <= 0;
		crd_mag_0 <= 0;
		caddr_mag_0 <= 0;
		cwr_ang_0 <= 0;
		cdata_ang_wr0 <= 0;
		crd_ang_0 <= 0;
		caddr_ang_0 <= 0;
		cwr1 <= 0;
		cdata_wr1 <= 0;
		crd1 <= 0;
		caddr_1 <= 0;
		cwr2 <= 0;
		cdata_wr2 <= 0;
		caddr_2 <= 0;
		done <= 0;

		center <= {7'd1, 7'd1};
		counter <= 0;
		convSum_x <= 0;
		convSum_y <= 0;
		l0_addr <= 0;
		l1_addr <= 0;
		l2_addr <= 0;
		I <= 0;
		J <= 0;
		pix0 <= 0;
		pix1 <= 0;
		nms_compare <= 0;
		threshold <= 0;
		first <= 0;
	end

	else begin
		case (currentState)
			IDLE: begin
				center <= {7'd1, 7'd1};
				ird <= 0;
				iaddr <= 0;
				cwr_mag_0 <= 0;
				cdata_mag_wr0 <= 0;
				crd_mag_0 <= 0;
				caddr_mag_0 <= 0;
				cwr_ang_0 <= 0;
				cdata_ang_wr0 <= 0;
				crd_ang_0 <= 0;
				caddr_ang_0 <= 0;
				cwr1 <= 0;
				cdata_wr1 <= 0;
				crd1 <= 0;
				caddr_1 <= 0;
				cwr2 <= 0;
				cdata_wr2 <= 0;
				caddr_2 <= 0;
				done <= 0;
			end 
			
			LAYER0: begin
				ird <= 1'b1;
				cwr_mag_0 <= 1'b0;
				cwr_ang_0 <= 1'b0;

				if (counter > 4'd1) begin
					convSum_x <= convSum_x + $signed({1'b0,idata})*kernel_x[counter-1];
					convSum_y <= convSum_y + $signed({1'b0,idata})*kernel_y[counter-1];
				end

				counter <= counter + 1;

				case (counter)
					0,1,2: iaddr[13:7] <= center[13:7] - 1; 
					3,4,5: iaddr[13:7] <= center[13:7];
					6,7,8: iaddr[13:7] <= center[13:7] + 1;
				endcase

				case (counter)
					0,3,6: iaddr[6:0] <= center[6:0] - 1; 
					1,4,7: iaddr[6:0] <= center[6:0];
					2,5,8: iaddr[6:0] <= center[6:0] + 1;
				endcase
			end

			WB0: begin
				ird <= 1'b0;
				counter <= 0;
				convSum_x <= 0;
				convSum_y <= 0;
				if (center[6:0] == 7'd126) begin
					center <= {center[13:7]+7'd1, 7'd1};
				end
				else center <= center + 1;

				cwr_mag_0 <= 1'b1;
				cdata_mag_wr0 <= mag;
				caddr_mag_0 <= l0_addr;
				cwr_ang_0 <= 1'b1;
				cdata_ang_wr0 <= angle;
				caddr_ang_0 <= l0_addr;
				l0_addr <= l0_addr + 1;
			end

			LAYER1: begin
				cwr_mag_0 <= 1'b0;
				cwr_ang_0 <= 1'b0;
				cwr1 <= 1'b0;
				counter <= counter + 1;

				if (counter == 0) begin
					crd_ang_0 <= 1'b1;
					crd_mag_0 <= 1'b1;
					caddr_ang_0 <= I + J*126;
					caddr_mag_0 <= I + J*126;
				end
				else begin
					case (counter)
						2: begin
							caddr_mag_0 <= pix1_addr;
							pix0 <= cdata_mag_rd0;
						end  
						3: caddr_mag_0 <= pix2_addr;
						4: pix1 <= cdata_mag_rd0;
						5: nms_compare <= ((pix0 > pix1 || pix0 == pix1) && (pix0 > cdata_mag_rd0 || pix0 == cdata_mag_rd0))? 1'b1 : 1'b0;  
					endcase
					
				end				
			end

			WB1: begin
				counter <= 0;
				crd_ang_0 <= 1'b0;
				crd_mag_0 <= 1'b0;

				if (l1_addr == 14'd15875) begin
					I <= 0;
					J <= 0;
				end
				else begin
					if (I == 7'd125) begin
						I <= 0;
						J <= J + 1;
					end
					else I <= I + 1;
				end
				
				l1_addr <= l1_addr + 1;
				cwr1 <= 1'b1;
				caddr_1 <= l1_addr;
				if (zero_flag) begin
					cdata_wr1 <= 0;
				end
				else cdata_wr1 <= (nms_compare)? pix0 : 0;			
			end

			LAYER2: begin
				cwr2 <= 1'b0;
				cwr1 <= 1'b0;
				crd1 <= 1'b1;
				counter <= counter + 1;

				case (counter)
					0: caddr_1 <= I + J*126;
					1: caddr_1 <= I + J*126 - 127;
					2: caddr_1 <= I + J*126 - 126;
					3: caddr_1 <= I + J*126 - 125;
					4: caddr_1 <= I + J*126 - 1;
					5: caddr_1 <= I + J*126 + 1;
					6: caddr_1 <= I + J*126 + 125;
					7: caddr_1 <= I + J*126 + 126;
					8: caddr_1 <= I + J*126 + 127;
				endcase

				if ((counter > 1) && (~threshold) && (~first)) begin
					if (counter == 2 && (hysteresis == 2'd0 || hysteresis == 2'd1)) begin
						threshold <= (hysteresis == 2'd0)? 1'b1 : 1'b0;
						first <= 1'b1;
					end
					else begin
						threshold <= (hysteresis == 2'd0)? 1'b1 : 1'b0;
					end
				end
			end

			WB2: begin
				crd1 <= 1'b0;
				counter <= 0;
				threshold <= 0;
				first <= 0;
				if (l2_addr == 14'd15875) begin
					I <= 0;
					J <= 0;
				end
				else begin
					if (I == 7'd125) begin
						I <= 0;
						J <= J + 1;
					end
					else I <= I + 1;
				end
				
				l2_addr <= l2_addr + 1;
				cwr2 <= 1'b1;
				caddr_2 <= l2_addr;
				if (zero_flag) begin
					cdata_wr2 <= 0;
				end
				else cdata_wr2 <= (threshold)? 13'd255 : 13'd0;
			end

			FINISH: begin
				done <= 1;
			end 
		endcase
	end
end

//  gradient magnitude
assign gx = (convSum_x[12])? ~(convSum_x - 1) : convSum_x;
assign gy = (convSum_y[12])? ~(convSum_y - 1) : convSum_y;
assign mag = gx + gy;

// gradient direction
always @(*) begin
	if (convSum_x == 0 && convSum_y == 0) begin
		angle = 13'd0;
	end

	else if (convSum_x == 0) begin
		angle = 13'd90;
	end

	else begin
		temp_result = (convSum_y << 16) / convSum_x;
		if (temp_result < $signed(29'h1FFF95F7) && temp_result > $signed(29'h1FFD95F7)) begin
			angle = 13'd135;
		end
		else if (temp_result < $signed(29'h00006A09) && temp_result > $signed(29'h1FFF95F7)) begin
			angle = 13'd0;
		end
		else if (temp_result < $signed(29'h00026A09) && temp_result > $signed(29'h00006A09)) begin
			angle = 13'd45;
		end
		else angle = 13'd90;	
	end
end

// For Layer1 ang Layer2
always @(*) begin
	if (J==0 || J==125 || I==0 || I==125) begin
		zero_flag = 1'b1;
	end

	else zero_flag = 1'b0;
end

// For Layer1
always @(*) begin
	case (cdata_ang_rd0)
		13'd45: begin
			pix1_addr = I + J*126 - 125;
			pix2_addr = I + J*126 + 125;
		end
		13'd135: begin
			pix1_addr = I + J*126 - 127;
			pix2_addr = I + J*126 + 127;
		end
		13'd0: begin
			pix1_addr = I + J*126 - 1;
			pix2_addr = I + J*126 + 1;
		end
		13'd90: begin
			pix1_addr = I + J*126 - 126;
			pix2_addr = I + J*126 + 126;
		end 
		default: begin
			pix1_addr = 0;
			pix2_addr = 0;
		end
	endcase
end

// For Layer2
always @(*) begin
	if (cdata_rd1 > 13'd100 || cdata_rd1 == 13'd100) begin
		hysteresis = 2'd0;
	end

	else if (cdata_rd1 < 13'd50) begin
		hysteresis = 2'd1;
	end

	else hysteresis = 2'd2;
end

endmodule