`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 22/11/2022 
// Design Name: 
// Module Name:    SM2 top
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
//     top module of SM2 algorithm ( input changed )
//     input: data is 32 bit each group.
//     k is random number, length is bit length of plaintext
//     pbx and pby is (x,y) of point PB
//     decrypt: 1 is decrypt mode
//     start: cycle1 start is valid, and cycle2 start to input
//     input data: 2048 bit
//     enc: k(256) pbx(256) pby(256) length(32) din(32*32) useless(32*7)
//     dec: db(256) c1x(256) c1y(256) c3(256) length(32) c2(32*16) useless(32*15)
//     output data: 32*n
//////////////////////////////////////////////////////////////////////////////////
module SM2(
    clk,
    rstn,
    din,
    decrypt,
    start,
    dout,
    valid
);
    input wire clk;
    input wire rstn;
    input wire[2047:0] din;
    input wire decrypt;
    input wire start;
    output wire[2047:0] dout;
    output wire valid;


    // constant
    parameter P = 256'hFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF;
    parameter A = 256'hFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFC;
    parameter B = 256'h28E9FA9E9D9F5E344D5A9E4BCF6509A7F39789F515AB8F92DDBCBD414D940E93;
    parameter n = 256'hFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFF7203DF6B21C6052B53BBF40939D54123;
    parameter GX = 256'h32C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7;
    parameter GY = 256'hBC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0;
    parameter constant1 = 256'h0000000000000000000000000000000000000000000000000000000000000001;

    // memory
    reg is_dec_reg;
    reg[31:0] plaintext[0:31];
    reg[31:0] ciphertext[0:31];
    reg[2559:0] shifter_reg; // shift register
    reg[31:0] t_reg[0:31];
    reg[255:0] k_reg;
    reg[255:0] db_reg;
    reg[255:0] pbx_reg;
    reg[255:0] pby_reg;
    reg[255:0] c1_x;
    reg[255:0] c1_y;
    reg[255:0] kpb_x;
    reg[255:0] kpb_y;
    reg[255:0] c3;
    reg[255:0] dbc1_x;
    reg[255:0] dbc1_y;
    reg[31:0] dout_counter1;
    reg[31:0] dout_counter2;
    reg[31:0] dout_counter3;
    reg[7:0] t_counter;
    reg[31:0] plaintext_length;
    reg[31:0] plaintext_last_length;
    reg[2047:0] doutreg;
    reg doutvalidreg;
    assign dout = doutreg;
    assign valid = doutvalidreg;
    reg[255:0] r_dec1x;
    reg[255:0] r_dec1y;
    reg[255:0] r_dec3;

    // shift register
    reg[31:0] srlength; // length of all data in shift register, add 256 or 32 after each filling
    reg[31:0] srcounter; // how many groups of whole 32bit plaintext
    wire[31:0] srbacklength; // in shift_back state, shift right (32-lastgrouplength)
    assign srbacklength = 32 - plaintext_last_length;
    wire[31:0] srshiftlength; // finally, shift all data to left
    assign srshiftlength = 2560 - srlength;
    wire[31:0] plaintext_wholegroups; // group number of whole data
    assign plaintext_wholegroups = plaintext_length >> 5;

    // sm3
    wire[31:0] sm3_din_groups_minus2; // groups of 512 bit data
    // groups should be 2,3,4,5 , need to judge counter>=groups-2
    assign sm3_din_groups_minus2 = ( srlength < 1025 ) ? 0 : 
                                   ( srlength < 1537 ) ? 1 :
                                   ( srlength < 2049 ) ? 2 : 3 ;

    // output c1 and c3
    reg[31:0] c1out[0:15];
    reg[31:0] c3out[0:7];

    // state machine
    reg[31:0] state;
    localparam IDLE   = 32'b00000000000000000000000000000001;
    localparam DIN    = 32'b00000000000000000000000000000010;
    localparam PRE1   = 32'b00000000000000000000000000000100;
    localparam MUL1   = 32'b00000000000000000000000000001000;
    localparam UPD1   = 32'b00000000000000000000000000010000;
    localparam PRE2   = 32'b00000000000000000000000000100000;
    localparam TRANS1 = 32'b00000000000000000000000001000000;
    localparam UPD2   = 32'b00000000000000000000000010000000;
    localparam PRE3   = 32'b00000000000000000000000100000000;
    localparam MUL2   = 32'b00000000000000000000001000000000;
    localparam UPD3   = 32'b00000000000000000000010000000000;
    localparam PRE4   = 32'b00000000000000000000100000000000;
    localparam TRANS2 = 32'b00000000000000000001000000000000;
    localparam UPD4   = 32'b00000000000000000010000000000000;
    localparam PRE5   = 32'b00000000000000000100000000000000;
    localparam KDF    = 32'b00000000000000001000000000000000;
    localparam UPD5   = 32'b00000000000000010000000000000000;
    localparam XOR    = 32'b00000000000000100000000000000000;
    localparam UPD6   = 32'b00000000000001000000000000000000;
    localparam PRE7   = 32'b00000000000010000000000000000000; // filling to shift register
    localparam PRE7S1 = 32'b00000000000010000000000000000001; // shift 256 + 256 x
    localparam PRE7S2 = 32'b00000000000010000000000000000010; // every time shift 32 + 32bit whole
    localparam PRE7S3 = 32'b00000000000010000000000000000100; // shift 32 + last
    localparam PRE7S4 = 32'b00000000000010000000000000001000; // shift back (32-last_length)
    localparam PRE7S5 = 32'b00000000000010000000000000010000; // shift 256 + 256 y 
    localparam PRE7S6 = 32'b00000000000010000000000000100000; // shift to left
    localparam SM3IN  = 32'b00000000000100000000000000000000;
    localparam SM3    = 32'b00000000001000000000000000000000;
    localparam UPD7   = 32'b00000000010000000000000000000000;
    localparam PRE8   = 32'b00000000100000000000000000000000;
    localparam DOUTP  = 32'b00000001000000000000000000000001; // output c1,c2,c3
    localparam DOUT   = 32'b00000001000000000000000000010000; // dout finished
    localparam FIN    = 32'b00000010000000000000000000000000;
    // decrypt mode
    localparam ISDEC  = 32'b10000000000000000000000000000000;
    localparam DC2    = 32'b10000000000000000000000000000001;
    localparam DPRE1  = 32'b10000000000000000000000000000010;
    localparam DMUL1  = 32'b10000000000000000000000000000100;
    localparam DUPD1  = 32'b10000000000000000000000000001000;
    localparam DPRE2  = 32'b10000000000000000000000000010000;
    localparam DTRANS = 32'b10000000000000000000000000100000;
    localparam DUPD2  = 32'b10000000000000000000000001000000;
    localparam DPRE3  = 32'b10000000000000000000000010000000;
    localparam DKDF   = 32'b10000000000000000000000100000000;
    localparam DUPD3  = 32'b10000000000000000000001000000000;
    localparam DXOR   = 32'b10000000000000000000010000000000;
    localparam DUPD4  = 32'b10000000000000000000100000000000;
    localparam DPRE5  = 32'b10000000000000000001000000000000;
    localparam DPRE5S1= 32'b10000000000000000001000000000001;
    localparam DPRE5S2= 32'b10000000000000000001000000000010;
    localparam DPRE5S3= 32'b10000000000000000001000000000100;
    localparam DPRE5S4= 32'b10000000000000000001000000001000;
    localparam DPRE5S5= 32'b10000000000000000001000000010000;
    localparam DPRE5S6= 32'b10000000000000000001000000100000;
    localparam DSM3IN = 32'b10000000000000000010000000000000;
    localparam DSM3   = 32'b10000000000000000100000000000000;
    localparam DUPD5  = 32'b10000000000000001000000000000000;
    localparam DDOUTP = 32'b10000000000000010000000000000000;
    localparam DDOUT  = 32'b10000000000000100000000000000000;

    wire current_finished;
    
    wire shiftend; // shiftend condition: current memorycounter > groups-2
    assign shiftend = ( plaintext_wholegroups < 2 ) ? 1 : 
                      ( srcounter > ( plaintext_wholegroups - 2 ) ) ? 1 : 0;

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
                    state <= ISDEC;
                end
                ISDEC:begin
                    state <= decrypt ? DC2 : PRE1;
                end
                PRE1:begin
                    state <= MUL1;
                end
                MUL1:begin
                    state <= current_finished ? UPD1 : MUL1;
                end
                UPD1:begin
                    state <= PRE2;
                end
                PRE2:begin
                    state <= TRANS1;
                end
                TRANS1:begin
                    state <= current_finished ? UPD2 : TRANS1;
                end
                UPD2:begin
                    state <= PRE3;
                end
                PRE3:begin
                    state <= MUL2;
                end
                MUL2:begin
                    state <= current_finished ? UPD3 : MUL2;
                end
                UPD3:begin
                    state <= PRE4;
                end
                PRE4:begin
                    state <= TRANS2;
                end
                TRANS2:begin
                    state <= current_finished ? UPD4 : TRANS2;
                end
                UPD4:begin
                    state <= PRE5;
                end
                PRE5:begin
                    state <= KDF;
                end
                KDF:begin
                    state <= current_finished ? UPD5 : KDF;
                end
                UPD5:begin
                    state <= XOR;
                end
                XOR:begin
                    state <= UPD6;
                end
                UPD6:begin
                    state <= PRE7;
                end
                PRE7:begin
                    state <= PRE7S1;
                end
                PRE7S1:begin
                    state <= PRE7S2;
                end
                PRE7S2:begin
                    state <= shiftend ? PRE7S3 : PRE7S2;
                end
                PRE7S3:begin
                    state <= PRE7S4;
                end
                PRE7S4:begin
                    state <= PRE7S5;
                end
                PRE7S5:begin
                    state <= PRE7S6;
                end
                PRE7S6:begin
                    state <= SM3IN;
                end
                SM3IN:begin
                    state <= SM3;
                end
                SM3:begin
                    state <= current_finished ? UPD7 : SM3;
                end
                UPD7:begin
                    state <= PRE8;
                end
                PRE8:begin
                    state <= DOUTP;
                end
                DOUTP:begin
                    state <= DOUT;
                end
                DOUT:begin
                    state <= FIN;
                end
                DC2:begin
                    state <= DPRE1;
                end
                DPRE1:begin
                    state <= DMUL1;
                end
                DMUL1:begin
                    state <= current_finished ? DUPD1 : DMUL1;
                end
                DUPD1:begin
                    state <= DPRE2;
                end
                DPRE2:begin
                    state <= DTRANS;
                end
                DTRANS:begin
                    state <= current_finished ? DUPD2 : DTRANS;
                end
                DUPD2:begin
                    state <= DPRE3;
                end
                DPRE3:begin
                    state <= DKDF;
                end
                DKDF:begin
                    state <= current_finished ? DUPD3 : DKDF;
                end
                DUPD3:begin
                    state <= DXOR;
                end
                DXOR:begin
                    state <= DUPD4;
                end
                DUPD4:begin
                    state <= DPRE5;
                end
                DPRE5:begin
                    state <= DPRE5S1;
                end
                DPRE5S1:begin
                    state <= DPRE5S2;
                end
                DPRE5S2:begin
                    state <= DPRE5S3;
                end
                DPRE5S3:begin
                    state <= DPRE5S4;
                end
                DPRE5S4:begin
                    state <= DPRE5S5;
                end
                DPRE5S5:begin
                    state <= DPRE5S6;
                end
                DPRE5S6:begin
                    state <= DSM3IN;
                end
                DSM3IN:begin
                    state <= DSM3;
                end
                DSM3:begin
                    state <= current_finished ? DUPD5 : DSM3;
                end
                DUPD5:begin
                    state <= DDOUTP;
                end
                DDOUTP:begin
                    state <= DDOUT;
                end
                DDOUT:begin
                    state <= FIN;
                end
                FIN:begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // datas
    // pointmul
    reg[255:0]      r_mul_x1;
    reg[255:0]      r_mul_y1;
    reg[255:0]      r_mul_z1;
    reg[255:0]      r_mul_k;
    reg             r_mul_start;
    wire[255:0]     w_mul_x2;
    wire[255:0]     w_mul_y2;
    wire[255:0]     w_mul_z2;
    wire            w_mul_done;
    reg[255:0]      r_mul_x2;
    reg[255:0]      r_mul_y2;
    reg[255:0]      r_mul_z2;
    // coordinate
    reg[255:0]      r_ord_xin;
    reg[255:0]      r_ord_yin;
    reg[255:0]      r_ord_zin;
    reg             r_ord_start;
    wire[255:0]     w_ord_xout;
    wire[255:0]     w_ord_yout;
    wire            w_ord_done;
    reg[255:0]      r_ord_xout;
    reg[255:0]      r_ord_yout;
    // kdf
    reg[511:0]      r_kdf_zin;
    reg             r_kdf_start;
    reg[31:0]       r_kdf_klen;
    wire[1023:0]    w_kdf_kout;
    wire            w_kdf_kout_valid;
    reg[1023:0]     r_kdf_kout;
    // sm3
    reg[31:0]       r_sm3_l;
    reg             r_sm3_start;
    wire[255:0]     w_sm3_hashout;
    wire            w_sm3_valid;
    reg[255:0]      r_sm3_hashout;

    // middle data
    reg[255:0] c1_jacobi_x;
    reg[255:0] c1_jacobi_y;
    reg[255:0] c1_jacobi_z;
    reg[255:0] kpb_jacobi_x;
    reg[255:0] kpb_jacobi_y;
    reg[255:0] kpb_jacobi_z;

    // memory data flow
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
 			plaintext[0]<=0;plaintext[1]<=0;plaintext[2]<=0;plaintext[3]<=0;
			plaintext[4]<=0;plaintext[5]<=0;plaintext[6]<=0;plaintext[7]<=0;
			plaintext[8]<=0;plaintext[9]<=0;plaintext[10]<=0;plaintext[11]<=0;
			plaintext[12]<=0;plaintext[13]<=0;plaintext[14]<=0;plaintext[15]<=0;
			plaintext[16]<=0;plaintext[17]<=0;plaintext[18]<=0;plaintext[19]<=0;
			plaintext[20]<=0;plaintext[21]<=0;plaintext[22]<=0;plaintext[23]<=0;
			plaintext[24]<=0;plaintext[25]<=0;plaintext[26]<=0;plaintext[27]<=0;
			plaintext[28]<=0;plaintext[29]<=0;plaintext[30]<=0;plaintext[31]<=0;
			ciphertext[0]<=0;ciphertext[1]<=0;ciphertext[2]<=0;ciphertext[3]<=0;
			ciphertext[4]<=0;ciphertext[5]<=0;ciphertext[6]<=0;ciphertext[7]<=0;
			ciphertext[8]<=0;ciphertext[9]<=0;ciphertext[10]<=0;ciphertext[11]<=0;
			ciphertext[12]<=0;ciphertext[13]<=0;ciphertext[14]<=0;ciphertext[15]<=0;
			ciphertext[16]<=0;ciphertext[17]<=0;ciphertext[18]<=0;ciphertext[19]<=0;
			ciphertext[20]<=0;ciphertext[21]<=0;ciphertext[22]<=0;ciphertext[23]<=0;
			ciphertext[24]<=0;ciphertext[25]<=0;ciphertext[26]<=0;ciphertext[27]<=0;
			ciphertext[28]<=0;ciphertext[29]<=0;ciphertext[30]<=0;ciphertext[31]<=0;
            t_reg[0]<=0;t_reg[1]<=0;t_reg[2]<=0;t_reg[3]<=0;
			t_reg[4]<=0;t_reg[5]<=0;t_reg[6]<=0;t_reg[7]<=0;
			t_reg[8]<=0;t_reg[9]<=0;t_reg[10]<=0;t_reg[11]<=0;
			t_reg[12]<=0;t_reg[13]<=0;t_reg[14]<=0;t_reg[15]<=0;
			t_reg[16]<=0;t_reg[17]<=0;t_reg[18]<=0;t_reg[19]<=0;
			t_reg[20]<=0;t_reg[21]<=0;t_reg[22]<=0;t_reg[23]<=0;
			t_reg[24]<=0;t_reg[25]<=0;t_reg[26]<=0;t_reg[27]<=0;
			t_reg[28]<=0;t_reg[29]<=0;t_reg[30]<=0;t_reg[31]<=0;
            c1out[0]<=0;c1out[1]<=0;c1out[2]<=0;c1out[3]<=0;
            c1out[4]<=0;c1out[5]<=0;c1out[6]<=0;c1out[7]<=0;
            c1out[8]<=0;c1out[9]<=0;c1out[10]<=0;c1out[11]<=0;
            c1out[12]<=0;c1out[13]<=0;c1out[14]<=0;c1out[15]<=0;
            c3out[0]<=0;c3out[1]<=0;c3out[2]<=0;c3out[3]<=0;
            c3out[4]<=0;c3out[5]<=0;c3out[6]<=0;c3out[7]<=0;
            k_reg <= 0;
            db_reg <= 0;
            pbx_reg <= 0;
            pby_reg <= 0;
            c1_x <= 0;
            c1_y <= 0;
            kpb_x <= 0;
            kpb_y <= 0;
            c3 <= 0;
            t_counter <= 0;
            plaintext_length <= 0;
            plaintext_last_length <= 0;
            c1_jacobi_x <= 0;
            c1_jacobi_y <= 0;
            c1_jacobi_z <= 0;
            kpb_jacobi_x <= 0;
            kpb_jacobi_y <= 0;
            kpb_jacobi_z <= 0;
            r_dec1x <= 0;
            r_dec1y <= 0;
            r_dec3 <= 0;
            dbc1_x <= 0;
            dbc1_y <= 0;
        end
        else begin
            case(state)
                IDLE:begin
 			        plaintext[0]<=0;plaintext[1]<=0;plaintext[2]<=0;plaintext[3]<=0;
			        plaintext[4]<=0;plaintext[5]<=0;plaintext[6]<=0;plaintext[7]<=0;
			        plaintext[8]<=0;plaintext[9]<=0;plaintext[10]<=0;plaintext[11]<=0;
			        plaintext[12]<=0;plaintext[13]<=0;plaintext[14]<=0;plaintext[15]<=0;
			        plaintext[16]<=0;plaintext[17]<=0;plaintext[18]<=0;plaintext[19]<=0;
			        plaintext[20]<=0;plaintext[21]<=0;plaintext[22]<=0;plaintext[23]<=0;
			        plaintext[24]<=0;plaintext[25]<=0;plaintext[26]<=0;plaintext[27]<=0;
			        plaintext[28]<=0;plaintext[29]<=0;plaintext[30]<=0;plaintext[31]<=0;
                    ciphertext[0]<=0;ciphertext[1]<=0;ciphertext[2]<=0;ciphertext[3]<=0;
			        ciphertext[4]<=0;ciphertext[5]<=0;ciphertext[6]<=0;ciphertext[7]<=0;
			        ciphertext[8]<=0;ciphertext[9]<=0;ciphertext[10]<=0;ciphertext[11]<=0;
			        ciphertext[12]<=0;ciphertext[13]<=0;ciphertext[14]<=0;ciphertext[15]<=0;
			        ciphertext[16]<=0;ciphertext[17]<=0;ciphertext[18]<=0;ciphertext[19]<=0;
			        ciphertext[20]<=0;ciphertext[21]<=0;ciphertext[22]<=0;ciphertext[23]<=0;
			        ciphertext[24]<=0;ciphertext[25]<=0;ciphertext[26]<=0;ciphertext[27]<=0;
			        ciphertext[28]<=0;ciphertext[29]<=0;ciphertext[30]<=0;ciphertext[31]<=0;
                    t_reg[0]<=0;t_reg[1]<=0;t_reg[2]<=0;t_reg[3]<=0;
			        t_reg[4]<=0;t_reg[5]<=0;t_reg[6]<=0;t_reg[7]<=0;
			        t_reg[8]<=0;t_reg[9]<=0;t_reg[10]<=0;t_reg[11]<=0;
			        t_reg[12]<=0;t_reg[13]<=0;t_reg[14]<=0;t_reg[15]<=0;
			        t_reg[16]<=0;t_reg[17]<=0;t_reg[18]<=0;t_reg[19]<=0;
			        t_reg[20]<=0;t_reg[21]<=0;t_reg[22]<=0;t_reg[23]<=0;
			        t_reg[24]<=0;t_reg[25]<=0;t_reg[26]<=0;t_reg[27]<=0;
			        t_reg[28]<=0;t_reg[29]<=0;t_reg[30]<=0;t_reg[31]<=0;
                    c1out[0]<=0;c1out[1]<=0;c1out[2]<=0;c1out[3]<=0;
                    c1out[4]<=0;c1out[5]<=0;c1out[6]<=0;c1out[7]<=0;
                    c1out[8]<=0;c1out[9]<=0;c1out[10]<=0;c1out[11]<=0;
                    c1out[12]<=0;c1out[13]<=0;c1out[14]<=0;c1out[15]<=0;
                    c3out[0]<=0;c3out[1]<=0;c3out[2]<=0;c3out[3]<=0;
                    c3out[4]<=0;c3out[5]<=0;c3out[6]<=0;c3out[7]<=0;
                    k_reg <= 0;
                    db_reg <= 0;
                    pbx_reg <= 0;
                    pby_reg <= 0;
                    c1_x <= 0;
                    c1_y <= 0;
                    c3 <= 0;
                    kpb_x <= 0;
                    kpb_y <= 0;
                    t_counter <= 0;                    
                    plaintext_length <= 0;
                    plaintext_last_length <= 0;
                    c1_jacobi_x <= 0;
                    c1_jacobi_y <= 0;
                    c1_jacobi_z <= 0;
                    kpb_jacobi_x <= 0;
                    kpb_jacobi_y <= 0;
                    kpb_jacobi_z <= 0;
                    r_dec1x <= 0;
                    r_dec1y <= 0;
                    r_dec3 <= 0;
                    dbc1_x <= 0;
                    dbc1_y <= 0;
                end
                DIN:begin // data input into plaintext
                    plaintext[0]<=din[1247:1216];plaintext[1]<=din[1215:1184];
                    plaintext[2]<=din[1183:1152];plaintext[3]<=din[1151:1120];
                    plaintext[4]<=din[1119:1088];plaintext[5]<=din[1087:1056];
                    plaintext[6]<=din[1055:1024];plaintext[7]<=din[1023:992];
                    plaintext[8]<=din[991:960];plaintext[9]<=din[959:928];
                    plaintext[10]<=din[927:896];plaintext[11]<=din[895:864];
                    plaintext[12]<=din[863:832];plaintext[13]<=din[831:800];
                    plaintext[14]<=din[799:768];plaintext[15]<=din[767:736];
                    plaintext[16]<=din[735:704];plaintext[17]<=din[703:672];
                    plaintext[18]<=din[671:640];plaintext[19]<=din[639:608];
                    plaintext[20]<=din[607:576];plaintext[21]<=din[575:544];
                    plaintext[22]<=din[543:512];plaintext[23]<=din[511:480];
                    plaintext[24]<=din[479:448];plaintext[25]<=din[447:416];
                    plaintext[26]<=din[415:384];plaintext[27]<=din[383:352];
                    plaintext[28]<=din[351:320];plaintext[29]<=din[319:288];
                    plaintext[30]<=din[287:256];plaintext[31]<=din[255:224];
                    plaintext_length <= din[1279:1248];
                    plaintext_last_length <= { 27'b0 , din[1252:1248] };
                    k_reg <= din[2047:1792];
                    db_reg <= din[2047:1792];
                    pbx_reg <= din[1791:1536];
                    pby_reg <= din[1535:1280];
                    r_dec1x <= din[1791:1536];
                    r_dec1y <= din[1535:1280];
                    r_dec3 <= din[1279:1024];
                end
                UPD1:begin
                    c1_jacobi_x <= r_mul_x2;
                    c1_jacobi_y <= r_mul_y2;
                    c1_jacobi_z <= r_mul_z2;
                end
                UPD2:begin // c1=[k]G
                    c1_x <= r_ord_xout;
                    c1_y <= r_ord_yout;
                end
                UPD3:begin
                    kpb_jacobi_x <= r_mul_x2;
                    kpb_jacobi_y <= r_mul_y2;
                    kpb_jacobi_z <= r_mul_z2;
                end
                UPD4:begin // [k]PB
                    kpb_x <= r_ord_xout;
                    kpb_y <= r_ord_yout;
                end
                XOR:begin // c2=M^t
					ciphertext[0] <= plaintext[0] ^ t_reg[0];
					ciphertext[1] <= plaintext[1] ^ t_reg[1];
					ciphertext[2] <= plaintext[2] ^ t_reg[2];
					ciphertext[3] <= plaintext[3] ^ t_reg[3];
					ciphertext[4] <= plaintext[4] ^ t_reg[4];
					ciphertext[5] <= plaintext[5] ^ t_reg[5];
					ciphertext[6] <= plaintext[6] ^ t_reg[6];
					ciphertext[7] <= plaintext[7] ^ t_reg[7];
					ciphertext[8] <= plaintext[8] ^ t_reg[8];
					ciphertext[9] <= plaintext[9] ^ t_reg[9];
					ciphertext[10] <= plaintext[10] ^ t_reg[10];
					ciphertext[11] <= plaintext[11] ^ t_reg[11];
					ciphertext[12] <= plaintext[12] ^ t_reg[12];
					ciphertext[13] <= plaintext[13] ^ t_reg[13];
					ciphertext[14] <= plaintext[14] ^ t_reg[14];
					ciphertext[15] <= plaintext[15] ^ t_reg[15];
					ciphertext[16] <= plaintext[16] ^ t_reg[16];
					ciphertext[17] <= plaintext[17] ^ t_reg[17];
					ciphertext[18] <= plaintext[18] ^ t_reg[18];
					ciphertext[19] <= plaintext[19] ^ t_reg[19];
					ciphertext[20] <= plaintext[20] ^ t_reg[20];
					ciphertext[21] <= plaintext[21] ^ t_reg[21];
					ciphertext[22] <= plaintext[22] ^ t_reg[22];
					ciphertext[23] <= plaintext[23] ^ t_reg[23];
					ciphertext[24] <= plaintext[24] ^ t_reg[24];
					ciphertext[25] <= plaintext[25] ^ t_reg[25];
					ciphertext[26] <= plaintext[26] ^ t_reg[26];
					ciphertext[27] <= plaintext[27] ^ t_reg[27];
					ciphertext[28] <= plaintext[28] ^ t_reg[28];
					ciphertext[29] <= plaintext[29] ^ t_reg[29];
					ciphertext[30] <= plaintext[30] ^ t_reg[30];
					ciphertext[31] <= plaintext[31] ^ t_reg[31];
                end
                UPD7:begin // c3=SM3
                    c3 <= r_sm3_hashout;
                end
                PRE8:begin // save c1 and c3 to memory
                    c1out[15] <= c1_y[31:0];
                    c1out[14] <= c1_y[63:32];
                    c1out[13] <= c1_y[95:64];
                    c1out[12] <= c1_y[127:96];
                    c1out[11] <= c1_y[159:128];
                    c1out[10] <= c1_y[191:160];
                    c1out[9] <= c1_y[223:192];
                    c1out[8] <= c1_y[255:224];
                    c1out[7] <= c1_x[31:0];
                    c1out[6] <= c1_x[63:32];
                    c1out[5] <= c1_x[95:64];
                    c1out[4] <= c1_x[127:96];
                    c1out[3] <= c1_x[159:128];
                    c1out[2] <= c1_x[191:160];
                    c1out[1] <= c1_x[223:192];
                    c1out[0] <= c1_x[255:224];
                    c3out[7] <= c3[31:0];
                    c3out[6] <= c3[63:32];
                    c3out[5] <= c3[95:64];
                    c3out[4] <= c3[127:96];
                    c3out[3] <= c3[159:128];
                    c3out[2] <= c3[191:160];
                    c3out[1] <= c3[223:192];
                    c3out[0] <= c3[255:224];
                end
                DC2:begin
                    c1_x <= { plaintext[0], plaintext[1], plaintext[2], plaintext[3], plaintext[4], plaintext[5], plaintext[6], plaintext[7] };
                    c1_y <= { plaintext[8], plaintext[9], plaintext[10], plaintext[11], plaintext[12], plaintext[13], plaintext[14], plaintext[15] };
                end
                DXOR:begin // c2=M^t
					ciphertext[0] <= plaintext[0] ^ t_reg[0];
					ciphertext[1] <= plaintext[1] ^ t_reg[1];
					ciphertext[2] <= plaintext[2] ^ t_reg[2];
					ciphertext[3] <= plaintext[3] ^ t_reg[3];
					ciphertext[4] <= plaintext[4] ^ t_reg[4];
					ciphertext[5] <= plaintext[5] ^ t_reg[5];
					ciphertext[6] <= plaintext[6] ^ t_reg[6];
					ciphertext[7] <= plaintext[7] ^ t_reg[7];
					ciphertext[8] <= plaintext[8] ^ t_reg[8];
					ciphertext[9] <= plaintext[9] ^ t_reg[9];
					ciphertext[10] <= plaintext[10] ^ t_reg[10];
					ciphertext[11] <= plaintext[11] ^ t_reg[11];
					ciphertext[12] <= plaintext[12] ^ t_reg[12];
					ciphertext[13] <= plaintext[13] ^ t_reg[13];
					ciphertext[14] <= plaintext[14] ^ t_reg[14];
					ciphertext[15] <= plaintext[15] ^ t_reg[15];
					ciphertext[16] <= plaintext[16] ^ t_reg[16];
					ciphertext[17] <= plaintext[17] ^ t_reg[17];
					ciphertext[18] <= plaintext[18] ^ t_reg[18];
					ciphertext[19] <= plaintext[19] ^ t_reg[19];
					ciphertext[20] <= plaintext[20] ^ t_reg[20];
					ciphertext[21] <= plaintext[21] ^ t_reg[21];
					ciphertext[22] <= plaintext[22] ^ t_reg[22];
					ciphertext[23] <= plaintext[23] ^ t_reg[23];
					ciphertext[24] <= plaintext[24] ^ t_reg[24];
					ciphertext[25] <= plaintext[25] ^ t_reg[25];
					ciphertext[26] <= plaintext[26] ^ t_reg[26];
					ciphertext[27] <= plaintext[27] ^ t_reg[27];
					ciphertext[28] <= plaintext[28] ^ t_reg[28];
					ciphertext[29] <= plaintext[29] ^ t_reg[29];
					ciphertext[30] <= plaintext[30] ^ t_reg[30];
					ciphertext[31] <= plaintext[31] ^ t_reg[31];
                end
                UPD5:begin
                    t_reg[0] <= r_kdf_kout[1023:992];
                    t_reg[1] <= r_kdf_kout[991:960];
                    t_reg[2] <= r_kdf_kout[959:928];
                    t_reg[3] <= r_kdf_kout[927:896];
                    t_reg[4] <= r_kdf_kout[895:864];
                    t_reg[5] <= r_kdf_kout[863:832];
                    t_reg[6] <= r_kdf_kout[831:800];
                    t_reg[7] <= r_kdf_kout[799:768];
                    t_reg[8] <= r_kdf_kout[767:736];
                    t_reg[9] <= r_kdf_kout[735:704];
                    t_reg[10] <= r_kdf_kout[703:672];
                    t_reg[11] <= r_kdf_kout[671:640];
                    t_reg[12] <= r_kdf_kout[639:608];
                    t_reg[13] <= r_kdf_kout[607:576];
                    t_reg[14] <= r_kdf_kout[575:544];
                    t_reg[15] <= r_kdf_kout[543:512];
                    t_reg[16] <= r_kdf_kout[511:480];
                    t_reg[17] <= r_kdf_kout[479:448];
                    t_reg[18] <= r_kdf_kout[447:416];
                    t_reg[19] <= r_kdf_kout[415:384];
                    t_reg[20] <= r_kdf_kout[383:352];
                    t_reg[21] <= r_kdf_kout[351:320];
                    t_reg[22] <= r_kdf_kout[319:288];
                    t_reg[23] <= r_kdf_kout[287:256];
                    t_reg[24] <= r_kdf_kout[255:224];
                    t_reg[25] <= r_kdf_kout[223:192];
                    t_reg[26] <= r_kdf_kout[191:160];
                    t_reg[27] <= r_kdf_kout[159:128];
                    t_reg[28] <= r_kdf_kout[127:96];
                    t_reg[29] <= r_kdf_kout[95:64];
                    t_reg[30] <= r_kdf_kout[63:32];
                    t_reg[31] <= r_kdf_kout[31:0];
                end
                DUPD3:begin
                    t_reg[0] <= r_kdf_kout[1023:992];
                    t_reg[1] <= r_kdf_kout[991:960];
                    t_reg[2] <= r_kdf_kout[959:928];
                    t_reg[3] <= r_kdf_kout[927:896];
                    t_reg[4] <= r_kdf_kout[895:864];
                    t_reg[5] <= r_kdf_kout[863:832];
                    t_reg[6] <= r_kdf_kout[831:800];
                    t_reg[7] <= r_kdf_kout[799:768];
                    t_reg[8] <= r_kdf_kout[767:736];
                    t_reg[9] <= r_kdf_kout[735:704];
                    t_reg[10] <= r_kdf_kout[703:672];
                    t_reg[11] <= r_kdf_kout[671:640];
                    t_reg[12] <= r_kdf_kout[639:608];
                    t_reg[13] <= r_kdf_kout[607:576];
                    t_reg[14] <= r_kdf_kout[575:544];
                    t_reg[15] <= r_kdf_kout[543:512];
                    t_reg[16] <= r_kdf_kout[511:480];
                    t_reg[17] <= r_kdf_kout[479:448];
                    t_reg[18] <= r_kdf_kout[447:416];
                    t_reg[19] <= r_kdf_kout[415:384];
                    t_reg[20] <= r_kdf_kout[383:352];
                    t_reg[21] <= r_kdf_kout[351:320];
                    t_reg[22] <= r_kdf_kout[319:288];
                    t_reg[23] <= r_kdf_kout[287:256];
                    t_reg[24] <= r_kdf_kout[255:224];
                    t_reg[25] <= r_kdf_kout[223:192];
                    t_reg[26] <= r_kdf_kout[191:160];
                    t_reg[27] <= r_kdf_kout[159:128];
                    t_reg[28] <= r_kdf_kout[127:96];
                    t_reg[29] <= r_kdf_kout[95:64];
                    t_reg[30] <= r_kdf_kout[63:32];
                    t_reg[31] <= r_kdf_kout[31:0];
                end
                // decrypt
                DUPD1:begin
                    c1_jacobi_x <= r_mul_x2;
                    c1_jacobi_y <= r_mul_y2;
                    c1_jacobi_z <= r_mul_z2;
                end
                DUPD2:begin
                    dbc1_x <= r_ord_xout;
                    dbc1_y <= r_ord_yout;
                end
                DUPD5:begin
                    c3 <= r_sm3_hashout;
                end
                default:begin
                end
            endcase
        end
    end



    // 2560 bit length shift register
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            shifter_reg <= 0;
            srcounter <= 0;
            srlength <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    shifter_reg <= 0;
                    srcounter <= 0;
                    srlength <= 0;
                end
                PRE7S1:begin
                    shifter_reg[2559:256] <= 0;
                    shifter_reg[255:0] <= kpb_x;
                    //srcounter <= srcounter + 1;
                    srlength <= srlength + 256;
                end
                PRE7S2:begin
                    shifter_reg[2559:32] <= shifter_reg[2527:0];
                    shifter_reg[31:0] <= plaintext[srcounter];
                    srcounter <= srcounter + 1;
                    srlength <= srlength + 32;
                end
                PRE7S3:begin
                    shifter_reg[2559:32] <= shifter_reg[2527:0];
                    shifter_reg[31:0] <= plaintext[srcounter];
                    srlength <= srlength + 32;
                end
                PRE7S4:begin
                    shifter_reg <= shifter_reg >> srbacklength;
                    srlength <= srlength - srbacklength;
                end
                PRE7S5:begin
                    shifter_reg[2559:256] <= shifter_reg[2303:0];
                    shifter_reg[255:0] <= kpb_y;
                    srlength <= srlength + 256;
                end
                PRE7S6:begin
                    shifter_reg <= shifter_reg << srshiftlength;
                end
                DPRE5S1:begin
                    shifter_reg[2559:256] <= 0;
                    shifter_reg[255:0] <= dbc1_x;
                    srcounter <= srcounter + 1;
                    srlength <= srlength + 256;
                end
                DPRE5S2:begin
                    shifter_reg[2559:32] <= shifter_reg[2527:0];
                    shifter_reg[31:0] <= plaintext[srcounter];
                    srcounter <= srcounter + 1;
                    srlength <= srlength + 32;
                end
                DPRE5S3:begin
                    shifter_reg[2559:32] <= shifter_reg[2527:0];
                    shifter_reg[31:0] <= plaintext[srcounter];
                    srlength <= srlength + 32;
                end
                DPRE5S4:begin
                    shifter_reg <= shifter_reg >> srbacklength;
                    srlength <= srlength - srbacklength;
                end
                DPRE5S5:begin
                    shifter_reg[2559:256] <= shifter_reg[2303:0];
                    shifter_reg[255:0] <= dbc1_y;
                    srlength <= srlength + 256;
                end
                DPRE5S6:begin
                    shifter_reg <= shifter_reg << srshiftlength;
                end
                default:begin
                end
            endcase
        end
    end


    // reg data flow
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            is_dec_reg <= 0;
            r_mul_x1 <= 0;
            r_mul_y1 <= 0;
            r_mul_z1 <= 0;
            r_mul_start <= 0;
            r_mul_x2 <= 0;
            r_mul_y2 <= 0;
            r_mul_z2 <= 0;
            r_ord_xin <= 0;
            r_ord_yin <= 0;
            r_ord_zin <= 0;
            r_ord_start <= 0;
            r_ord_xout <= 0;
            r_ord_yout <= 0;
            r_kdf_zin <= 0;
            r_kdf_start <= 0;
            r_kdf_klen <= 0;
            r_kdf_kout <= 0;
            r_sm3_l <= 0;
            r_sm3_start <= 0;
            r_sm3_hashout <= 0;
            doutreg <= 0;
            doutvalidreg <= 0;
            dout_counter1 <= 0;
            dout_counter2 <= 0;
            dout_counter3 <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    is_dec_reg <= decrypt;
                    r_mul_x1 <= 0;
                    r_mul_y1 <= 0;
                    r_mul_z1 <= 0;
                    r_mul_start <= 0;
                    r_mul_x2 <= 0;
                    r_mul_y2 <= 0;
                    r_mul_z2 <= 0;
                    r_ord_xin <= 0;
                    r_ord_yin <= 0;
                    r_ord_zin <= 0;
                    r_ord_start <= 0;
                    r_ord_xout <= 0;
                    r_ord_yout <= 0;
                    r_kdf_zin <= 0;
                    r_kdf_start <= 0;
                    r_kdf_klen <= 0;
                    r_kdf_kout <= 0;
                    r_sm3_l <= 0;
                    r_sm3_start <= 0;
                    r_sm3_hashout <= 0;
                    doutreg <= 0;
                    doutvalidreg <= 0;
                    dout_counter1 <= 0;
                    dout_counter2 <= 0;
                    dout_counter3 <= 0;
                end
                DIN:begin
                    //is_dec_reg <= decrypt;
                end
                PRE1:begin // c1=[k]G
                    r_mul_x1 <= GX;
                    r_mul_y1 <= GY;
                    r_mul_z1 <= constant1;
                    r_mul_k <= k_reg;
                    r_mul_start <= 1;
                end
                MUL1:begin
                    r_mul_start <= 0;
                    r_mul_x2 <= w_mul_x2;
                    r_mul_y2 <= w_mul_y2;
                    r_mul_z2 <= w_mul_z2;
                end
                UPD1:begin
                end
                PRE2:begin // c1 jacobi to c1(x,y)
                    r_ord_xin <= c1_jacobi_x;
                    r_ord_yin <= c1_jacobi_y;
                    r_ord_zin <= c1_jacobi_z;
                    r_ord_start <= 1;
                end
                TRANS1:begin
                    r_ord_start <= 0;
                    r_ord_xout <= w_ord_xout;
                    r_ord_yout <= w_ord_yout;
                end
                UPD2:begin
                end
                PRE3:begin // kpb=[k]pb
                    r_mul_x1 <= pbx_reg;
                    r_mul_y1 <= pby_reg;
                    r_mul_z1 <= constant1;
                    r_mul_k <= k_reg;
                    r_mul_start <= 1;
                end
                MUL2:begin
                    r_mul_start <= 0;
                    r_mul_x2 <= w_mul_x2;
                    r_mul_y2 <= w_mul_y2;
                    r_mul_z2 <= w_mul_z2;
                end
                UPD3:begin
                end
                PRE4:begin // kpb jacobi to kpb(x,y)
                    r_ord_xin <= kpb_jacobi_x;
                    r_ord_yin <= kpb_jacobi_y;
                    r_ord_zin <= kpb_jacobi_z;
                    r_ord_start <= 1;
                end
                TRANS2:begin
                    r_ord_start <= 0;
                    r_ord_xout <= w_ord_xout;
                    r_ord_yout <= w_ord_yout;
                end
                UPD4:begin
                end
                PRE5:begin // KDF
                    r_kdf_zin <= { kpb_x, kpb_y };
                    r_kdf_start <= 1;
                    r_kdf_klen <= plaintext_length;
                end
                KDF:begin
                    r_kdf_zin <= 0;
                    r_kdf_start <= 0;
                    r_kdf_klen <= 0;
                    r_kdf_kout <= w_kdf_kout;
                end
                UPD5:begin
                end
                XOR:begin
                end
                UPD6:begin
                end
                SM3IN:begin
                    r_sm3_start <= 1;
                    r_sm3_l <= srlength;
                end
                SM3:begin
                    r_sm3_start <= 0;
                    r_sm3_hashout <= w_sm3_hashout;
                end
                UPD7:begin
                end
                PRE8:begin
                end
                DOUTP:begin
                    doutreg[2047:1792] <= c1_x;
                    doutreg[1791:1536] <= c1_y;
                    doutreg[1535:1504]<=ciphertext[0];doutreg[1503:1472]<=ciphertext[1];
                    doutreg[1471:1440]<=ciphertext[2];doutreg[1439:1408]<=ciphertext[3];
                    doutreg[1407:1376]<=ciphertext[4];doutreg[1375:1344]<=ciphertext[5];
                    doutreg[1343:1312]<=ciphertext[6];doutreg[1311:1280]<=ciphertext[7];
                    doutreg[1279:1248]<=ciphertext[8];doutreg[1247:1216]<=ciphertext[9];
                    doutreg[1215:1184]<=ciphertext[10];doutreg[1183:1152]<=ciphertext[11];
                    doutreg[1151:1120]<=ciphertext[12];doutreg[1119:1088]<=ciphertext[13];
                    doutreg[1087:1056]<=ciphertext[14];doutreg[1055:1024]<=ciphertext[15];
                    doutreg[1023:992]<=ciphertext[16];doutreg[991:960]<=ciphertext[17];
                    doutreg[959:928]<=ciphertext[18];doutreg[927:896]<=ciphertext[19];
                    doutreg[895:864]<=ciphertext[20];doutreg[863:832]<=ciphertext[21];
                    doutreg[831:800]<=ciphertext[22];doutreg[799:768]<=ciphertext[23];
                    doutreg[767:736]<=ciphertext[24];doutreg[735:704]<=ciphertext[25];
                    doutreg[703:672]<=ciphertext[26];doutreg[671:640]<=ciphertext[27];
                    doutreg[639:608]<=ciphertext[28];doutreg[607:576]<=ciphertext[29];
                    doutreg[575:544]<=ciphertext[30];doutreg[543:512]<=ciphertext[31];
                    doutreg[511:256] <= c3;
                    doutreg[255:0] <= 0;
                    doutvalidreg <= 1;
                end
                DOUT:begin
                    doutvalidreg <= 0;
                end
                // decrypt
                DC2:begin
                end
                DPRE1:begin // [db]c1 and save to dbc1
                    r_mul_x1 <= r_dec1x;
                    r_mul_y1 <= r_dec1y;
                    r_mul_z1 <= constant1;
                    r_mul_k <= db_reg;
                    r_mul_start <= 1;
                end
                DMUL1:begin
                    r_mul_start <= 0;
                    r_mul_x2 <= w_mul_x2;
                    r_mul_y2 <= w_mul_y2;
                    r_mul_z2 <= w_mul_z2;
                end
                DUPD1:begin
                end
                DPRE2:begin
                    r_ord_xin <= c1_jacobi_x;
                    r_ord_yin <= c1_jacobi_y;
                    r_ord_zin <= c1_jacobi_z;
                    r_ord_start <= 1;
                end
                DTRANS:begin
                    r_ord_start <= 0;
                    r_ord_xout <= w_ord_xout;
                    r_ord_yout <= w_ord_yout;
                end
                DUPD2:begin
                end
                DPRE3:begin
                    r_kdf_zin <= { dbc1_x, dbc1_y };
                    r_kdf_start <= 1;
                    r_kdf_klen <= plaintext_length;
                end
                DKDF:begin
                    r_kdf_zin <= 0;
                    r_kdf_start <= 0;
                    r_kdf_klen <= 0;
                    r_kdf_kout <= w_kdf_kout;
                end
                DUPD3:begin
                end
                DXOR:begin
                end
                DUPD4:begin
                end
                DSM3IN:begin
                    r_sm3_start <= 1;
                    r_sm3_l <= srlength;
                end
                DSM3:begin
                    r_sm3_start <= 0;
                    r_sm3_hashout <= w_sm3_hashout;
                end
                DUPD5:begin
                end
                DDOUTP:begin
                    doutreg[2047:2016]<=ciphertext[0];doutreg[2015:1984]<=ciphertext[1];
                    doutreg[1983:1952]<=ciphertext[2];doutreg[1951:1920]<=ciphertext[3];
                    doutreg[1919:1888]<=ciphertext[4];doutreg[1887:1856]<=ciphertext[5];
                    doutreg[1855:1824]<=ciphertext[6];doutreg[1823:1792]<=ciphertext[7];
                    doutreg[1791:1760]<=ciphertext[8];doutreg[1759:1728]<=ciphertext[9];
                    doutreg[1727:1696]<=ciphertext[10];doutreg[1695:1664]<=ciphertext[11];
                    doutreg[1663:1632]<=ciphertext[12];doutreg[1631:1600]<=ciphertext[13];
                    doutreg[1599:1568]<=ciphertext[14];doutreg[1567:1536]<=ciphertext[15];
                    doutreg[1535:1504]<=ciphertext[16];doutreg[1503:1472]<=ciphertext[17];
                    doutreg[1471:1440]<=ciphertext[18];doutreg[1439:1408]<=ciphertext[19];
                    doutreg[1407:1376]<=ciphertext[20];doutreg[1375:1344]<=ciphertext[21];
                    doutreg[1343:1312]<=ciphertext[22];doutreg[1311:1280]<=ciphertext[23];
                    doutreg[1279:1248]<=ciphertext[24];doutreg[1247:1216]<=ciphertext[25];
                    doutreg[1215:1184]<=ciphertext[26];doutreg[1183:1152]<=ciphertext[27];
                    doutreg[1151:1120]<=ciphertext[28];doutreg[1119:1088]<=ciphertext[29];
                    doutreg[1087:1056]<=ciphertext[30];doutreg[1055:1024]<=ciphertext[31];
                    doutvalidreg <= 1;
                end
                DDOUT:begin
                    doutvalidreg <= 0;
                end
                FIN:begin
                end
                default:begin
                end
            endcase
        end
    end


    // modules
    point_mul point_mul_sm2(
        .clk(clk),
        .rstn(rstn),
        .x1(r_mul_x1),
        .y1(r_mul_y1),
        .z1(r_mul_z1),
        .k(r_mul_k),
        .start(r_mul_start),
        .x2(w_mul_x2),
        .y2(w_mul_y2),
        .z2(w_mul_z2),
        .done(w_mul_done)
    );

    coordinate_jton coordinate_jton_sm2(
        .clk(clk),
        .rstn(rstn),
        .xin(r_ord_xin),
        .yin(r_ord_yin),
        .zin(r_ord_zin),
        .start(r_ord_start),
        .xout(w_ord_xout),
        .yout(w_ord_yout),
        .done(w_ord_done),
        .correct()
    );

    KDF KDF_sm2(
        .clk(clk),
        .rstn(rstn),
        .zin(r_kdf_zin),
        .start(r_kdf_start),
        .klen(r_kdf_klen),
        .kout(w_kdf_kout),
        .kout_valid(w_kdf_kout_valid)
    );

    sm3_top sm3_top_sm2(
        .clk(clk),
        .rstn(rstn),
        .datain1(shifter_reg[2559:2048]),
        .datain2(shifter_reg[2047:1536]),
        .datain3(shifter_reg[1535:1024]),
        .datain4(shifter_reg[1023:512]),
        .datain5(shifter_reg[511:0]),
        .l(r_sm3_l),
        .start(r_sm3_start),
        .hashout(w_sm3_hashout),
        .valid(w_sm3_valid)
    );

    assign current_finished = w_mul_done || w_kdf_kout_valid || w_ord_done || w_kdf_kout_valid || w_sm3_valid ;


endmodule
