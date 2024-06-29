module aes(
    input           clk,
    input           rst,
    input  [127:0]  plaintext,
    input  [127:0]  key,
    input  [7:0]    rom_data,
    output reg [7:0]    rom_addr,
    output reg [127:0]  ciphertext,
    output reg         done
);

localparam READ = 3'd0;
localparam SUBBYTES = 3'd1;
localparam  ROTSUB = 3'd2;
localparam RCON = 3'd3;
localparam R1TOR9 = 3'd4;
localparam FINAL = 3'd5;

parameter rcon1 = 8'h1;
parameter rcon2 = 8'h2;
parameter rcon3 = 8'h4;
parameter rcon4 = 8'h8;
parameter rcon5 = 8'h10;
parameter rcon6 = 8'h20;
parameter rcon7 = 8'h40;
parameter rcon8 = 8'h80;
parameter rcon9 = 8'h1b;
parameter rcon10 = 8'h36;

reg [2:0] state, nextstate;
reg [127:0] after_addroundkey, after_subbytes, after_shiftrow, after_mixcolumns, temp, final_temp;
reg [127:0] last_key;

reg [7:0] pos1, pos2, pos3, pos4, pos5, pos6, pos7, pos8, pos9, pos10, pos11, pos12, pos13, pos14, pos15, pos16;
reg [7:0] mixcolpos1, mixcolpos2, mixcolpos3, mixcolpos4, mixcolpos5, mixcolpos6, mixcolpos7, mixcolpos8, mixcolpos9, mixcolpos10, mixcolpos11, mixcolpos12, mixcolpos13, mixcolpos14, mixcolpos15, mixcolpos16;

reg [4:0] count;
reg [2:0] key_count;
reg [31:0] subword;
reg [3:0] round;

always @(posedge clk) begin
    if(rst | done) state <= READ;
    else state <= nextstate;
end

always @(*) begin
    case (state)
        READ: begin
            nextstate = SUBBYTES;
        end
        SUBBYTES: begin
            if(count==16) nextstate = ROTSUB;
            else nextstate = state;
        end
        ROTSUB: begin
            if(key_count==4) nextstate = RCON;
            else nextstate = state;
        end
        RCON: begin
            nextstate = R1TOR9;
        end
        R1TOR9:begin
            if(round==11) nextstate = FINAL;
            else nextstate = SUBBYTES;
        end
        FINAL: begin
            nextstate = READ;
        end 
    endcase
end

always @(posedge clk) begin
    if(rst) begin
        ciphertext <= 0;
        done <= 0;
        count <= 0;
        round <=1;
        key_count <=0;
        after_addroundkey <= 0;
        after_subbytes <= 0;
        after_shiftrow <= 0;
        after_mixcolumns <= 0;
        subword <= 0;
    end
    else begin
        case (state)
            READ: begin
                after_addroundkey <= plaintext^key;
                last_key <= key;
                ciphertext <= 0;
                done <= 0;
                count <= 0;
                round <=1;
                key_count <=0;
            end
            SUBBYTES: begin
                count <= count + 1;
                case (count)
                    5'd0: rom_addr <= after_addroundkey[127:120];
                    5'd1: rom_addr <= after_addroundkey[119:112];
                    5'd2: rom_addr <= after_addroundkey[111:104];
                    5'd3: rom_addr <= after_addroundkey[103:96];
                    5'd4: rom_addr <= after_addroundkey[95:88];
                    5'd5: rom_addr <= after_addroundkey[87:80];
                    5'd6: rom_addr <= after_addroundkey[79:72];
                    5'd7: rom_addr <= after_addroundkey[71:64];
                    5'd8: rom_addr <= after_addroundkey[63:56];
                    5'd9: rom_addr <= after_addroundkey[55:48];
                    5'd10: rom_addr <= after_addroundkey[47:40];
                    5'd11: rom_addr <= after_addroundkey[39:32];
                    5'd12: rom_addr <= after_addroundkey[31:24];
                    5'd13: rom_addr <= after_addroundkey[23:16];
                    5'd14: rom_addr <= after_addroundkey[15:8];
                    5'd15: rom_addr <= after_addroundkey[7:0];
                endcase
            end
            ROTSUB: begin
                key_count <= key_count + 1;
                case (key_count)
                    3'd0: begin
                        temp <= after_mixcolumns;
                        final_temp <= after_shiftrow;
                        rom_addr <= last_key[23:16];
                    end
                    3'd1: begin
                        rom_addr <= last_key[15:8];
                    end
                    3'd2: begin
                        rom_addr <= last_key[7:0];
                    end
                    3'd3: begin
                        rom_addr <= last_key[31:24];
                    end 
                endcase
            end
            RCON: begin
                round <= round + 1;
                case (round)
                    4'd1: begin
                        last_key[127:96] <= {subword[31:24]^rcon1, subword[23:0]}^last_key[127:96];
                        last_key[95:64] <= {subword[31:24]^rcon1, subword[23:0]}^last_key[127:96]^last_key[95:64];
                        last_key[63:32] <= {subword[31:24]^rcon1, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32];
                        last_key[31:0] <= {subword[31:24]^rcon1, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32]^last_key[31:0];
                    end
                    4'd2: begin
                        last_key[127:96] <= {subword[31:24]^rcon2, subword[23:0]}^last_key[127:96];
                        last_key[95:64] <= {subword[31:24]^rcon2, subword[23:0]}^last_key[127:96]^last_key[95:64];
                        last_key[63:32] <= {subword[31:24]^rcon2, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32];
                        last_key[31:0] <= {subword[31:24]^rcon2, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32]^last_key[31:0];
                    end
                    4'd3: begin
                        last_key[127:96] <= {subword[31:24]^rcon3, subword[23:0]}^last_key[127:96];
                        last_key[95:64] <= {subword[31:24]^rcon3, subword[23:0]}^last_key[127:96]^last_key[95:64];
                        last_key[63:32] <= {subword[31:24]^rcon3, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32];
                        last_key[31:0] <= {subword[31:24]^rcon3, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32]^last_key[31:0];
                    end
                    4'd4: begin
                        last_key[127:96] <= {subword[31:24]^rcon4, subword[23:0]}^last_key[127:96];
                        last_key[95:64] <= {subword[31:24]^rcon4, subword[23:0]}^last_key[127:96]^last_key[95:64];
                        last_key[63:32] <= {subword[31:24]^rcon4, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32];
                        last_key[31:0] <= {subword[31:24]^rcon4, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32]^last_key[31:0];
                    end
                    4'd5: begin
                        last_key[127:96] <= {subword[31:24]^rcon5, subword[23:0]}^last_key[127:96];
                        last_key[95:64] <= {subword[31:24]^rcon5, subword[23:0]}^last_key[127:96]^last_key[95:64];
                        last_key[63:32] <= {subword[31:24]^rcon5, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32];
                        last_key[31:0] <= {subword[31:24]^rcon5, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32]^last_key[31:0];
                    end
                    4'd6: begin
                        last_key[127:96] <= {subword[31:24]^rcon6, subword[23:0]}^last_key[127:96];
                        last_key[95:64] <= {subword[31:24]^rcon6, subword[23:0]}^last_key[127:96]^last_key[95:64];
                        last_key[63:32] <= {subword[31:24]^rcon6, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32];
                        last_key[31:0] <= {subword[31:24]^rcon6, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32]^last_key[31:0];
                    end
                    4'd7: begin
                        last_key[127:96] <= {subword[31:24]^rcon7, subword[23:0]}^last_key[127:96];
                        last_key[95:64] <= {subword[31:24]^rcon7, subword[23:0]}^last_key[127:96]^last_key[95:64];
                        last_key[63:32] <= {subword[31:24]^rcon7, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32];
                        last_key[31:0] <= {subword[31:24]^rcon7, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32]^last_key[31:0];
                    end
                    4'd8: begin
                        last_key[127:96] <= {subword[31:24]^rcon8, subword[23:0]}^last_key[127:96];
                        last_key[95:64] <= {subword[31:24]^rcon8, subword[23:0]}^last_key[127:96]^last_key[95:64];
                        last_key[63:32] <= {subword[31:24]^rcon8, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32];
                        last_key[31:0] <= {subword[31:24]^rcon8, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32]^last_key[31:0];
                    end
                    4'd9: begin
                        last_key[127:96] <= {subword[31:24]^rcon9, subword[23:0]}^last_key[127:96];
                        last_key[95:64] <= {subword[31:24]^rcon9, subword[23:0]}^last_key[127:96]^last_key[95:64];
                        last_key[63:32] <= {subword[31:24]^rcon9, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32];
                        last_key[31:0] <= {subword[31:24]^rcon9, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32]^last_key[31:0];
                    end
                    4'd10: begin
                        last_key[127:96] <= {subword[31:24]^rcon10, subword[23:0]}^last_key[127:96];
                        last_key[95:64] <= {subword[31:24]^rcon10, subword[23:0]}^last_key[127:96]^last_key[95:64];
                        last_key[63:32] <= {subword[31:24]^rcon10, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32];
                        last_key[31:0] <= {subword[31:24]^rcon10, subword[23:0]}^last_key[127:96]^last_key[95:64]^last_key[63:32]^last_key[31:0];
                    end 
                endcase
            end
            R1TOR9: begin
                after_addroundkey <= temp^last_key;
                count <=0;
            end
            FINAL:begin
                ciphertext <= final_temp^last_key;
                done <= 1;
            end 
        endcase
    end
end

always @(*) begin
    case (key_count)
        3'd2: subword[31:24] = rom_data;
        3'd3: subword[23:16] = rom_data;
        3'd4: subword[15:8] = rom_data;
        3'd5: subword[7:0] = rom_data;
        default: subword = subword;
    endcase
end

always @(*) begin
    case (count)
        5'd2: after_subbytes[127:120] = rom_data;
        5'd3: after_subbytes[119:112] = rom_data;
        5'd4: after_subbytes[111:104] = rom_data;
        5'd5: after_subbytes[103:96] = rom_data;
        5'd6: after_subbytes[95:88] = rom_data;
        5'd7: after_subbytes[87:80] = rom_data;
        5'd8: after_subbytes[79:72] = rom_data;
        5'd9: after_subbytes[71:64] = rom_data;
        5'd10: after_subbytes[63:56] = rom_data;
        5'd11: after_subbytes[55:48] = rom_data;
        5'd12: after_subbytes[47:40] = rom_data;
        5'd13: after_subbytes[39:32] = rom_data;
        5'd14: after_subbytes[31:24] = rom_data;
        5'd15: after_subbytes[23:16] = rom_data;
        5'd16: after_subbytes[15:8] = rom_data;
        5'd17: after_subbytes[7:0] = rom_data;
        default: after_subbytes = after_subbytes;
    endcase
end

always @(*) begin
    pos1 = after_subbytes[127:120]; pos5 = after_subbytes[95:88]; pos9 = after_subbytes[63:56];   pos13 = after_subbytes[31:24];
    pos2 = after_subbytes[87:80];   pos6 = after_subbytes[55:48]; pos10 = after_subbytes[23:16];  pos14 = after_subbytes[119:112];
    pos3 = after_subbytes[47:40];   pos7 = after_subbytes[15:8];  pos11 = after_subbytes[111:104];pos15 = after_subbytes[79:72];
    pos4 = after_subbytes[7:0];     pos8 = after_subbytes[103:96];pos12 = after_subbytes[71:64];  pos16 = after_subbytes[39:32];
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