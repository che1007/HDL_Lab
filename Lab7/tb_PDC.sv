`timescale 1ns/10ps
`define PERIOD 10.0
`define PatternPATH "./pattern/"
`define offset 54
`define size_width 256
`define size_pic `size_width*`size_width
`define MAXCYCLE 12000000
`define PatNum 3

module tb_PDC;

reg                 clk;
reg                 rst;
reg              enable;
wire   [7:0]    RAM_i_Q;
wire   [7:0]    RAM_o_Q;
wire           RAM_i_OE;
wire           RAM_i_WE;
wire   [17:0]   RAM_i_A;
wire   [7:0]    RAM_i_D;
wire           RAM_o_OE;
wire           RAM_o_WE;
wire   [17:0]   RAM_o_A;
wire   [7:0]    RAM_o_D;
wire               done;

reg [7:0] ANS [`size_pic*3-1:0];
reg [7:0] header [`offset-1:0];
integer ofile, ifile;
integer idx;
int linedata1, linedata2, linedata3;
string s_idx, s_i;

PDC PDC(
  // input port
  .clk     (clk     ),
  .rst     (rst     ),
  .enable  (enable  ),
  .RAM_i_Q (RAM_i_Q ),
  .RAM_o_Q (RAM_o_Q ),
  // output port
  .RAM_i_OE(RAM_i_OE),
  .RAM_i_WE(RAM_i_WE),
  .RAM_i_A (RAM_i_A ),
  .RAM_i_D (RAM_i_D ),
  .RAM_o_OE(RAM_o_OE),
  .RAM_o_WE(RAM_o_WE),
  .RAM_o_A (RAM_o_A ),
  .RAM_o_D (RAM_o_D ),
  .done    (done    ) 
);

RAM #(.depth(196705)) RAM_i(
  .CK(clk     ), 
  .A (RAM_i_A ), 
  .WE(RAM_i_WE), 
  .OE(RAM_i_OE), 
  .D (RAM_i_D ), 
  .Q (RAM_i_Q )
);

RAM #(.depth(196608)) RAM_o(
  .CK(clk     ), 
  .A (RAM_o_A ), 
  .WE(RAM_o_WE), 
  .OE(RAM_o_OE), 
  .D (RAM_o_D ), 
  .Q (RAM_o_Q )
);

always #(`PERIOD / 2.0)clk = ~clk;

initial begin
  $display("********************************");
  $display("**      Simulation Start      **");
  $display("********************************");
end 

initial begin
  $readmemh({`PatternPATH, "BmpHeader.dat"} , header);
end

initial begin
  linedata3 = $fopen({`PatternPATH, "BmpHeader.dat"} ,"r");
  for(int i=0;i<`PatNum;i++)begin
    s_i.itoa(i+1);
    linedata1 = $fopen({`PatternPATH, "RAM_Golden", s_i, ".dat"},"r");
    linedata2 = $fopen({`PatternPATH, "RAM_init", s_i, ".dat"}  ,"r");
    if (linedata1 == 0 || linedata2 == 0 || linedata3 == 0) begin
      $display("\n");
      $display("********************************");
      $display("**    pattern handle null     **");
      $display("********************************");
      $finish;
    end
    $fclose(linedata1);
    $fclose(linedata2);
  end
  $fclose(linedata3);
end

initial begin
  clk      = 0;
  enable   = 0;
  ofile    = 0;
  rst      = 1;
  repeat(3)@(posedge clk)rst = 1;
  rst = 0;
  @(posedge clk);
  //===================== check ANS =====================
  for(idx=0;idx<`PatNum;idx++)begin
    s_idx.itoa(idx+1);
    @(posedge clk);
    $readmemb({`PatternPATH, "RAM_Golden", s_idx, ".dat"}, ANS);
    $readmemb({`PatternPATH, "RAM_init", s_idx, ".dat"}  , RAM_i.memory);
    #(`PERIOD / 2.0)enable = 1;
    #(`PERIOD)enable = 0;
    wait(done == 1);
    @(posedge clk);
    for(int i=0;i<`size_pic*3;i=i+1)begin
      if( (RAM_o.memory[i] !== ANS[i] || $isunknown(RAM_o.memory[i])))begin
        $display(" ****************************               ");
        $display(" **                        **       |\__||  ");
        $display(" **  OOPS!!                **      / X,X  | ");
        $display(" **                        **    /_____   | ");
        $display(" **  Simulation Failed!!   **   /^ ^ ^ \\  |");
        $display(" **                        **  |^ ^ ^ ^ |w| ");
        $display(" ****************************   \\m___m__|_|");
        $display("Error, Pattern %1d, RAM_o[%5d] = %3d, expect = %3d", idx+1, i, RAM_o.memory[i], ANS[i]);
        $display(" -------------- Simulation stop --------------\n\n");
        $stop;
      end
    end
    $display("============ Pattern %1d PASS !!! ============", idx+1);
    // ===================== write BMP file =====================
    ifile = $fopen({"input_image", s_idx, ".bmp"}, "wb");
    ofile = $fopen({"your_result", s_idx, ".bmp"}, "wb");
    // write header
    for(int i=0;i<`offset;i++)begin
      $fwrite(ifile, "%c", header[i]);
      $fwrite(ofile, "%c", header[i]);
    end
    // write data
    for(int i=0;i<`size_pic;i++)begin
      automatic int y = (`size_pic-1-i) / 256;
      automatic int x = (`size_pic-1-i) % 256;
      automatic int newAddr = y * 256 + (255-x);
      for(int rgb=0;rgb<3;rgb++)begin
        $fwrite(ifile, "%c", RAM_i.memory[16'h61 + newAddr + ((2-rgb)<<16)]);
        $fwrite(ofile, "%c", RAM_o.memory[newAddr + ((2-rgb)<<16)]);
      end
    end
    $fclose(ifile); 
    $fclose(ofile);
    if(idx == 1)resetTask();
  end
  $display("\n");
  $display(" ****************************               ");
  $display(" **                        **       |\__||  ");
  $display(" **  Congratulations !!    **      / O.O  | ");
  $display(" **                        **    /_____   | ");
  $display(" **  Simulation PASS!!     **   /^ ^ ^ \\  |");
  $display(" **                        **  |^ ^ ^ ^ |w| ");
  $display(" ****************************   \\m___m__|_|");
  $display("\n");
  $finish;
end

initial begin
  #(`MAXCYCLE * `PERIOD);
  $display("*************************************");
  $display("                                     ");
  $display(" OOPS, simulation can not finish...  ");
  $display("                                     ");
  $display("*************************************");
  $finish;
end


task resetTask;
begin
  rst = 1;
  repeat(3)@(posedge clk)rst = 1;
  rst = 0;
end
endtask

endmodule


module RAM #(parameter depth=65536)(CK, A, WE, OE, D, Q);

  input                                  CK;
  input  [$clog2(depth)-1:0]              A;
  input                                  WE;
  input                                  OE;
  input  [7:0]                            D;
  output [7:0]                            Q;

  reg    [7:0]                            Q;
  reg    [$clog2(depth)-1:0]      latched_A;
  reg    [$clog2(depth)-1:0]  latched_A_neg;
  reg    [7:0] memory           [depth-1:0];

  always @(posedge CK) begin
    if (WE) begin
      memory[A] <= D;
    end
		latched_A <= A;
  end
  
  always@(negedge CK) begin
    latched_A_neg <= latched_A;
  end
  
  always @(*) begin
    if (OE) begin
      Q = memory[latched_A_neg];
    end
    else begin
      Q = 8'hzz;
    end
  end
  
endmodule
