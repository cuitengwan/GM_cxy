`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 24/1/2023 
// Design Name: 
// Module Name:    keytop
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//     to generate all the rks
//     input a new group of key, and output is 32 32bit rk
//////////////////////////////////////////////////////////////////////////////////
module key_top (
    clk,
    rstn,
    key,
    valid,
    rk
);
    input wire clk;
    input wire rstn;
    input wire[127:0] key;
    input wire valid;
    output wire[1023:0] rk;

    /* consts */
    wire [31:0]                FK0;
    wire [31:0]                FK1;
    wire [31:0]                FK2;
    wire [31:0]                FK3;
    assign FK0 = 32'hA3B1BAC6;
    assign FK1 = 32'h56AA3350;
    assign FK2 = 32'h677D9197;
    assign FK3 = 32'hB27022DC;

    /* registers */
    reg  [127:0]               regp; //pre
    reg  [127:0]       keyreg[0:31]; //save the K, [127:96] of each is rk


    /* calculate rk modules, 1 pre + 31 normal */
    wire [31:0]      k_result[0:31];
    rk_calculate rk_calculate_inst_pre(
        .k0(regp[127:96]),
        .k1(regp[95:64]),
        .k2(regp[63:32]),
        .k3(regp[31:0]),
        .k4(k_result[0]),
        .round(32'd0)
    );

    genvar i;
    generate
        for(i=0;i<31;i=i+1) begin:genk
            rk_calculate rk_calculate_inst(
                keyreg[i][127:96],
                keyreg[i][95:64],
                keyreg[i][63:32],
                keyreg[i][31:0],
                k_result[(i+1)],
                (i+1));
        end
    endgenerate 

    integer j;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            regp <= 0;
            keyreg[0] <= 0;keyreg[1] <= 0;keyreg[2] <= 0;keyreg[3] <= 0;
            keyreg[4] <= 0;keyreg[5] <= 0;keyreg[6] <= 0;keyreg[7] <= 0;
            keyreg[8] <= 0;keyreg[9] <= 0;keyreg[10] <= 0;keyreg[11] <= 0;
            keyreg[12] <= 0;keyreg[13] <= 0;keyreg[14] <= 0;keyreg[15] <= 0;
            keyreg[16] <= 0;keyreg[17] <= 0;keyreg[18] <= 0;keyreg[19] <= 0;
            keyreg[20] <= 0;keyreg[21] <= 0;keyreg[22] <= 0;keyreg[23] <= 0;
            keyreg[24] <= 0;keyreg[25] <= 0;keyreg[26] <= 0;keyreg[27] <= 0;
            keyreg[28] <= 0;keyreg[29] <= 0;keyreg[30] <= 0;keyreg[31] <= 0;
        end
        else begin
            // move logic
            // pre: xor with FK
                regp[127:96] <= key[127:96] ^ FK0;
                regp[95:64] <= key[95:64] ^ FK1;
                regp[63:32] <= key[63:32] ^ FK2;
                regp[31:0] <= key[31:0] ^ FK3;

            // every register, low32 flow to high32, new data save in low32
                keyreg[0][127:96] <= regp[95:64];
                keyreg[0][95:64] <= regp[63:32];
                keyreg[0][63:32] <= regp[31:0];
                keyreg[0][31:0] <= k_result[0];

                keyreg[1][127:96] <= keyreg[0][95:64];
                keyreg[1][95:64] <= keyreg[0][63:32];
                keyreg[1][63:32] <= keyreg[0][31:0];
                keyreg[1][31:0] <= k_result[1];

                keyreg[2][127:96] <= keyreg[1][95:64];
                keyreg[2][95:64] <= keyreg[1][63:32];
                keyreg[2][63:32] <= keyreg[1][31:0];
                keyreg[2][31:0] <= k_result[2];

                keyreg[3][127:96] <= keyreg[2][95:64];
                keyreg[3][95:64] <= keyreg[2][63:32];
                keyreg[3][63:32] <= keyreg[2][31:0];
                keyreg[3][31:0] <= k_result[3];

                keyreg[4][127:96] <= keyreg[3][95:64];
                keyreg[4][95:64] <= keyreg[3][63:32];
                keyreg[4][63:32] <= keyreg[3][31:0];
                keyreg[4][31:0] <= k_result[4];

                keyreg[5][127:96] <= keyreg[4][95:64];
                keyreg[5][95:64] <= keyreg[4][63:32];
                keyreg[5][63:32] <= keyreg[4][31:0];
                keyreg[5][31:0] <= k_result[5];

                keyreg[6][127:96] <= keyreg[5][95:64];
                keyreg[6][95:64] <= keyreg[5][63:32];
                keyreg[6][63:32] <= keyreg[5][31:0];
                keyreg[6][31:0] <= k_result[6];

                keyreg[7][127:96] <= keyreg[6][95:64];
                keyreg[7][95:64] <= keyreg[6][63:32];
                keyreg[7][63:32] <= keyreg[6][31:0];
                keyreg[7][31:0] <= k_result[7];

                keyreg[8][127:96] <= keyreg[7][95:64];
                keyreg[8][95:64] <= keyreg[7][63:32];
                keyreg[8][63:32] <= keyreg[7][31:0];
                keyreg[8][31:0] <= k_result[8];

                keyreg[9][127:96] <= keyreg[8][95:64];
                keyreg[9][95:64] <= keyreg[8][63:32];
                keyreg[9][63:32] <= keyreg[8][31:0];
                keyreg[9][31:0] <= k_result[9];

                keyreg[10][127:96] <= keyreg[9][95:64];
                keyreg[10][95:64] <= keyreg[9][63:32];
                keyreg[10][63:32] <= keyreg[9][31:0];
                keyreg[10][31:0] <= k_result[10];

                keyreg[11][127:96] <= keyreg[10][95:64];
                keyreg[11][95:64] <= keyreg[10][63:32];
                keyreg[11][63:32] <= keyreg[10][31:0];
                keyreg[11][31:0] <= k_result[11];

                keyreg[12][127:96] <= keyreg[11][95:64];
                keyreg[12][95:64] <= keyreg[11][63:32];
                keyreg[12][63:32] <= keyreg[11][31:0];
                keyreg[12][31:0] <= k_result[12];

                keyreg[13][127:96] <= keyreg[12][95:64];
                keyreg[13][95:64] <= keyreg[12][63:32];
                keyreg[13][63:32] <= keyreg[12][31:0];
                keyreg[13][31:0] <= k_result[13];

                keyreg[14][127:96] <= keyreg[13][95:64];
                keyreg[14][95:64] <= keyreg[13][63:32];
                keyreg[14][63:32] <= keyreg[13][31:0];
                keyreg[14][31:0] <= k_result[14];

                keyreg[15][127:96] <= keyreg[14][95:64];
                keyreg[15][95:64] <= keyreg[14][63:32];
                keyreg[15][63:32] <= keyreg[14][31:0];
                keyreg[15][31:0] <= k_result[15];

                keyreg[16][127:96] <= keyreg[15][95:64];
                keyreg[16][95:64] <= keyreg[15][63:32];
                keyreg[16][63:32] <= keyreg[15][31:0];
                keyreg[16][31:0] <= k_result[16];

                keyreg[17][127:96] <= keyreg[16][95:64];
                keyreg[17][95:64] <= keyreg[16][63:32];
                keyreg[17][63:32] <= keyreg[16][31:0];
                keyreg[17][31:0] <= k_result[17];

                keyreg[18][127:96] <= keyreg[17][95:64];
                keyreg[18][95:64] <= keyreg[17][63:32];
                keyreg[18][63:32] <= keyreg[17][31:0];
                keyreg[18][31:0] <= k_result[18];

                keyreg[19][127:96] <= keyreg[18][95:64];
                keyreg[19][95:64] <= keyreg[18][63:32];
                keyreg[19][63:32] <= keyreg[18][31:0];
                keyreg[19][31:0] <= k_result[19];

                keyreg[20][127:96] <= keyreg[19][95:64];
                keyreg[20][95:64] <= keyreg[19][63:32];
                keyreg[20][63:32] <= keyreg[19][31:0];
                keyreg[20][31:0] <= k_result[20];

                keyreg[21][127:96] <= keyreg[20][95:64];
                keyreg[21][95:64] <= keyreg[20][63:32];
                keyreg[21][63:32] <= keyreg[20][31:0];
                keyreg[21][31:0] <= k_result[21];

                keyreg[22][127:96] <= keyreg[21][95:64];
                keyreg[22][95:64] <= keyreg[21][63:32];
                keyreg[22][63:32] <= keyreg[21][31:0];
                keyreg[22][31:0] <= k_result[22];

                keyreg[23][127:96] <= keyreg[22][95:64];
                keyreg[23][95:64] <= keyreg[22][63:32];
                keyreg[23][63:32] <= keyreg[22][31:0];
                keyreg[23][31:0] <= k_result[23];

                keyreg[24][127:96] <= keyreg[23][95:64];
                keyreg[24][95:64] <= keyreg[23][63:32];
                keyreg[24][63:32] <= keyreg[23][31:0];
                keyreg[24][31:0] <= k_result[24];

                keyreg[25][127:96] <= keyreg[24][95:64];
                keyreg[25][95:64] <= keyreg[24][63:32];
                keyreg[25][63:32] <= keyreg[24][31:0];
                keyreg[25][31:0] <= k_result[25];

                keyreg[26][127:96] <= keyreg[25][95:64];
                keyreg[26][95:64] <= keyreg[25][63:32];
                keyreg[26][63:32] <= keyreg[25][31:0];
                keyreg[26][31:0] <= k_result[26];

                keyreg[27][127:96] <= keyreg[26][95:64];
                keyreg[27][95:64] <= keyreg[26][63:32];
                keyreg[27][63:32] <= keyreg[26][31:0];
                keyreg[27][31:0] <= k_result[27];

                keyreg[28][127:96] <= keyreg[27][95:64];
                keyreg[28][95:64] <= keyreg[27][63:32];
                keyreg[28][63:32] <= keyreg[27][31:0];
                keyreg[28][31:0] <= k_result[28];

                keyreg[29][127:96] <= keyreg[28][95:64];
                keyreg[29][95:64] <= keyreg[28][63:32];
                keyreg[29][63:32] <= keyreg[28][31:0];
                keyreg[29][31:0] <= k_result[29];

                keyreg[30][127:96] <= keyreg[29][95:64];
                keyreg[30][95:64] <= keyreg[29][63:32];
                keyreg[30][63:32] <= keyreg[29][31:0];
                keyreg[30][31:0] <= k_result[30];

                keyreg[31][127:96] <= keyreg[30][95:64];
                keyreg[31][95:64] <= keyreg[30][63:32];
                keyreg[31][63:32] <= keyreg[30][31:0];
                keyreg[31][31:0] <= k_result[31];
                
        end
    end

    /* output logic */
    assign rk = { keyreg[0][31:0], keyreg[1][31:0], keyreg[2][31:0], keyreg[3][31:0], 
                  keyreg[4][31:0], keyreg[5][31:0], keyreg[6][31:0], keyreg[7][31:0],
                  keyreg[8][31:0], keyreg[9][31:0], keyreg[10][31:0], keyreg[11][31:0],
                  keyreg[12][31:0], keyreg[13][31:0], keyreg[14][31:0], keyreg[15][31:0],
                  keyreg[16][31:0], keyreg[17][31:0], keyreg[18][31:0], keyreg[19][31:0],
                  keyreg[20][31:0], keyreg[21][31:0], keyreg[22][31:0], keyreg[23][31:0],
                  keyreg[24][31:0], keyreg[25][31:0], keyreg[26][31:0], keyreg[27][31:0],
                  keyreg[28][31:0], keyreg[29][31:0], keyreg[30][31:0], keyreg[31][31:0] } ;

    // CK
    function[31: 0] cki;
        input[ 4: 0] sin;
        case (sin)
            5'd0:   cki = 32'h00070e15;
            5'd1:   cki = 32'h1c232a31;
            5'd2:   cki = 32'h383f464d;
            5'd3:   cki = 32'h545b6269;
            5'd4:   cki = 32'h70777e85;
            5'd5:   cki = 32'h8c939aa1;
            5'd6:   cki = 32'ha8afb6bd;
            5'd7:   cki = 32'hc4cbd2d9;
            5'd8:   cki = 32'he0e7eef5;
            5'd9:   cki = 32'hfc030a11;
            5'd10:  cki = 32'h181f262d;
            5'd11:  cki = 32'h343b4249;
            5'd12:  cki = 32'h50575e65;
            5'd13:  cki = 32'h6c737a81;
            5'd14:  cki = 32'h888f969d;
            5'd15:  cki = 32'ha4abb2b9;
            5'd16:  cki = 32'hc0c7ced5;
            5'd17:  cki = 32'hdce3eaf1;
            5'd18:  cki = 32'hf8ff060d;
            5'd19:  cki = 32'h141b2229;
            5'd20:  cki = 32'h30373e45;
            5'd21:  cki = 32'h4c535a61;
            5'd22:  cki = 32'h686f767d;
            5'd23:  cki = 32'h848b9299;
            5'd24:  cki = 32'ha0a7aeb5;
            5'd25:  cki = 32'hbcc3cad1;
            5'd26:  cki = 32'hd8dfe6ed;
            5'd27:  cki = 32'hf4fb0209;
            5'd28:  cki = 32'h10171e25;
            5'd29:  cki = 32'h2c333a41;
            5'd30:  cki = 32'h484f565d;
            5'd31:  cki = 32'h646b7279;
            default:cki = 32'h00000000;
        endcase
    endfunction


endmodule
