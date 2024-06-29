module ALU(
  input  [15:0] src_A_i,
  input  [15:0] src_B_i,
  input  [2:0]  inst_i,
  input  [7:0]  sortNum1_i,
  input  [7:0]  sortNum2_i,
  input  [7:0]  sortNum3_i,
  input  [7:0]  sortNum4_i,
  input  [7:0]  sortNum5_i,
  input  [7:0]  sortNum6_i,
  input  [7:0]  sortNum7_i,
  input  [7:0]  sortNum8_i,
  input  [7:0]  sortNum9_i,
  output reg [7:0]  sortNum1_o,
  output reg [7:0]  sortNum2_o,
  output reg [7:0]  sortNum3_o,
  output reg [7:0]  sortNum4_o,
  output reg [7:0]  sortNum5_o,
  output reg [7:0]  sortNum6_o,
  output reg [7:0]  sortNum7_o,
  output reg [7:0]  sortNum8_o,
  output reg [7:0]  sortNum9_o,
  output reg [15:0] data_o
);

reg [16:0] temp;
reg [2:0] cmp;
reg signed [31:0] full_product;
reg signed [47:0] full_product2;
reg signed [79:0] tempfull_product;
reg signed [15:0] product, product_round, before_tanh;
reg first = 1'b0;
integer i;

reg [7:0] max11, max21, max31, max41, max51, max61;
reg [7:0] med11, med21, med31, med61;
reg [7:0] min11, min21, min31, min41, min51, min61;

reg [7:0] max12, max22, max32, max42, max52;
reg [7:0] med12, med22, med32, med42;
reg [7:0] min12, min22, min32, min42, min52;

reg [7:0] max13, max23;
reg [7:0] med13, med23;
reg [7:0] min13, min23;


always @(*) begin
    case(inst_i)
      3'b000: begin
        temp = {src_A_i[15], src_A_i} + {src_B_i[15], src_B_i};
        data_o = (~temp[16] & temp[15]) ? 16'b0111111111111111 :
                 (temp[16] & ~temp[15]) ? 16'b1000000000000000 : 
                  temp[15:0];
      end
      3'b001: begin
        temp = {src_A_i[15], src_A_i} - {src_B_i[15], src_B_i};
        data_o = (~temp[16] & temp[15]) ? 16'b0111111111111111 :
                 (temp[16] & ~temp[15]) ? 16'b1000000000000000 : 
                  temp[15:0];
      end
      3'b100: begin
        for(i=15; i>=0; i=i-1) begin
          if(src_A_i[i] & ~first) begin
            data_o = 15 - i;
            if(i!=0) begin
              first = 1'b1;
            end
            else begin
              first = 1'b0;
            end
          end
          else begin
            if(i==0) begin
              first = 1'b0;
            end
          end
        end   
      end
      3'b010: begin
        full_product = ($signed(src_A_i) * $signed(src_B_i));
        product = full_product[25:10];
        // round up or dwon
        product_round = (full_product[9:0]>10'b1000000000)? product + 1 : (full_product[9] & full_product[10])? product + 1 : product;
        // process overflow
        data_o = (src_A_i!=0 & src_B_i!=0)? (src_A_i[15] & src_B_i[15]) || (~src_A_i[15] & ~src_B_i[15])? (full_product[31:25]==7'b0)? product_round : {1'b0,{15{1'b1}}} : (full_product[31:25]=={7{1'b1}})? product_round : {1'b1,{15{1'b0}}} : 0;
        
        // if(full_product[9:0]>10'b1000000000) begin
        //   product_round = product + 1;
        // end
        // else begin
        //   if(full_product[9] & full_product[10]) begin
        //     product_round = product + 1;
        //   end
        //   else begin
        //     product_round = product;
        //   end
        // end

        
        // if((src_A_i[15] & src_B_i[15]) || (~src_A_i[15] & ~src_B_i[15])) begin
        //   if(src_A_i!=0 & src_B_i!=0) begin
        //     data_o = (full_product[31:25]==7'b0000000) ? product_round : 16'b0111111111111111;  {1'b1,{15{1'b0}}}
        //   end
        //   else begin
        //     data_o = 0;
        //   end
        // end
        // else begin
        //   if(src_A_i!=0 & src_B_i!=0) begin
        //     data_o = (full_product[31:25]==7'b1111111) ? product_round : 16'b1000000000000000;  
        //   end
        //   else begin
        //     data_o = 0;
        //   end
        // end
      end
      3'b101: begin
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

        sortNum1_o = min23;
        sortNum2_o = min32;
        sortNum3_o = min52;
        sortNum4_o = min61;
        sortNum5_o = med61;
        sortNum6_o = max61;
        sortNum7_o = max51;
        sortNum8_o = max31;
        sortNum9_o = max21;

      end
      3'b011: begin
        // Before hyperbolic tangent
        tempfull_product = $signed({6'b0,10'b1100110001})*$signed(src_A_i)*($signed(src_A_i)*$signed(src_A_i)*$signed({6'b0,10'b0000101110}) + $signed({17'b0,1'b1,30'b0}));
        before_tanh = (tempfull_product[39:0]>{1'b1,39'b0})? tempfull_product[55:40]+1 : (tempfull_product[39] & tempfull_product[40])? tempfull_product[55:40]+1 : tempfull_product[55:40];
                      
        // After hyperbolic tangent
        cmp = (before_tanh<$signed({6'b111110,10'b1000000000}) || before_tanh==$signed({6'b111110,10'b1000000000}))? 3'b000 :
              (before_tanh>$signed({6'b111110,10'b1000000000}) & (before_tanh<$signed({6'b111111,10'b1000000000}) || before_tanh==$signed({6'b111111,10'b1000000000})))? 3'b001 :
              (before_tanh>$signed({6'b111111,10'b1000000000}) & (before_tanh<$signed({6'b0,10'b1000000000}) || before_tanh==$signed({6'b0,10'b1000000000})))? 3'b010 :
              (before_tanh>$signed({6'b0,10'b1000000000}) & (before_tanh<$signed({6'b000001,10'b1000000000}) || before_tanh==$signed({6'b000001,10'b1000000000})))? 3'b011 :
              3'b100;

        case (cmp)
          3'b000: begin
            product_round = $signed({6'b111111,10'b0});
          end
          3'b001: begin
            full_product = before_tanh*$signed({6'b0,10'b1000000000})-$signed({12'b0,2'b01,18'b0});
            product_round = (full_product[9:0]>10'b1000000000)? full_product[25:10]+1 : (full_product[9] & full_product[10])? full_product[25:10]+1 : full_product[25:10];
          end
          3'b010: begin
            product_round = before_tanh;
          end
          3'b011: begin
            full_product = before_tanh*$signed({6'b0,10'b1000000000})+$signed({12'b0,2'b01,18'b0});
            product_round = (full_product[9:0]>10'b1000000000)? full_product[25:10]+1 : (full_product[9] & full_product[10])? full_product[25:10]+1 : full_product[25:10];
          end
          3'b100: begin
            product_round = $signed({6'b000001,10'b0});
          end 
          default: product_round = 0;
        endcase

        full_product2 = $signed({6'b0,10'b1000000000})*$signed(src_A_i)*($signed({6'b000001,10'b0})+product_round);
        data_o = (full_product2[19:0]>{1'b1,19'b0})? full_product2[35:20]+1 : (full_product2[19] & full_product2[20])? full_product2[35:20]+1 : full_product2[35:20];


        // if(before_tanh<$signed({6'b111110,10'b1000000000}) || before_tanh==$signed({6'b111110,10'b1000000000})) begin
        //   data_o = 0;
        // end

        // else if(before_tanh>$signed({6'b111110,10'b1000000000}) & (before_tanh<$signed({6'b111111,10'b1000000000}) || before_tanh==$signed({6'b111111,10'b1000000000}))) begin
        //   full_product = before_tanh*$signed({6'b0,10'b1000000000})-$signed({12'b0,2'b01,18'b0});
        //   product_round = (full_product[9:0]>10'b1000000000)? full_product[25:10]+1 : (full_product[9] & full_product[10])? full_product[25:10]+1 : full_product[25:10];

        //   full_product2 = $signed({6'b0,10'b1000000000})*$signed(src_A_i)*($signed({6'b000001,10'b0})+product_round);
        //   data_o = (full_product2[19:0]>{1'b1,19'b0})? full_product2[35:20]+1 : (full_product2[19] & full_product2[20])? full_product2[35:20]+1 : full_product2[35:20];
        // end

        // else if(before_tanh>$signed({6'b111111,10'b1000000000}) & (before_tanh<$signed({6'b0,10'b1000000000}) || before_tanh==$signed({6'b0,10'b1000000000}))) begin
        //   product_round = before_tanh;
          
        //   full_product2 = $signed({6'b0,10'b1000000000})*$signed(src_A_i)*($signed({6'b000001,10'b0})+product_round);
        //   data_o = (full_product2[19:0]>{1'b1,19'b0})? full_product2[35:20]+1 : (full_product2[19] & full_product2[20])? full_product2[35:20]+1 : full_product2[35:20];
        // end

        // else if(before_tanh>$signed({6'b0,10'b1000000000}) & (before_tanh<$signed({6'b000001,10'b1000000000}) || before_tanh==$signed({6'b000001,10'b1000000000}))) begin
        //   full_product = before_tanh*$signed({6'b0,10'b1000000000})+$signed({12'b0,2'b01,18'b0});
        //   product_round = (full_product[9:0]>10'b1000000000)? full_product[25:10]+1 : (full_product[9] & full_product[10])? full_product[25:10]+1 : full_product[25:10];

        //   full_product2 = $signed({6'b0,10'b1000000000})*$signed(src_A_i)*($signed({6'b000001,10'b0})+product_round);
        //   data_o = (full_product2[19:0]>{1'b1,19'b0})? full_product2[35:20]+1 : (full_product2[19] & full_product2[20])? full_product2[35:20]+1 : full_product2[35:20];
        // end

        // else begin
        //   product_round = $signed({6'b000001,10'b0});

        //   full_product2 = $signed({6'b0,10'b1000000000})*$signed(src_A_i)*($signed({6'b000001,10'b0})+product_round);
        //   data_o = (full_product2[19:0]>{1'b1,19'b0})? full_product2[35:20]+1 : (full_product2[19] & full_product2[20])? full_product2[35:20]+1 : full_product2[35:20];
        // end
      end
      default: begin
        data_o = 0;
      end  
    endcase
end

endmodule
