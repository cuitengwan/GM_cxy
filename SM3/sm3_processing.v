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
module sm3_processing(
    clk,
    rstn,
    datain,
    hashin_a,
    hashin_b,
    hashin_c,
    hashin_d,
    hashin_e,
    hashin_f,
    hashin_g,
    hashin_h,
    start,
    hashout,
    valid
);
    input wire clk;
    input wire rstn;
    input wire[511:0] datain;
    input wire[31:0] hashin_a;
    input wire[31:0] hashin_b;
    input wire[31:0] hashin_c;
    input wire[31:0] hashin_d;
    input wire[31:0] hashin_e;
    input wire[31:0] hashin_f;
    input wire[31:0] hashin_g;
    input wire[31:0] hashin_h;
    input wire start;
    output wire[255:0] hashout;
    output wire valid;

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

    reg [511:0]          r_data;
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
    localparam DIN    = 6'b000010;
    localparam ROUND  = 6'b000100;
    localparam XOR    = 6'b001000;
    localparam FIN    = 6'b010000;

    // counter
    reg[9:0] counter;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:begin
                    state <= start ? DIN : IDLE;
                end
                DIN:begin
                    state <= ROUND;
                end
                ROUND:begin
                    state <= (counter>=63) ? XOR : ROUND;
                end
                XOR:begin
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
            save_A <= 0;
            save_B <= 0;
            save_C <= 0;
            save_D <= 0;
            save_E <= 0;
            save_F <= 0;
            save_G <= 0;
            save_H <= 0;
            r_TJC <= 32'h79cc4519;
        end
        else begin
            case(state)
                IDLE: begin
                    A <= hashin_a;
                    B <= hashin_b;
                    C <= hashin_c;
                    D <= hashin_d;
                    E <= hashin_e;
                    F <= hashin_f;
                    G <= hashin_g;
                    H <= hashin_h;
                    save_A <= hashin_a;
                    save_B <= hashin_b;
                    save_C <= hashin_c;
                    save_D <= hashin_d;
                    save_E <= hashin_e;
                    save_F <= hashin_f;
                    save_G <= hashin_g;
                    save_H <= hashin_h;
                    counter <= 0;
                    r_data <= datain;
                    r_W <= datain;
                    r_TJC <= 32'h79cc4519;
                end
                DIN:begin
                    // do nothing?
                end
                ROUND:begin
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
                XOR:begin
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

    assign hashout = { A,B,C,D,E,F,G,H };
    assign valid = ( state == FIN ) ? 1 : 0;
 

endmodule
