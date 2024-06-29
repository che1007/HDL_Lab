module aes(
    input              clk,
    input              rst,
    input              valid,
    input      [127:0] matrix1,
    input      [127:0] matrix2,
    output reg    [1:0]   count,
    output reg    [127:0] matrix3
);


reg [127:0] after_addroundkey, after_shiftrow, after_mixcolumns;
reg [7:0] pos1, pos2, pos3, pos4, pos5, pos6, pos7, pos8, pos9, pos10, pos11, pos12, pos13, pos14, pos15, pos16;
reg [7:0] mixcolpos1, mixcolpos2, mixcolpos3, mixcolpos4, mixcolpos5, mixcolpos6, mixcolpos7, mixcolpos8, mixcolpos9, mixcolpos10, mixcolpos11, mixcolpos12, mixcolpos13, mixcolpos14, mixcolpos15, mixcolpos16;
reg f1, f2;

always @(posedge clk) begin
    if(rst) begin
        count <= 0;
        matrix3 <= 0;
        f1 <= 0;
        f2 <= 0;
    end
    else if(valid) begin
        after_addroundkey <= matrix1^matrix2;
        matrix3 <= matrix1^matrix2;
        count <= count + 1;
        f1 <= 1;
        f2 <= 0;
    end
    else if(f1) begin
        count <= count + 1;
        case (f2)
            1'b0: begin
                matrix3 <= after_shiftrow;
                f2 <= 1;
            end 
            default: matrix3 <= after_mixcolumns; 
        endcase
    end
end

always @(after_addroundkey) begin
    pos1 = after_addroundkey[127:120]; pos5 = after_addroundkey[95:88]; pos9 = after_addroundkey[63:56];   pos13 = after_addroundkey[31:24];
    pos2 = after_addroundkey[87:80];   pos6 = after_addroundkey[55:48]; pos10 = after_addroundkey[23:16];  pos14 = after_addroundkey[119:112];
    pos3 = after_addroundkey[47:40];   pos7 = after_addroundkey[15:8];  pos11 = after_addroundkey[111:104];pos15 = after_addroundkey[79:72];
    pos4 = after_addroundkey[7:0];     pos8 = after_addroundkey[103:96];pos12 = after_addroundkey[71:64];  pos16 = after_addroundkey[39:32];
    after_shiftrow = {pos1, pos2, pos3, pos4, pos5, pos6, pos7, pos8, pos9, pos10, pos11, pos12, pos13, pos14, pos15, pos16};
end

always @(*) begin
    mixcolpos1 = (pos1[7]? (pos1<<1)^{8'b00011011} : pos1<<1) ^ (pos2[7]? (pos2<<1)^{8'b00011011}^pos2 : (pos2<<1)^pos2) ^ pos3 ^ pos4;
    mixcolpos2 = pos1 ^ (pos2[7]? (pos2<<1)^{8'b00011011} : pos2<<1) ^ (pos3[7]? (pos3<<1)^{8'b00011011}^pos3 : (pos3<<1)^pos3) ^ pos4;
    mixcolpos3 = pos1 ^ pos2 ^ (pos3[7]? (pos3<<1)^{8'b00011011} : pos3<<1) ^ (pos4[7]? (pos4<<1)^{8'b00011011}^pos4 : (pos4<<1)^pos4);
    mixcolpos4 = (pos1[7]? (pos1<<1)^{8'b00011011}^pos1 : (pos1<<1)^pos1) ^ pos2 ^ pos3 ^ (pos4[7]? (pos4<<1)^{8'b00011011} : pos4<<1);

    mixcolpos5 = (pos5[7]? (pos5<<1)^{8'b00011011} : pos5<<1) ^ (pos6[7]? (pos6<<1)^{8'b00011011}^pos6 : (pos6<<1)^pos6) ^ pos7 ^ pos8;
    mixcolpos6 = pos5 ^ (pos6[7]? (pos6<<1)^{8'b00011011} : pos6<<1) ^ (pos7[7]? (pos7<<1)^{8'b00011011}^pos7 : (pos7<<1)^pos7) ^ pos8;
    mixcolpos7 = pos5 ^ pos6 ^ (pos7[7]? (pos7<<1)^{8'b00011011} : pos7<<1) ^ (pos8[7]? (pos8<<1)^{8'b00011011}^pos8 : (pos8<<1)^pos8);
    mixcolpos8 = (pos5[7]? (pos5<<1)^{8'b00011011}^pos5 : (pos5<<1)^pos5) ^ pos6 ^ pos7 ^ (pos8[7]? (pos8<<1)^{8'b00011011} : pos8<<1);

    mixcolpos9 = (pos9[7]? (pos9<<1)^{8'b00011011} : pos9<<1) ^ (pos10[7]? (pos10<<1)^{8'b00011011}^pos10 : (pos10<<1)^pos10) ^ pos11 ^ pos12;
    mixcolpos10 = pos9 ^ (pos10[7]? (pos10<<1)^{8'b00011011} : pos10<<1) ^ (pos11[7]? (pos11<<1)^{8'b00011011}^pos11 : (pos11<<1)^pos11) ^ pos12;
    mixcolpos11 = pos9 ^ pos10 ^ (pos11[7]? (pos11<<1)^{8'b00011011} : pos11<<1) ^ (pos12[7]? (pos12<<1)^{8'b00011011}^pos12 : (pos12<<1)^pos12);
    mixcolpos12 = (pos9[7]? (pos9<<1)^{8'b00011011}^pos9 : (pos9<<1)^pos9) ^ pos10 ^ pos11 ^ (pos12[7]? (pos12<<1)^{8'b00011011} : pos12<<1);

    mixcolpos13 = (pos13[7]? (pos13<<1)^{8'b00011011} : pos13<<1) ^ (pos14[7]? (pos14<<1)^{8'b00011011}^pos14 : (pos14<<1)^pos14) ^ pos15 ^ pos16;
    mixcolpos14 = pos13 ^ (pos14[7]? (pos14<<1)^{8'b00011011} : pos14<<1) ^ (pos15[7]? (pos15<<1)^{8'b00011011}^pos15 : (pos15<<1)^pos15) ^ pos16;
    mixcolpos15 = pos13 ^ pos14 ^ (pos15[7]? (pos15<<1)^{8'b00011011} : pos15<<1) ^ (pos16[7]? (pos16<<1)^{8'b00011011}^pos16 : (pos16<<1)^pos16);
    mixcolpos16 = (pos13[7]? (pos13<<1)^{8'b00011011}^pos13 : (pos13<<1)^pos13) ^ pos14 ^ pos15 ^ (pos16[7]? (pos16<<1)^{8'b00011011} : pos16<<1);
    after_mixcolumns = {mixcolpos1, mixcolpos2, mixcolpos3, mixcolpos4, mixcolpos5, mixcolpos6, mixcolpos7, mixcolpos8, mixcolpos9, mixcolpos10, mixcolpos11, mixcolpos12, mixcolpos13, mixcolpos14, mixcolpos15, mixcolpos16};
end

endmodule