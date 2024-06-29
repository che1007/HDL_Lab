`timescale 1ns/10ps
`define CYCLE 10
`define MAX_CYCLE 300000
`include "aes.v"


module testfixture();

integer fpat;
integer gold_count = 0;
integer error1 = 0;
integer error2 = 0;
integer error3 = 0;
integer error1_count = 0;
integer error2_count = 0;
integer error3_count = 0;
integer FULL  = 90; // this HW FULL score
integer SCORE = FULL;
integer tmp; // return value of fscanf(number of read line)

logic [127:0] error1_matrix;
logic [127:0] error2_matrix;
logic [127:0] error3_matrix;

logic [127:0] fgold1 [3071:0];
logic [127:0] fgold2 [3071:0];
logic [127:0] fgold3 [3071:0];

logic CLK = 0;
logic RST = 0;
logic VALID;
logic [127:0] matrix1;
logic [127:0] matrix2;
logic [1:0]   count;
logic [127:0] matrix3;

logic [1:0] rst_count;
logic [127:0] pat;
logic change_pattern_pulse;

aes AES(
    .clk     (CLK),
    .rst     (RST),
    .valid   (VALID),
    .matrix1 (matrix1),
    .matrix2 (matrix2),
    .count   (count),
    .matrix3 (matrix3)
);

always begin #(`CYCLE/2) CLK = ~CLK; end


typedef enum logic [2:0] { 
    RST_state, PAT_state, CHECK_G1, CHECK_G2, CHECK_G3, DONE
}fsm;
fsm state;

// initial variable
initial begin
    state = RST_state;
    rst_count = 0;
end

// assign pattern from file
initial begin
    fpat = $fopen("pat/pat.dat", "r");
    if (fpat == 0) begin
        $display ("Failed open %s", "pat/pat.dat");
        $stop;
    end
    else begin
        while (!$feof(fpat)) begin
            
            tmp = $fscanf(fpat, "%h\n", pat); // read one line in pat.dat file as plaintext
            
            @(posedge change_pattern_pulse);
        end
    end
end
 
// assign golden from file
initial begin
    $readmemh("golden/gold1.dat", fgold1);
    $readmemh("golden/gold2.dat", fgold2);
    $readmemh("golden/gold3.dat", fgold3);
end


assign change_pattern_pulse = (state == CHECK_G3)? 1'b1 : 1'b0;

assign VALID   = (state == PAT_state)? 1'b1 : 1'b0;
assign matrix1 = (state == PAT_state)? pat : 'dz;
assign matrix2 = (state == PAT_state)? 128'h54686973_49734153_65637265_744B6579 : 'dz; // ThisIsASecretKey


// --------------------- //
//          FSM          //
// --------------------- //
always @(posedge CLK) begin
    case (state)
        RST_state: begin  // reset the system
            state <= (rst_count == 2)? PAT_state : RST_state;
            rst_count <= rst_count + 1;
            RST <= (rst_count == 2)? 0 : 1;
        end
        PAT_state: begin // feed pattern in one cycle
            state <= CHECK_G1;
            $display("Pattern %4d/%4d", gold_count+1, 3072);
        end
        CHECK_G1: begin // check with golden1
            if (count === 2'd1) begin
                state <= CHECK_G2;
                check(1);
            end
            else
                state <= CHECK_G1;

            //$display("Add Round Key:");
            //draw_matrix(matrix3);
        end
        CHECK_G2: begin // check with golden2
            if (count === 2'd2) begin
                state <= CHECK_G3;
                check(2);
            end
            else
                state <= CHECK_G2;

            //$display("Row Shift:");
            //draw_matrix(matrix3);
        end
        CHECK_G3: begin // check with golden3
            if (count === 2'd3) begin
                state <= (gold_count == 3071)? DONE : PAT_state;
                check(3);
                gold_count = gold_count + 1;
            end
            else
                state <= CHECK_G3;

            //$display("Mix Column:");
            //draw_matrix(matrix3);
        end
        DONE: begin
            state <= DONE;
            result();

            $fclose(fpat);
            score();
            $stop;  // if all pattern are feed
        end
    endcase
end

// reach maximum limit of clock cycle
initial begin
    # (`MAX_CYCLE);
    $display("\n");
    $display("\n");
    $display("        ****************************               ");
    $display("        **                        **       |\__||  ");
    $display("        **  OOPS!!                **      / X,X  | ");
    $display("        **                        **    /_____   | ");
    $display("        **  Simulation Failed!!   **   /^ ^ ^ \\  |");
    $display("        **                        **  |^ ^ ^ ^ |w| ");
    $display("        ****************************   \\m___m__|_|");
    $display("\n");
    //$display("Pattern name: %s", pattern_name);
    $display("!!! Reach maximum cycle number !!!");
    $display("\n\n---------- Your score: %2d/%2d ----------", 0, FULL);
    $stop;
end


task draw_matrix;
    input [127:0] matrix;

    logic [0:15][7:0] array;
    integer i, j;
    assign array = matrix;

    // print as column major
    for (i=0; i<4; i=i+1) begin
        for (j=0; j<4; j=j+1) begin
            $write("%2h  ", array[i+4*j]);
        end
        $write("\n");
    end
    $display();
endtask

task check(
    integer mode
);
    case (mode)
        1: begin
            $write("AddRoundKey Operation: ");
            if (matrix3 !== fgold1[gold_count]) begin
                error1 ++;
                $write("Error, ");
            end
            else begin
                $write("Correct, ");
            end

            if (error1 == 1) begin// record first error1 matrix
                error1_matrix = matrix3; 
                error1_count = gold_count;
            end
        end
        2: begin
            $write("ShiftRows Operation: ");
            if (matrix3 !== fgold2[gold_count]) begin
                error2 ++;
                $write("Error, ");
            end
            else begin
                $write("Correct, ");
            end
            if (error2 == 1) begin// record first error2 matrix
                error2_matrix = matrix3; 
                error2_count = gold_count;
            end
        end
        3: begin
            $write("MixColumns Operation:  ");
            if (matrix3 !== fgold3[gold_count]) begin
                error3 ++;
                $write("Error\n\n");
            end
            else begin
                $write("Correct\n\n");
            end
            if (error3 == 1) begin// record first error3 matrix
                error3_matrix = matrix3; 
                error3_count = gold_count;
            end
        end
        default: begin
            $display("task check with wrong mode in testbench (If Occure, please contact to TA)");
            $stop;
        end
    endcase

endtask

task result();
    $display("\n\n-------- Simulation report --------");
    $display("AddRoundKey Operation ERROR amount: %d", error1);
    $display("ShiftRows   Operation ERROR amount: %d", error2);
    $display("MixColumns  Operation ERROR amount: %d\n", error3);


    if (error1) begin
        $display("-> AddRoundKey Operation: the first error was detected in Pattern %4d", error1_count);
        $display("Your matrix: ");
        draw_matrix(error1_matrix);
        $display("Golden matrix:");
        draw_matrix(fgold1[error1_count]);
        $display("\n");
    end
    if (error2) begin
        $display("-> ShiftRows Operation: the first error was detected in Pattern %4d", error2_count);
        $display("Your matrix: ");
        draw_matrix(error2_matrix);
        $display("Golden matrix:");
        draw_matrix(fgold2[error2_count]);
        $display("\n");
    end
    if (error3) begin
        $display("-> MixColumns Operation: the first error was detected in Pattern %4d", error3_count);
        $display("Your matrix: ");
        draw_matrix(error3_matrix);
        $display("Golden matrix:");
        draw_matrix(fgold3[error3_count]);
        $display("\n");
    end
    


    if (error1 == 0 && error2 == 0 && error3 == 0) begin // all pattern pass, show info
        $display("\n");
        $display("\n");
        $display("        ****************************               ");
        $display("        **                        **       |\__||  ");
        $display("        **  Congratulations !!    **      / O.O  | ");
        $display("        **                        **    /_____   | ");
        $display("        **  Simulation PASS!!     **   /^ ^ ^ \\  |");
        $display("        **                        **  |^ ^ ^ ^ |w| ");
        $display("        ****************************   \\m___m__|_|");
        $display("\n");
    end
    else begin
        $display("\n");
        $display("\n");
        $display("        ****************************               ");
        $display("        **                        **       |\__||  ");
        $display("        **  OOPS!!                **      / X,X  | ");
        $display("        **                        **    /_____   | ");
        $display("        **  Simulation Failed!!   **   /^ ^ ^ \\  |");
        $display("        **                        **  |^ ^ ^ ^ |w| ");
        $display("        ****************************   \\m___m__|_|");
        $display("\n");
    end
endtask

task score();
    
    if (error1) SCORE = SCORE - 10;
    if (error2) SCORE = SCORE - 20;
    if (error3) SCORE = SCORE - 60;

    $display("\n\n---------- Your score: %2d/%2d ----------", SCORE, FULL);
endtask
endmodule