`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 24/1/2023 
// Design Name: 
// Module Name:    enctop
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
//     enc module of sm4
//     just input data and rk
//////////////////////////////////////////////////////////////////////////////////
module enc_top (
    clk,
    rstn,
    data,
    dataout,
    rk
);
    input wire clk;
    input wire rstn;
    input wire[127:0] data;
    // input wire start;
    output wire[127:0] dataout;
    input wire[1023:0] rk;
    //output wire valid;

    /* registers */
    reg  [127:0]         xreg[0:32]; //save the x, [127:96] of each is the new x
    wire [31:0]      x_result[0:31];
    reg  [127:0]              xregp; //pre for xreg

    /* calculate x modules, 32 normal */
    genvar i;
    generate
        for(i=0;i<32;i=i+1) begin:genx
            x_calculate x_calculate_inst(
                xreg[i][127:96],
                xreg[i][95:64],
                xreg[i][63:32],
                xreg[i][31:0],
                x_result[(i)],
                rk[(1023-(32*i)) -: 32]);
        end
    endgenerate

    integer j;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            xregp <= 0;
            xreg[0] <= 0;xreg[1] <= 0;xreg[2] <= 0;xreg[3] <= 0;
            xreg[4] <= 0;xreg[5] <= 0;xreg[6] <= 0;xreg[7] <= 0;
            xreg[8] <= 0;xreg[9] <= 0;xreg[10] <= 0;xreg[11] <= 0;
            xreg[12] <= 0;xreg[13] <= 0;xreg[14] <= 0;xreg[15] <= 0;
            xreg[16] <= 0;xreg[17] <= 0;xreg[18] <= 0;xreg[19] <= 0;
            xreg[20] <= 0;xreg[21] <= 0;xreg[22] <= 0;xreg[23] <= 0;
            xreg[24] <= 0;xreg[25] <= 0;xreg[26] <= 0;xreg[27] <= 0;
            xreg[28] <= 0;xreg[29] <= 0;xreg[30] <= 0;xreg[31] <= 0;
            xreg[32] <= 0;
        end
        else begin
            xregp <= data;
            xreg[0] <= xregp;

            // move logic
            // every register, low32 flow to high32, new data save in low32
                xreg[1][127:96] <= xreg[0][95:64];
                xreg[1][95:64] <= xreg[0][63:32];
                xreg[1][63:32] <= xreg[0][31:0];
                xreg[1][31:0] <= x_result[0];

                xreg[2][127:96] <= xreg[1][95:64];
                xreg[2][95:64] <= xreg[1][63:32];
                xreg[2][63:32] <= xreg[1][31:0];
                xreg[2][31:0] <= x_result[1];

                xreg[3][127:96] <= xreg[2][95:64];
                xreg[3][95:64] <= xreg[2][63:32];
                xreg[3][63:32] <= xreg[2][31:0];
                xreg[3][31:0] <= x_result[2];

                xreg[4][127:96] <= xreg[3][95:64];
                xreg[4][95:64] <= xreg[3][63:32];
                xreg[4][63:32] <= xreg[3][31:0];
                xreg[4][31:0] <= x_result[3];

                xreg[5][127:96] <= xreg[4][95:64];
                xreg[5][95:64] <= xreg[4][63:32];
                xreg[5][63:32] <= xreg[4][31:0];
                xreg[5][31:0] <= x_result[4];

                xreg[6][127:96] <= xreg[5][95:64];
                xreg[6][95:64] <= xreg[5][63:32];
                xreg[6][63:32] <= xreg[5][31:0];
                xreg[6][31:0] <= x_result[5];

                xreg[7][127:96] <= xreg[6][95:64];
                xreg[7][95:64] <= xreg[6][63:32];
                xreg[7][63:32] <= xreg[6][31:0];
                xreg[7][31:0] <= x_result[6];

                xreg[8][127:96] <= xreg[7][95:64];
                xreg[8][95:64] <= xreg[7][63:32];
                xreg[8][63:32] <= xreg[7][31:0];
                xreg[8][31:0] <= x_result[7];

                xreg[9][127:96] <= xreg[8][95:64];
                xreg[9][95:64] <= xreg[8][63:32];
                xreg[9][63:32] <= xreg[8][31:0];
                xreg[9][31:0] <= x_result[8];

                xreg[10][127:96] <= xreg[9][95:64];
                xreg[10][95:64] <= xreg[9][63:32];
                xreg[10][63:32] <= xreg[9][31:0];
                xreg[10][31:0] <= x_result[9];

                xreg[11][127:96] <= xreg[10][95:64];
                xreg[11][95:64] <= xreg[10][63:32];
                xreg[11][63:32] <= xreg[10][31:0];
                xreg[11][31:0] <= x_result[10];

                xreg[12][127:96] <= xreg[11][95:64];
                xreg[12][95:64] <= xreg[11][63:32];
                xreg[12][63:32] <= xreg[11][31:0];
                xreg[12][31:0] <= x_result[11];

                xreg[13][127:96] <= xreg[12][95:64];
                xreg[13][95:64] <= xreg[12][63:32];
                xreg[13][63:32] <= xreg[12][31:0];
                xreg[13][31:0] <= x_result[12];

                xreg[14][127:96] <= xreg[13][95:64];
                xreg[14][95:64] <= xreg[13][63:32];
                xreg[14][63:32] <= xreg[13][31:0];
                xreg[14][31:0] <= x_result[13];

                xreg[15][127:96] <= xreg[14][95:64];
                xreg[15][95:64] <= xreg[14][63:32];
                xreg[15][63:32] <= xreg[14][31:0];
                xreg[15][31:0] <= x_result[14];

                xreg[16][127:96] <= xreg[15][95:64];
                xreg[16][95:64] <= xreg[15][63:32];
                xreg[16][63:32] <= xreg[15][31:0];
                xreg[16][31:0] <= x_result[15];

                xreg[17][127:96] <= xreg[16][95:64];
                xreg[17][95:64] <= xreg[16][63:32];
                xreg[17][63:32] <= xreg[16][31:0];
                xreg[17][31:0] <= x_result[16];

                xreg[18][127:96] <= xreg[17][95:64];
                xreg[18][95:64] <= xreg[17][63:32];
                xreg[18][63:32] <= xreg[17][31:0];
                xreg[18][31:0] <= x_result[17];

                xreg[19][127:96] <= xreg[18][95:64];
                xreg[19][95:64] <= xreg[18][63:32];
                xreg[19][63:32] <= xreg[18][31:0];
                xreg[19][31:0] <= x_result[18];

                xreg[20][127:96] <= xreg[19][95:64];
                xreg[20][95:64] <= xreg[19][63:32];
                xreg[20][63:32] <= xreg[19][31:0];
                xreg[20][31:0] <= x_result[19];

                xreg[21][127:96] <= xreg[20][95:64];
                xreg[21][95:64] <= xreg[20][63:32];
                xreg[21][63:32] <= xreg[20][31:0];
                xreg[21][31:0] <= x_result[20];

                xreg[22][127:96] <= xreg[21][95:64];
                xreg[22][95:64] <= xreg[21][63:32];
                xreg[22][63:32] <= xreg[21][31:0];
                xreg[22][31:0] <= x_result[21];

                xreg[23][127:96] <= xreg[22][95:64];
                xreg[23][95:64] <= xreg[22][63:32];
                xreg[23][63:32] <= xreg[22][31:0];
                xreg[23][31:0] <= x_result[22];

                xreg[24][127:96] <= xreg[23][95:64];
                xreg[24][95:64] <= xreg[23][63:32];
                xreg[24][63:32] <= xreg[23][31:0];
                xreg[24][31:0] <= x_result[23];

                xreg[25][127:96] <= xreg[24][95:64];
                xreg[25][95:64] <= xreg[24][63:32];
                xreg[25][63:32] <= xreg[24][31:0];
                xreg[25][31:0] <= x_result[24];

                xreg[26][127:96] <= xreg[25][95:64];
                xreg[26][95:64] <= xreg[25][63:32];
                xreg[26][63:32] <= xreg[25][31:0];
                xreg[26][31:0] <= x_result[25];

                xreg[27][127:96] <= xreg[26][95:64];
                xreg[27][95:64] <= xreg[26][63:32];
                xreg[27][63:32] <= xreg[26][31:0];
                xreg[27][31:0] <= x_result[26];

                xreg[28][127:96] <= xreg[27][95:64];
                xreg[28][95:64] <= xreg[27][63:32];
                xreg[28][63:32] <= xreg[27][31:0];
                xreg[28][31:0] <= x_result[27];

                xreg[29][127:96] <= xreg[28][95:64];
                xreg[29][95:64] <= xreg[28][63:32];
                xreg[29][63:32] <= xreg[28][31:0];
                xreg[29][31:0] <= x_result[28];

                xreg[30][127:96] <= xreg[29][95:64];
                xreg[30][95:64] <= xreg[29][63:32];
                xreg[30][63:32] <= xreg[29][31:0];
                xreg[30][31:0] <= x_result[29];

                xreg[31][127:96] <= xreg[30][95:64];
                xreg[31][95:64] <= xreg[30][63:32];
                xreg[31][63:32] <= xreg[30][31:0];
                xreg[31][31:0] <= x_result[30];

                xreg[32][127:96] <= xreg[31][95:64];
                xreg[32][95:64] <= xreg[31][63:32];
                xreg[32][63:32] <= xreg[31][31:0];
                xreg[32][31:0] <= x_result[31];
        end
    end

    assign dataout = xreg[32];

endmodule