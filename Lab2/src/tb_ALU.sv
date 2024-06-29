`timescale 1ns/1ps
`define patternNum 1000
`define PatternPATH "./pattern/"

module tb_ALU;

localparam INT_W  = 6;
localparam FRAC_W = 10;
localparam INST_W = 3;
localparam BitWidth = INT_W + FRAC_W;
localparam Byte   = 8;

logic [BitWidth-1:0]    src_A_i;
logic [BitWidth-1:0]    src_B_i;
logic [INST_W-1:0  ]     inst_i;
logic [Byte-1:0]     sortNum1_i;
logic [Byte-1:0]     sortNum2_i;
logic [Byte-1:0]     sortNum3_i;
logic [Byte-1:0]     sortNum4_i;
logic [Byte-1:0]     sortNum5_i;
logic [Byte-1:0]     sortNum6_i;
logic [Byte-1:0]     sortNum7_i;
logic [Byte-1:0]     sortNum8_i;
logic [Byte-1:0]     sortNum9_i;
logic [Byte-1:0]     sortNum1_o;
logic [Byte-1:0]     sortNum2_o;
logic [Byte-1:0]     sortNum3_o;
logic [Byte-1:0]     sortNum4_o;
logic [Byte-1:0]     sortNum5_o;
logic [Byte-1:0]     sortNum6_o;
logic [Byte-1:0]     sortNum7_o;
logic [Byte-1:0]     sortNum8_o;
logic [Byte-1:0]     sortNum9_o;
logic [BitWidth-1:0]     data_o;

logic [4+BitWidth*2-1:0] ALU_inputData  [`patternNum-1:0];
logic [BitWidth-1:0]     ALU_outputData [`patternNum-1:0];

logic [4+BitWidth*9-1:0] sort_inputData [`patternNum-1:0];
logic [BitWidth*9-1:0]   sort_outputData[`patternNum-1:0];

string inst_str;
logic [BitWidth-1:0]        golden;
logic [BitWidth*9-1:0] golden_sort;
logic [9:0] patternIndex;

int error[6];
int score[6] = {16, 16, 16, 10, 16, 16};
int total_score = 0;

ALU UUT(
  .src_A_i   (src_A_i   ),
  .src_B_i   (src_B_i   ),
  .inst_i    (inst_i    ),
  .sortNum1_i(sortNum1_i),
  .sortNum2_i(sortNum2_i),
  .sortNum3_i(sortNum3_i),
  .sortNum4_i(sortNum4_i),
  .sortNum5_i(sortNum5_i),
  .sortNum6_i(sortNum6_i),
  .sortNum7_i(sortNum7_i),
  .sortNum8_i(sortNum8_i),
  .sortNum9_i(sortNum9_i),
  .sortNum1_o(sortNum1_o),
  .sortNum2_o(sortNum2_o),
  .sortNum3_o(sortNum3_o),
  .sortNum4_o(sortNum4_o),
  .sortNum5_o(sortNum5_o),
  .sortNum6_o(sortNum6_o),
  .sortNum7_o(sortNum7_o),
  .sortNum8_o(sortNum8_o),
  .sortNum9_o(sortNum9_o),
  .data_o    (data_o    )
);

initial begin
  $display("********************************");
  $display("**      Simulation Start      **");
  $display("********************************\n");
end 

initial begin
  src_A_i    = 'd0;
  src_B_i    = 'd0;
  inst_i     = 'd0;
  sortNum1_i = 'd0;
  sortNum2_i = 'd0;
  sortNum3_i = 'd0;
  sortNum4_i = 'd0;
  sortNum5_i = 'd0;
  sortNum6_i = 'd0;
  sortNum7_i = 'd0;
  sortNum8_i = 'd0;
  sortNum9_i = 'd0;
  golden     = 'd0;
  
  // check instruction 0~4
  for(int inst=0;inst<5;inst++)begin
    inst_str.itoa(inst);
    $readmemb({`PatternPATH, "Inst", inst_str, "_i.dat"}, ALU_inputData );
    $readmemb({`PatternPATH, "Inst", inst_str, "_o.dat"}, ALU_outputData);
    for(int patIdx=0;patIdx<`patternNum;patIdx++)begin
      patternIndex = patIdx;
      {inst_i, src_A_i, src_B_i} = ALU_inputData[patIdx];
      golden = ALU_outputData[patIdx];
      #10;
      // check ALU output data
      if($isunknown(data_o))begin
        $display(" ============ Unknown value occurs at your data_o, simulation stop ============");
        $stop;
      end
      else begin
        if(data_o !== golden)begin
          error[inst] += 1;
          if(error[inst] == 1)$display("time = %0t ps ,Instruction %1d Error, your data_o = %b, expect data_o = %b" ,$time, inst, data_o, golden);
        end
      end
    end
    if(error[inst] === 0)$display("Instruction %1d ALL PASS !!!", inst);
  end
  
  // check instruction 5
  $readmemb({`PatternPATH, "Inst5_i.dat"}, sort_inputData );
  $readmemb({`PatternPATH, "Inst5_o.dat"}, sort_outputData);
  for(int patIdx=0;patIdx<`patternNum;patIdx++)begin
    patternIndex = patIdx;
    {inst_i,sortNum1_i,sortNum2_i,sortNum3_i,sortNum4_i,sortNum5_i,sortNum6_i,sortNum7_i,sortNum8_i,sortNum9_i} = sort_inputData[patIdx];
    golden_sort = sort_outputData[patIdx];
    #10;
    // check ALU output data
    if($isunknown(sortNum1_o) | 
       $isunknown(sortNum2_o) |
       $isunknown(sortNum3_o) |
       $isunknown(sortNum4_o) |
       $isunknown(sortNum5_o) |
       $isunknown(sortNum6_o) |
       $isunknown(sortNum7_o) |
       $isunknown(sortNum8_o) |
       $isunknown(sortNum9_o) )begin
      $display(" ============ Unknown value occurs at your output port, simulation stop ============");
      $stop;
    end
    else begin
      if({sortNum1_o,sortNum2_o,sortNum3_o,sortNum4_o,sortNum5_o,sortNum6_o,sortNum7_o,sortNum8_o,sortNum9_o} !== golden_sort)begin
        error[5] += 1;
        if(error[5] == 1)begin
          $display("time=%0tps,Instruction %1d Error",$time, 5);
          $display("your sortNum1_o = %3d, expect sortNum1_o = %3d" ,sortNum1_o, golden_sort[8*8+:8]);
          $display("your sortNum2_o = %3d, expect sortNum2_o = %3d" ,sortNum2_o, golden_sort[7*8+:8]);
          $display("your sortNum3_o = %3d, expect sortNum3_o = %3d" ,sortNum3_o, golden_sort[6*8+:8]);
          $display("your sortNum4_o = %3d, expect sortNum4_o = %3d" ,sortNum4_o, golden_sort[5*8+:8]);
          $display("your sortNum5_o = %3d, expect sortNum5_o = %3d" ,sortNum5_o, golden_sort[4*8+:8]);
          $display("your sortNum6_o = %3d, expect sortNum6_o = %3d" ,sortNum6_o, golden_sort[3*8+:8]);
          $display("your sortNum7_o = %3d, expect sortNum7_o = %3d" ,sortNum7_o, golden_sort[2*8+:8]);
          $display("your sortNum8_o = %3d, expect sortNum8_o = %3d" ,sortNum8_o, golden_sort[1*8+:8]);
          $display("your sortNum9_o = %3d, expect sortNum9_o = %3d" ,sortNum9_o, golden_sort[0*8+:8]);
        end
      end
    end
  end
  if(error[5] === 0)$display("Instruction %1d ALL PASS !!!", 5);
  
  if(error[0] == 0 && error[1] == 0 && error[2] == 0 && error[3] == 0 && error[4] == 0 && error[5] == 0)begin
    $display("\n");
    $display(" ****************************               ");
    $display(" **                        **       |\__||  ");
    $display(" **  Congratulations !!    **      / O.O  | ");
    $display(" **                        **    /_____   | ");
    $display(" **  Simulation PASS!!     **   /^ ^ ^ \\  |");
    $display(" **                        **  |^ ^ ^ ^ |w| ");
    $display(" ****************************   \\m___m__|_|");
  end
  else begin
    $display("\n");
    $display(" ****************************               ");
    $display(" **                        **       |\__||  ");
    $display(" **  OOPS!!                **      / X,X  | ");
    $display(" **                        **    /_____   | ");
    $display(" **  Simulation Failed!!   **   /^ ^ ^ \\  |");
    $display(" **                        **  |^ ^ ^ ^ |w| ");
    $display(" ****************************   \\m___m__|_|");
  end
  
  for(int i=0;i<6;i++)begin
    if(error[i] === 0)total_score += score[i];
  end
  $display("\n====== Your score : %2d / 90 ======\n", total_score);
  $stop;
end


endmodule


