module median_fliter(
  // input port
  input                  clk,
  input                  rst,
  input               enable,
  input  [7:0]     RAM_IMG_Q,
  input  [7:0]     RAM_OUT_Q,
  // output port
  output reg         RAM_IMG_OE,
  output reg         RAM_IMG_WE,
  output reg [15:0]    RAM_IMG_A,
  output reg [7:0]     RAM_IMG_D,
  output reg         RAM_OUT_OE,
  output reg         RAM_OUT_WE,
  output reg [15:0]    RAM_OUT_A,
  output reg [7:0]     RAM_OUT_D,
  output reg               done
);

localparam IDLE = 2'd0;
localparam READ = 2'd1;
localparam WRITE = 2'd2;
localparam FINISH = 2'd3;


reg [1:0] state, nextstate;
reg [15:0] center; // Coordinate (row, column) = (center[15:8], center[7:0])
reg [3:0] counter;
reg zeropad, last_zeropad;

reg [7:0] sortNum1_i, sortNum2_i, sortNum3_i, sortNum4_i, sortNum5_i, sortNum6_i, sortNum7_i, sortNum8_i, sortNum9_i;
reg [7:0] max11, max21, max31, max41, max51, max61;
reg [7:0] med11, med21, med31, med61;
reg [7:0] min11, min21, min31, min41, min51, min61;

reg [7:0] max12, max22, max32, max42, max52;
reg [7:0] med12, med22, med32, med42;
reg [7:0] min12, min22, min32, min42, min52;

reg [7:0] max13, max23;
reg [7:0] med13, med23;
reg [7:0] min13, min23;



always @(posedge clk) begin
  if(rst) state <= IDLE;
  else state <= nextstate;  
end

always @(*) begin
  case (state)
    IDLE: nextstate = READ;
    READ: nextstate = (counter == 4'd9)? WRITE : READ;
    WRITE: nextstate = (center == 16'd65535)? FINISH : READ;
    FINISH: nextstate = FINISH; 
    default: nextstate = IDLE;
  endcase
end

always @(posedge clk) begin
  if(rst) begin
    RAM_IMG_OE <= 0;
    RAM_IMG_WE <= 0;
    RAM_IMG_A <= 0;
    RAM_IMG_D <= 0;
    RAM_OUT_OE <= 0;
    RAM_OUT_WE <= 0;
    RAM_OUT_A <= 0;
    RAM_OUT_D <= 0;
    done <= 0;

    center <= {8'd0 , 8'd0};
		counter <= 4'd0;
    zeropad <= 1'b0;
    last_zeropad <= 1'b0;
    sortNum1_i <= 0; 
    sortNum2_i <= 0;
    sortNum3_i <= 0; 
    sortNum4_i <= 0; 
    sortNum5_i <= 0; 
    sortNum6_i <= 0; 
    sortNum7_i <= 0; 
    sortNum8_i <= 0; 
    sortNum9_i <= 0;
    
    
  end

  else begin
    case (state)
      IDLE: begin
        center <= {8'd0 , 8'd0};
        counter <= 4'd0;
        zeropad <= 1'b0;
        last_zeropad <= 1'b0;
        sortNum1_i <= 0; 
        sortNum2_i <= 0;
        sortNum3_i <= 0; 
        sortNum4_i <= 0; 
        sortNum5_i <= 0; 
        sortNum6_i <= 0; 
        sortNum7_i <= 0; 
        sortNum8_i <= 0; 
        sortNum9_i <= 0;
      end
      READ: begin
        counter <= counter + 1;
        RAM_IMG_OE <= 1;
        RAM_OUT_WE <= 0;
        last_zeropad <= zeropad;

        if(counter>0) begin
          case (counter)
            4'd1: sortNum1_i <= (~last_zeropad)? RAM_IMG_Q : 0; 
            4'd2: sortNum2_i <= (~last_zeropad)? RAM_IMG_Q : 0;
            4'd3: sortNum3_i <= (~last_zeropad)? RAM_IMG_Q : 0;
            4'd4: sortNum4_i <= (~last_zeropad)? RAM_IMG_Q : 0;
            4'd5: sortNum5_i <= (~last_zeropad)? RAM_IMG_Q : 0;
            4'd6: sortNum6_i <= (~last_zeropad)? RAM_IMG_Q : 0;
            4'd7: sortNum7_i <= (~last_zeropad)? RAM_IMG_Q : 0;
            4'd8: sortNum8_i <= (~last_zeropad)? RAM_IMG_Q : 0;
            4'd9: sortNum9_i <= (~last_zeropad)? RAM_IMG_Q : 0;
          endcase 
        end       
      end
      WRITE: begin
        RAM_IMG_OE <= 0;
        counter <= 0;
        RAM_OUT_WE <= 1;
        RAM_OUT_A <= center;
        RAM_OUT_D <= med61;
        center <= center + 1;
      end
      FINISH: done <= 1;
    endcase
  end
end

always @(*) begin
  case (counter)
    4'd0: begin
      if(center[15:8]==0 | center[7:0]==0) zeropad = 1;
      else zeropad = 0;
    end
    4'd1: begin
      if(center[15:8]==0) zeropad = 1;
      else zeropad = 0;
    end
    4'd2: begin
      if(center[15:8]==0 | center[7:0]==255) zeropad = 1;
      else zeropad = 0;
    end
    4'd3: begin
      if(center[7:0]==0) zeropad = 1;
      else zeropad = 0;
    end
    4'd4: begin
      zeropad = 0;
    end
    4'd5: begin
      if(center[7:0]==255) zeropad = 1;
      else zeropad = 0;
    end
    4'd6: begin
      if(center[15:8]==255 | center[7:0]==0) zeropad = 1;
      else zeropad = 0;
    end
    4'd7: begin
      if(center[15:8]==255) zeropad = 1;
      else zeropad = 0;
    end
    4'd8: begin
      if(center[15:8]==255 | center[7:0]==255) zeropad = 1;
      else zeropad = 0;
    end 
    default: zeropad = zeropad;
  endcase
end

always @(*) begin
  if(~zeropad) begin
    case (counter)
      0,1,2: RAM_IMG_A[15:8] = center[15:8] - 8'd1;
      3,4,5: RAM_IMG_A[15:8] = center[15:8];
      6,7,8: RAM_IMG_A[15:8] = center[15:8] + 8'd1;
    endcase

    case (counter)
      0,3,6: RAM_IMG_A[7:0] = center[7:0] - 8'd1; 
      1,4,7: RAM_IMG_A[7:0] = center[7:0];
      2,5,8: RAM_IMG_A[7:0] = center[7:0] + 8'd1; 
    endcase    
  end
  else RAM_IMG_A = 0;
end

always @(*) begin
  // Level1
        max11 = (sortNum1_i>sortNum2_i)?(sortNum1_i>sortNum3_i)?sortNum1_i:sortNum3_i : (sortNum2_i>sortNum3_i)?sortNum2_i:sortNum3_i;
        med11 = (sortNum1_i<sortNum2_i)?(sortNum2_i<sortNum3_i)?sortNum2_i:(sortNum1_i>sortNum3_i)?sortNum1_i:sortNum3_i : (sortNum2_i>sortNum3_i)?sortNum2_i:(sortNum1_i<sortNum3_i)?sortNum1_i:sortNum3_i;
        min11 = (sortNum1_i<sortNum2_i)?(sortNum1_i<sortNum3_i)?sortNum1_i:sortNum3_i : (sortNum2_i>sortNum3_i)?sortNum3_i:sortNum2_i;

        max12 = (sortNum4_i>sortNum5_i)?(sortNum4_i>sortNum6_i)?sortNum4_i:sortNum6_i : (sortNum5_i>sortNum6_i)?sortNum5_i:sortNum6_i;
        med12 = (sortNum4_i<sortNum5_i)?(sortNum5_i<sortNum6_i)?sortNum5_i:(sortNum4_i>sortNum6_i)?sortNum4_i:sortNum6_i : (sortNum5_i>sortNum6_i)?sortNum5_i:(sortNum4_i<sortNum6_i)?sortNum4_i:sortNum6_i;
        min12 = (sortNum4_i<sortNum5_i)?(sortNum4_i<sortNum6_i)?sortNum4_i:sortNum6_i : (sortNum5_i>sortNum6_i)?sortNum6_i:sortNum5_i;

        max13 = (sortNum7_i>sortNum8_i)?(sortNum7_i>sortNum9_i)?sortNum7_i:sortNum9_i : (sortNum8_i>sortNum9_i)?sortNum8_i:sortNum9_i;
        med13 = (sortNum7_i<sortNum8_i)?(sortNum8_i<sortNum9_i)?sortNum8_i:(sortNum7_i>sortNum9_i)?sortNum7_i:sortNum9_i : (sortNum8_i>sortNum9_i)?sortNum8_i:(sortNum7_i<sortNum9_i)?sortNum7_i:sortNum9_i;
        min13 = (sortNum7_i<sortNum8_i)?(sortNum7_i<sortNum9_i)?sortNum7_i:sortNum9_i : (sortNum8_i>sortNum9_i)?sortNum9_i:sortNum8_i;

        // Level2
        max21 = (max11>max12)?(max11>max13)?max11:max13 : (max12>max13)?max12:max13; // 最大值
        med21 = (max11<max12)?(max12<max13)?max12:(max11>max13)?max11:max13 : (max12>max13)?max12:(max11<max13)?max11:max13;
        min21 = (max11<max12)?(max11<max13)?max11:max13 : (max12>max13)?max13:max12;

        max22 = (med11>med12)?(med11>med13)?med11:med13 : (med12>med13)?med12:med13;
        med22 = (med11<med12)?(med12<med13)?med12:(med11>med13)?med11:med13 : (med12>med13)?med12:(med11<med13)?med11:med13;
        min22 = (med11<med12)?(med11<med13)?med11:med13 : (med12>med13)?med13:med12;

        max23 = (min11>min12)?(min11>min13)?min11:min13 : (min12>min13)?min12:min13;
        med23 = (min11<min12)?(min12<min13)?min12:(min11>min13)?min11:min13 : (min12>min13)?min12:(min11<min13)?min11:min13;
        min23 = (min11<min12)?(min11<min13)?min11:min13 : (min12>min13)?min13:min12; // 最小值

        // Level3
        max31 = (med21>max22)?(med21>max23)?med21:max23 : (max22>max23)?max22:max23; // 第二大
        med31 = (med21<max22)?(max22<max23)?max22:(med21>max23)?med21:max23 : (max22>max23)?max22:(med21<max23)?med21:max23;
        min31 = (med21<max22)?(med21<max23)?med21:max23 : (max22>max23)?max23:max22;

        max32 = (min21>min22)?(min21>med23)?min21:med23 : (min22>med23)?min22:med23;
        med32 = (min21<min22)?(min22<med23)?min22:(min21>med23)?min21:med23 : (min22>med23)?min22:(min21<med23)?min21:med23;
        min32 = (min21<min22)?(min21<med23)?min21:med23 : (min22>med23)?med23:min22; // 第二小

        // Level4
        max41 = (med31>min31) ? med31:min31;
        min41 = (med31>min31) ? min31:med31;

        max42 = (med22>max32)?(med22>med32)?med22:med32 : (max32>med32)?max32:med32;
        med42 = (med22<max32)?(max32<med32)?max32:(med22>med32)?med22:med32 : (max32>med32)?max32:(med22<med32)?med22:med32;
        min42 = (med22<max32)?(med22<med32)?med22:med32 : (max32>med32)?med32:max32;

        // level5
        max51 = (max41>max42) ? max41:max42; // 第三大
        min51 = (max41>max42) ? max42:max41;

        max52 = (min41>min42) ? min41:min42; 
        min52 = (min41>min42) ? min42:min41; // 第三小

        // Level6
        max61 = (min51>med42)?(min51>max52)?min51:max52 : (med42>max52)?med42:max52; // 第四大
        med61 = (min51<med42)?(med42<max52)?med42:(min51>max52)?min51:max52 : (med42>max52)?med42:(min51<max52)?min51:max52; // 第五大
        min61 = (min51<med42)?(min51<max52)?min51:max52 : (med42>max52)?max52:med42; // 第六大
end
endmodule