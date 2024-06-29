module PDC(
  // input port
  input             clk,
  input             rst,
  input          enable,
  input [7:0]   RAM_i_Q,
  input [7:0]   RAM_o_Q,
  // output port
  output reg       RAM_i_OE,
  output reg       RAM_i_WE,
  output reg [17:0] RAM_i_A,
  output reg [7:0]  RAM_i_D,
  output reg       RAM_o_OE,
  output reg       RAM_o_WE,
  output reg [17:0] RAM_o_A,
  output reg [7:0]  RAM_o_D,
  output reg           done
);

localparam IDLE = 4'd0;
localparam READ_ADJ = 4'd1;
localparam READ_DET = 4'd2;
localparam READ_COOR = 4'd3;
localparam FIND_P = 4'd4;
localparam R_W_r = 4'd5;
localparam R_W_g = 4'd6;
localparam R_W_b = 4'd7;
localparam BUFFER = 4'd8;
localparam FINISH = 4'd9;

reg [3:0] currentState, nextState;
reg [17:0] addr;
reg signed [103:0] adj [0:15];
reg signed [71:0] det;
reg signed [71:0] inv_a [0:15];
reg [7:0] coor [0:7];
reg [3:0] cnt;
reg [3:0] index;
reg signed [71:0] factor [0:7];

reg [15:0] pixel_loc; // Coordinate (row, column) = (pixel_loc[15:8], pixel_loc[7:0])
reg [71:0] ori_pixel_x;
reg [71:0] ori_pixel_y;
reg [7:0] round_x;
reg [7:0] round_y;
integer i;

always @(posedge clk) begin
	if (rst) currentState <= IDLE;
	else currentState <= nextState;
end

always @(*) begin
  case (currentState)
    IDLE: nextState = (enable)? READ_ADJ : IDLE;
    READ_ADJ: nextState = (addr == 18'd81)? READ_DET : READ_ADJ;
    READ_DET: nextState = (cnt == 4'd10)? READ_COOR : READ_DET;
    READ_COOR: nextState = (cnt == 4'd9)? FIND_P : READ_COOR;
    FIND_P: nextState = R_W_r;
    R_W_r: nextState = (cnt == 4'd2)? R_W_g : R_W_r;
    R_W_g: nextState = (cnt == 4'd2)? R_W_b : R_W_g;
    R_W_b: nextState = (cnt == 4'd2)? BUFFER : R_W_b;
    BUFFER: nextState = (pixel_loc == 16'd0)? FINISH : FIND_P;
    FINISH: nextState = IDLE;  
    default: nextState = IDLE;
  endcase
end

always @(posedge clk or posedge rst) begin
  if (rst) begin
    RAM_i_OE <= 0;
    RAM_i_WE <= 0;
    RAM_i_A <= 0;
    RAM_i_D <= 0;
    RAM_o_OE <= 0;
    RAM_o_WE <= 0;
    RAM_o_A <= 0;
    RAM_o_D <= 0;
    done <= 0;

    addr <= 0;
    cnt <= 0;
    index <= 0;
    det <= 0;
    pixel_loc <= {8'd0, 8'd0};
    ori_pixel_x <= 0;
    ori_pixel_y <= 0;
    for (i=0; i<16; i=i+1) begin
      adj[i] <= 0;
    end
    for (i=0; i<8; i=i+1) begin
      coor[i] <= 0;
    end
  end

  else begin
    case (currentState)
      IDLE: begin
        RAM_i_OE <= 0;
        RAM_i_WE <= 0;
        RAM_i_A <= 0;
        RAM_i_D <= 0;
        RAM_o_OE <= 0;
        RAM_o_WE <= 0;
        RAM_o_A <= 0;
        RAM_o_D <= 0;
        done <= 0;

        addr <= 0;
        cnt <= 0;
        index <= 0;
        det <= 0;
        pixel_loc <= {8'd0, 8'd0};
        ori_pixel_x <= 0;
        ori_pixel_y <= 0;
        for (i=0; i<16; i=i+1) begin
          adj[i] <= 0;
        end
        for (i=0; i<8; i=i+1) begin
          coor[i] <= 0;
        end
      end

      READ_ADJ: begin
        if (addr == 18'd81 && index == 4'd15) begin
          addr <= 18'd80;
        end
        else addr <= addr + 1;
        
        RAM_i_OE <= 1;
        RAM_i_A <= addr;

        if (addr > 1) begin
          if (cnt == 4'd4) begin
            cnt <= 0;
            index <= index + 1;  
          end
          else cnt <= cnt + 1;
          
          case (cnt)
            4'd0: adj[index][39:32] <= RAM_i_Q; 
            4'd1: adj[index][47:40] <= RAM_i_Q;
            4'd2: adj[index][55:48] <= RAM_i_Q;
            4'd3: adj[index][63:56] <= RAM_i_Q;
            4'd4: adj[index][71:64] <= RAM_i_Q;
          endcase
        end
      end

      READ_DET: begin
        RAM_i_A <= addr;
        if (addr == 18'd90) begin
          addr <= 18'd89;
          cnt <= 0;
        end
        
        else begin
          addr <= addr + 1;
          cnt <= cnt + 1;
        end 
        
        if (cnt > 4'd1) begin
          case (cnt)
            4'd2: det[7:0] <= RAM_i_Q;
            4'd3: det[15:8] <= RAM_i_Q;
            4'd4: det[23:16] <= RAM_i_Q;
            4'd5: det[31:24] <= RAM_i_Q;
            4'd6: det[39:32] <= RAM_i_Q;
            4'd7: det[47:40] <= RAM_i_Q;
            4'd8: det[55:48] <= RAM_i_Q;
            4'd9: det[63:56] <= RAM_i_Q;
            4'd10: det[71:64] <= RAM_i_Q;
          endcase 
        end
      end

      READ_COOR: begin
        RAM_i_A <= addr;
        addr <= addr + 1;
        cnt <= cnt + 1;
        if (cnt > 4'd1) begin
          coor[cnt-2] <= RAM_i_Q;
        end
      end

      FIND_P: begin
        cnt <= 0;
        RAM_i_OE <= 0;
        ori_pixel_x <= factor[0]*$signed({1'b0,pixel_loc[7:0]}) + factor[1]*$signed({1'b0,pixel_loc[15:8]}) + factor[2]*$signed({1'b0,pixel_loc[7:0]})*$signed({1'b0,pixel_loc[15:8]}) + factor[3];
        ori_pixel_y <= factor[4]*$signed({1'b0,pixel_loc[7:0]}) + factor[5]*$signed({1'b0,pixel_loc[15:8]}) + factor[6]*$signed({1'b0,pixel_loc[7:0]})*$signed({1'b0,pixel_loc[15:8]}) + factor[7];
      end

      R_W_r: begin
        cnt <= cnt + 1;

        if (cnt == 0) begin
          RAM_i_OE <= 1;
          RAM_i_A <= 18'd97 + {round_y, round_x};  
        end
        
        else if (cnt > 4'd1) begin
          RAM_o_WE <= 1;
          RAM_o_A <= pixel_loc;
          RAM_o_D <= RAM_i_Q;
          cnt <= 0;
        end
      end

      R_W_g: begin
        cnt <= cnt + 1;

        if (cnt == 0) begin
          RAM_i_OE <= 1;
          RAM_i_A <= 18'd65633 + {round_y, round_x};  
        end

        else if (cnt > 4'd1) begin
          RAM_o_WE <= 1;
          RAM_o_A <= 18'd65536 + pixel_loc;
          RAM_o_D <= RAM_i_Q;
          cnt <= 0;
        end
      end

      R_W_b: begin
        cnt <= cnt + 1;
        
        if (cnt == 0) begin
          RAM_i_OE <= 1;
          RAM_i_A <= 18'd131169 + {round_y, round_x};  
        end

        else if (cnt > 4'd1) begin
          pixel_loc <= pixel_loc + 1;
          RAM_o_WE <= 1;
          RAM_o_A <= 18'd131072 + pixel_loc;
          RAM_o_D <= RAM_i_Q;
          cnt <= 0;
        end
      end
      
      BUFFER: begin
        RAM_o_WE <= 0;
      end
      FINISH: begin
        done <= 1;
      end 
    endcase
  end
end

always @(*) begin
  for (i=0; i<16; i=i+1) begin
    inv_a[i] = (adj[i]<<32)/det;
  end
end

always @(*) begin
  for (i=0; i<8; i=i+1) begin
    if (i<4) begin
      factor[i] = $signed({1'b0, coor[0]})*inv_a[4*i] + $signed({1'b0, coor[2]})*inv_a[4*i+1] + $signed({1'b0, coor[4]})*inv_a[4*i+2] + $signed({1'b0, coor[6]})*inv_a[4*i+3]; 
    end
    else begin
      factor[i] = $signed({1'b0, coor[1]})*inv_a[4*(i-4)] + $signed({1'b0, coor[3]})*inv_a[4*(i-4)+1] + $signed({1'b0, coor[5]})*inv_a[4*(i-4)+2] + $signed({1'b0, coor[7]})*inv_a[4*(i-4)+3];
    end   
  end
end

always @(*) begin
  round_x = ori_pixel_x[39:32] + ori_pixel_x[31];
  round_y = ori_pixel_y[39:32] + ori_pixel_y[31];
end

endmodule

