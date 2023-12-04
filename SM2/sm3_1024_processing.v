`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 18/11/2022 
// Design Name: 
// Module Name:    SM3 processing
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
//     sm3 processing module, including expantion and compress
//     input 1024 bit data, output 256 hash result
//////////////////////////////////////////////////////////////////////////////////
module sm3_1024_processing(
    clk,
    rstn,
    datain,
    start,
    hashout,
    valid
);
    input wire clk;
    input wire rstn;
    input wire[1023:0] datain;
    input wire start;
    output wire[255:0] hashout;
    output wire valid;

    // counter
    reg[9:0] counter;

    // fixed parameter
    wire[31:0]              IV_A;
    wire[31:0]              IV_B;
    wire[31:0]              IV_C;
    wire[31:0]              IV_D;
    wire[31:0]              IV_E;
    wire[31:0]              IV_F;
    wire[31:0]              IV_G;
    wire[31:0]              IV_H;
    assign IV_A = 32'h7380166F;
    assign IV_B = 32'h4914b2b9;
    assign IV_C = 32'h172442d7;
    assign IV_D = 32'hda8a0600;
    assign IV_E = 32'ha96f30bc;
    assign IV_F = 32'h163138aa;
    assign IV_G = 32'he38dee4d;
    assign IV_H = 32'hb0fb0e4e;
    wire[31:0]              TJ1;
    wire[31:0]              TJ2;
    assign TJ1 = 32'h79cc4519;
    assign TJ2 = 32'h7a879d8a;
    wire[31:0]              TJC;
    reg [31:0]            r_TJC;
    assign TJC = r_TJC;

    // data reg
    reg [31:0]                 A;
    reg [31:0]                 B;
    reg [31:0]                 C;
    reg [31:0]                 D;
    reg [31:0]                 E;
    reg [31:0]                 F;
    reg [31:0]                 G;
    reg [31:0]                 H;

    reg [1023:0]          r_data;
    reg [511:0]              r_W;

    wire[31:0]	         W0,W1,W2,W3,W4,W5,W6,W7,W8,W9,W10,W11,W12,W13,W14,W15;
    wire[31:0]               W16; // Wj
    wire[31:0]              W16x;
    wire[31:0]               W0j; // Wj'

    assign {W0,W1,W2,W3,W4,W5,W6,W7} = r_W[511:256];
	assign {W8,W9,W10,W11,W12,W13,W14,W15} = r_W[255:0];
    assign W16x = W0^W7^{W13[16:0],W13[31:17]};
	assign W16 = (W16x^{W16x[16:0],W16x[31:17]}^{W16x[8:0],W16x[31:9]})^{W3[24:0],W3[31:25]}^W10;
	assign W0j = W0^W4;

    // save the result of round1
    reg [31:0]            save_A;
    reg [31:0]            save_B;
    reg [31:0]            save_C;
    reg [31:0]            save_D;
    reg [31:0]            save_E;
    reg [31:0]            save_F;
    reg [31:0]            save_G;
    reg [31:0]            save_H;

    // state machine
    reg[5:0] state;
    localparam IDLE   = 6'b000001;
    localparam ROUND1 = 6'b000010;
    localparam MID    = 6'b000100;
    localparam ROUND2 = 6'b001000;
    localparam MID2   = 6'b010000;
    localparam FIN    = 6'b100000;

    // counter
    

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:begin
                    state <= start ? ROUND1 : IDLE;
                end
                ROUND1:begin
                    state <= (counter>=63) ? MID : ROUND1;
                end
                MID:begin
                    state <= ROUND2;
                end
                ROUND2:begin
                    state <= (counter>=63) ? MID2 : ROUND2;
                end
                MID2:begin
                    state <= FIN;
                end
                FIN:begin
                    state <= IDLE;
                end
                default:begin
                end
            endcase
        end
    end

    // calculate wires
    wire[31:0] SS1p;
    wire[31:0] SS1;
    wire[31:0] SS2;
    wire[31:0] TT1;
    wire[31:0] TT2;
    assign SS1p = { A[19:0], A[31:20] } + E + TJC;
    assign SS1 = { SS1p[24:0], SS1p[31:25] };
    assign SS2 = SS1 ^ { A[19:0], A[31:20] };
    assign TT1 = ( counter<=7'd15 ) ? ((A^B^C)+D+SS2+W0j) : (((A&B)|(A&C)|(B&C))+D+SS2+W0j);
    assign TT2 = (counter<=7'd15) ? ((E^F^G)+H+SS1+W0) : (((E&F)|((~E)&G))+H+SS1+W0);

    // data change
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            A <= 0;
            B <= 0;
            C <= 0;
            D <= 0;
            E <= 0;
            F <= 0;
            G <= 0;
            H <= 0;
            counter <= 0;
            r_data <= 0;
            r_W <= 0;
            r_TJC <= 32'h79cc4519;
        end
        else begin
            case(state)
                IDLE: begin
                    A <= IV_A;
                    B <= IV_B;
                    C <= IV_C;
                    D <= IV_D;
                    E <= IV_E;
                    F <= IV_F;
                    G <= IV_G;
                    H <= IV_H;
                    counter <= 0;
                    r_data <= datain;
                    r_W <= datain[1023:512];
                end
                ROUND1:begin
                    A <= TT1;
                    B <= A;
                    C <= {B[22:0],B[31:23]};
                    D <= C;
                    E <= (TT2^{TT2[22:0],TT2[31:23]}^{TT2[14:0],TT2[31:15]});
                    F <= E;
                    G <= {F[12:0],F[31:13]};
                    H <= G;
                    counter <= counter + 1;
                    r_W <= {W1,W2,W3,W4,W5,W6,W7,W8,W9,W10,W11,W12,W13,W14,W15,W16};
                    if(counter==7'd15) begin
			            r_TJC <= 32'h9d8a7a87;  //32'h7a879d8a<<16;
                    end
		            else begin
			            r_TJC <= {r_TJC[30:0],r_TJC[31]};
                    end
                end
                MID:begin
                    counter <= 0;
                    r_W <= r_data[511:0];
                    save_A <= A ^ IV_A;
                    save_B <= B ^ IV_B;
                    save_C <= C ^ IV_C;
                    save_D <= D ^ IV_D;
                    save_E <= E ^ IV_E;
                    save_F <= F ^ IV_F;
                    save_G <= G ^ IV_G;
                    save_H <= H ^ IV_H;
                    A <= A ^ IV_A;
                    B <= B ^ IV_B;
                    C <= C ^ IV_C;
                    D <= D ^ IV_D;
                    E <= E ^ IV_E;
                    F <= F ^ IV_F;
                    G <= G ^ IV_G;
                    H <= H ^ IV_H;
                    r_TJC <= 32'h79cc4519;
                end
                ROUND2:begin
                    A <= TT1;
                    B <= A;
                    C <= {B[22:0],B[31:23]};
                    D <= C;
                    E <= (TT2^{TT2[22:0],TT2[31:23]}^{TT2[14:0],TT2[31:15]});
                    F <= E;
                    G <= {F[12:0],F[31:13]};
                    H <= G;
                    counter <= counter + 1;
                    r_W <= {W1,W2,W3,W4,W5,W6,W7,W8,W9,W10,W11,W12,W13,W14,W15,W16};
                    if(counter==7'd15) begin
			            r_TJC <= 32'h9d8a7a87;  //32'h7a879d8a<<16;
                    end
		            else begin
			            r_TJC <= {r_TJC[30:0],r_TJC[31]};
                    end
                end
                MID2:begin
                    A <= A ^ save_A;
                    B <= B ^ save_B;
                    C <= C ^ save_C;
                    D <= D ^ save_D;
                    E <= E ^ save_E;
                    F <= F ^ save_F;
                    G <= G ^ save_G;
                    H <= H ^ save_H;
                end
                FIN:begin
                    counter <= 0;
                end
                default:begin
                end
            endcase
        end
    end

    assign hashout = { A,B,C,D,E,F,G,H};
    assign valid = ( state == FIN ) ? 1 : 0;
 

endmodule
