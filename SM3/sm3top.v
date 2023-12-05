`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 13/2/2023 
// Design Name: 
// Module Name:    sm3top
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
//     top module of SM3 algorithm
//     input : 4 groups of 512 bit data
//     output: 4 groups of 256 result in reverse order
//     INPUT DATA SHOULD KEEP AFTER START!
//////////////////////////////////////////////////////////////////////////////////
module sm3top (
    clk,
    rstn,
    din,
    start,
    dout,
    valid
);
    input wire clk;
    input wire rstn;
    input wire[2047:0] din;
    input wire start;
    output wire[1023:0] dout;
    output wire valid;

    wire[255:0] dout1;
    wire[255:0] dout2;
    wire[255:0] dout3;
    wire[255:0] dout4;

    /* reg declaration */
    /* ABCDEFGH, 4x32 each */
    reg  [127:0]                  A             ;
    reg  [127:0]                  B             ;
    reg  [127:0]                  C             ;
    reg  [127:0]                  D             ;
    reg  [127:0]                  E             ;
    reg  [127:0]                  F             ;
    reg  [127:0]                  G             ;
    reg  [127:0]                  H             ;

    /* save the original ABCDEFGH data */
    /* save1 is for final XOR and save is for the next input data */
    reg  [127:0]                  save_A        ;
    reg  [127:0]                  save_B        ;
    reg  [127:0]                  save_C        ;
    reg  [127:0]                  save_D        ;
    reg  [127:0]                  save_E        ;
    reg  [127:0]                  save_F        ;
    reg  [127:0]                  save_G        ;
    reg  [127:0]                  save_H        ;
    reg  [127:0]                  save_A_1      ;
    reg  [127:0]                  save_B_1      ;
    reg  [127:0]                  save_C_1      ;
    reg  [127:0]                  save_D_1      ;
    reg  [127:0]                  save_E_1      ;
    reg  [127:0]                  save_F_1      ;
    reg  [127:0]                  save_G_1      ;
    reg  [127:0]                  save_H_1      ;

    /* registers in pipeline */
    /* name rule: double underline __ means "add" */
    // T1
    reg  [31:0]                   ff            ;
    reg  [31:0]                   a_shift__e    ;
    reg  [31:0]                   tj_shift_j    ;
    reg  [31:0]                   gg            ;
    reg  [31:0]                   h__wj         ;
    reg  [31:0]                   a_shift_12_t1 ; // save the A<<<12
    reg  [31:0]                   wj_temp1      ; // Wj-16 ^ Wj-9 ^ ( Wj-3 <<< 15 )
    reg  [31:0]                   wj_temp2      ; // ( Wj-13 <<< 7 ) ^ Wj-6
    // T2
    reg  [31:0]                   ss1           ;
    reg  [31:0]                   ff__d         ;
    reg  [31:0]                   gg__h__wj     ;
    reg  [31:0]                   a_shift_12_t2 ; // save the A<<<12
    reg  [31:0]                   wj_temp3      ; // P1()
    reg  [31:0]                   wj_temp2t2    ; // save the temp2
    // T3
    reg  [31:0]                   ff__d__wjc    ;
    reg  [31:0]                   ss2           ;
    reg  [31:0]                   tt2           ;
    reg  [31:0]                   wj_temp4      ; // wj final

    // wire of the registers
    // in fact, they are useless, but I don't want to rewrite
    wire [31:0]                   w_ff          ;
    wire [31:0]                   w_a_shift__e  ;
    wire [31:0]                   w_tj_shift_j  ;
    wire [31:0]                   w_gg          ;
    wire [31:0]                   w_h__wj       ;
    wire [31:0]                   w_ss1         ;
    wire [31:0]                   w_ff__d       ;
    wire [31:0]                   w_gg__h__wj   ;
    wire [31:0]                   w_ff__d__wjc  ;
    wire [31:0]                   w_ss2         ;
    wire [31:0]                   w_tt2         ;
    wire [31:0]                   w_a_shift_12_t1  ;
    wire [31:0]                   w_a_shift_12_t2  ;
    wire [31:0]                   w_wj_temp1    ;
    wire [31:0]                   w_wj_temp2    ;
    wire [31:0]                   w_wj_temp2t2  ;
    wire [31:0]                   w_wj_temp3    ;
    wire [31:0]                   w_wj_temp4    ;
    assign w_ff = ff;
    assign w_a_shift__e = a_shift__e;
    assign w_tj_shift_j = tj_shift_j;
    assign w_gg = gg;
    assign w_h__wj = h__wj;
    assign w_ss1 = ss1;
    assign w_ff__d = ff__d;
    assign w_gg__h__wj = gg__h__wj;
    assign w_ff__d__wjc = ff__d__wjc;
    assign w_ss2 = ss2;
    assign w_tt2 = tt2;
    assign w_a_shift_12_t1 = a_shift_12_t1;
    assign w_a_shift_12_t2 = a_shift_12_t2;
    assign w_wj_temp1 = wj_temp1;
    assign w_wj_temp2 = wj_temp2;
    assign w_wj_temp2t2 = wj_temp2t2;
    assign w_wj_temp3 = wj_temp3;
    assign w_wj_temp4 = wj_temp4;

    /* state machine */
    // coding is not 01234567 for safe
    // 0 -> 1 -> 3 -> 2 -> 6 -> 7 -> 5 -> 0
    parameter IDLE = 3'b000;
    parameter DATAIN = 3'b001; // useless state?
    parameter INIT0 = 3'b011;
    parameter INIT1 = 3'b010;
    parameter INIT2 = 3'b110; // three initial state, fill the 3 stages in pipeline
    parameter CYCLE = 3'b111; // cycling state
    parameter DATAOUTWAIT = 3'b101; // XOR and save data to memory
    parameter DATAOUT = 3'b100;
    reg[2:0] currentstate;
    wire finished;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            currentstate <= IDLE;
        end
        else begin
            case(currentstate)
                IDLE: begin
                    if(start) begin
                        currentstate <= DATAIN;
                    end
                    else begin
                        currentstate <= IDLE;
                    end
                end
                DATAIN: begin
                    currentstate <= INIT0;
                end
                INIT0: begin
                    currentstate <= INIT1;
                end
                INIT1: begin
                    currentstate <= INIT2;
                end
                INIT2: begin
                    currentstate <= CYCLE;
                end
                CYCLE: begin
                    if(finished) begin
                        currentstate <= DATAOUTWAIT;
                    end
                    else begin
                        currentstate <= CYCLE;
                    end
                end
                DATAOUTWAIT: begin
                    currentstate <= DATAOUT;
                end
                DATAOUT: begin
                    currentstate <= IDLE;
                end
            endcase
        end
    end

    assign valid = ( currentstate == DATAOUT ) ? 1 : 0;

    /* counter logic */
    /* counter is from 0 to 63. [1:0] controls "which data" is running currently */
    /* "which data" means the new result in pipeline stage 4 */
    /* For example, when counter[1:0]=2, currently a new result of group 2 is just calculated */
    /* real counter j is [8:2], counter[8] is for redundance */
    // j is 7 bit
    reg  [8:0]                    counter       ;
    wire [6:0]                    j             ;
    // for message expanding, which data is running currently
    // caution: k is one cycle "left moved" by j
    wire [6:0]                    k             ;
    wire [6:0]                    k_minus_1     ; // k-1
    // the new result belongs to which "group of data"
    // group number is 0, 1, 2, 3
    wire [1:0]                    group         ;
    assign group = counter[1:0] + 3; // counter=1->group0, counter=4->group3
    // j is (counter+3)>>2, temp1 is just a temp variable
    wire [8:0]                    temp1         ;
    assign temp1 = ( counter + 3 ) >> 2;
    assign j = temp1[6:0];
    // when compressing is in cycle j, message expanding is in cycle j+16
    // k is j+16, but k moved left for one cycle
    wire [8:0]                    temp2         ;
    assign temp2 = ( counter ) >> 2;
    assign k = temp2[6:0] + 16;
    assign k_minus_1 = k - 1;
    // counter starts in cycle state
    wire                          start_counter ;
    assign start_counter = ( currentstate == CYCLE ) ? 1 : 0 ;
    // counter==256, group3 's cycle 64 is finished
    assign finished = (counter == 256) ? 1 : 0;
    // just for group plus
    wire[1:0] group_plus1;
    wire[1:0] group_plus2;
    wire[1:0] group_plus3;
    assign group_plus1 = group + 1;
    assign group_plus2 = group + 2;
    assign group_plus3 = group + 3;

    // counter add logic
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            counter <= 0;
        end
        else begin
            if(start_counter) begin
                counter <= counter + 1;
                if(counter==256) begin
                    counter <= 0;
                end
                else begin
                end
            end
            else begin
                counter <= counter;
            end
        end
    end

    /* Wj memory */
    // a memory which saves all Wj data of four groups
    
    // j is 0 to 63, j+16 is 16 to 79
    // memory [68:79] is for redundance, not used
    reg[31:0] mem [0:3][0:79];
    /* current Wj and Wj' */
    wire[31:0] currentwj;
    wire[31:0] currentwjc;
    // when counter=C, group=C[1:0]-1=G, the new data of group G is calculated
    // next time, group G need its Wj to calculate T1
    assign currentwj = mem[group][j];
    // Wj' is used in T3, in this time group number is G+2
    wire[6:0] jp = ( counter + 1 ) >> 2;
    assign currentwjc = mem[group_plus2][jp] ^ mem[group_plus2][(jp+4)];

    /* Const */
    wire[31:0] TJ1;
    wire[31:0] TJ2;
    wire[31:0] tj;
    assign TJ1 = 32'h79cc4519;
    assign TJ2 = 32'h7a879d8a;
    assign tj = ( j > 15 ) ? TJ2 : TJ1 ;

    /* module wire */
    wire [31:0]                   wire_before_ff          ;
    wire [31:0]                   wire_before_a_shift     ;
    wire [31:0]                   wire_before_a_shift__e  ;
    wire [31:0]                   wire_before_tj_shift_j  ;
    wire [31:0]                   wire_before_gg          ;
    wire [31:0]                   wire_before_h__wj       ;
    wire [31:0]                   wire_before_ff__d       ;
    wire [31:0]                   wire_before_ss1         ;
    wire [31:0]                   wire_before_gg__h__wj   ;
    wire [31:0]                   wire_before_ff__d__wjc  ;
    wire [31:0]                   wire_before_ss2         ;
    wire [31:0]                   wire_before_tt2         ;
    wire [31:0]                   wire_b_shift_9          ;
    wire [31:0]                   wire_f_shift_19         ;
    wire [31:0]                   wire_before_a_final     ;
    wire [31:0]                   wire_before_e_final     ;
    wire [31:0]                   wire_wj_3_15            ;
    wire [31:0]                   wire_wj_13_7            ;
    wire [31:0]                   wire_p1                 ;

    /* module declaration*/
    // T1
    // ffj
    ffj ffjinst(
        .x(A[127:96]),
        .y(B[127:96]),
        .z(C[127:96]),
        .j(j),
        .dout(wire_before_ff)
    );

    // (A<<<12)+E
    t1module1 t1module1inst(
        .a(A[127:96]),
        .e(E[127:96]),
        .dout(wire_before_a_shift__e)
    );

    // (A<<<12)
    shifter shifter_a_shift_12(
        .din(A[127:96]),
        .num(8'd12),
        .dout(wire_before_a_shift)
    );

    // Tj<<<j
    shifter shifter_tjj(
        .din(tj),
        .num({1'b0,j}),
        .dout(wire_before_tj_shift_j)
    );

    // GG
    ggj ggjinst(
        .x(E[127:96]),
        .y(F[127:96]),
        .z(G[127:96]),
        .j(j),
        .dout(wire_before_gg)
    );

    // H+Wj
    adder adder_h__wj(
        .a(H[127:96]),
        .b(currentwj),
        .c(wire_before_h__wj)
    );

    // T2
    // FF+D
    adder adder_ff__d(
        .a(w_ff),
        .b(D[95:64]),
        .c(wire_before_ff__d)
    );

    // SS1 ((a<<<12)+e+(tj<<<j))<<<7
    ss1 ss1inst(
        .a_shift__e(w_a_shift__e),
        .tj_shift_j(w_tj_shift_j),
        .dout(wire_before_ss1)
    );

    // GG+H+Wj
    adder adder_gg__h__wj(
        .a(w_gg),
        .b(w_h__wj),
        .c(wire_before_gg__h__wj)
    );

    // T3
    // FF+D+Wj'
    adder adder_ff__d__wjc(
        .a(w_ff__d),
        .b(currentwjc),
        .c(wire_before_ff__d__wjc)
    );

    // SS2 ss1^(a<<<12)
    ss2 ss2inst(
        .a_shift_12(w_a_shift_12_t2),
        .ss1(w_ss1),
        .dout(wire_before_ss2)
    );

    //TT2 gg+h+wj+ss1
    adder adder_tt2(
        .a(w_gg__h__wj),
        .b(w_ss1),
        .c(wire_before_tt2)
    );

    // T4
    // TT1=FF+D+Wj'+SS2
    // save in A high
    adder adder_tt1(
        .a(w_ff__d__wjc),
        .b(w_ss2),
        .c(wire_before_a_final)
    );

    // P0(TT2)
    p0tt2 p0tt2inst(
        .din(w_tt2),
        .dout(wire_before_e_final)
    );

    // T1 calculated and saved in every T
    // B<<<9 and F<<<19
    shifter shifter_b_shift_9(
        .din(B[31:0]),
        .num(8'd9),
        .dout(wire_b_shift_9)
    );
    
    shifter shifter_f_shift_9(
        .din(F[31:0]),
        .num(8'd19),
        .dout(wire_f_shift_19)
    );

    // Wj logic for message expanding
    shifter shifter_wj3_15(
        .din(mem[group_plus3][(j+12)]),
        .num(8'd15),
        .dout(wire_wj_3_15)
    );

    shifter shifter_wj13_7(
        .din(mem[group_plus3][(j+2)]),
        .num(8'd7),
        .dout(wire_wj_13_7)
    );

    modulep1 modulep1inst(
        .x(w_wj_temp1),
        .dout(wire_p1)
    );


    reg[255:0] dfinal1;
    reg[255:0] dfinal2;
    reg[255:0] dfinal3;
    reg[255:0] dfinal4;

    /* reg logic */
    // ABCDEFGH
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            A <= 128'h7380166f7380166f7380166f7380166f;
            B <= 128'h4914b2b94914b2b94914b2b94914b2b9;
            C <= 128'h172442d7172442d7172442d7172442d7;
            D <= 128'hda8a0600da8a0600da8a0600da8a0600;
            E <= 128'ha96f30bca96f30bca96f30bca96f30bc;
            F <= 128'h163138aa163138aa163138aa163138aa;
            G <= 128'he38dee4de38dee4de38dee4de38dee4d;
            H <= 128'hb0fb0e4eb0fb0e4eb0fb0e4eb0fb0e4e;
            save_A <= 128'h7380166f7380166f7380166f7380166f;
            save_B <= 128'h4914b2b94914b2b94914b2b94914b2b9;
            save_C <= 128'h172442d7172442d7172442d7172442d7;
            save_D <= 128'hda8a0600da8a0600da8a0600da8a0600;
            save_E <= 128'ha96f30bca96f30bca96f30bca96f30bc;
            save_F <= 128'h163138aa163138aa163138aa163138aa;
            save_G <= 128'he38dee4de38dee4de38dee4de38dee4d;
            save_H <= 128'hb0fb0e4eb0fb0e4eb0fb0e4eb0fb0e4e;
            dfinal1 <= 0;
            dfinal2 <= 0;
            dfinal3 <= 0;
            dfinal4 <= 0;
        end
        else begin
            if(currentstate==IDLE) begin
                A <= save_A;
                B <= save_B;
                C <= save_C;
                D <= save_D;
                E <= save_E;
                F <= save_F;
                G <= save_G;
                H <= save_H;
                save_A_1 <= save_A;
                save_B_1 <= save_B;
                save_C_1 <= save_C;
                save_D_1 <= save_D;
                save_E_1 <= save_E;
                save_F_1 <= save_F;
                save_G_1 <= save_G;
                save_H_1 <= save_H;
                dfinal1 <= 0;
                dfinal2 <= 0;
                dfinal3 <= 0;
                dfinal4 <= 0;
            end
            else if(currentstate==CYCLE) begin
                A[127:96] <= wire_before_a_final;
                A[95:64]  <= A[127:96];
                A[63:32]  <= A[95:64];
                A[31:0]   <= A[63:32];

                B[127:96] <= A[31:0];
                B[95:64]  <= B[127:96];
                B[63:32]  <= B[95:64];
                B[31:0]   <= B[63:32];

                C[127:96] <= wire_b_shift_9;
                C[95:64]  <= C[127:96];
                C[63:32]  <= C[95:64];
                C[31:0]   <= C[63:32];

                D[127:96] <= C[31:0];
                D[95:64]  <= D[127:96];
                D[63:32]  <= D[95:64];
                D[31:0]   <= D[63:32];

                E[127:96] <= wire_before_e_final;
                E[95:64]  <= E[127:96];
                E[63:32]  <= E[95:64];
                E[31:0]   <= E[63:32];

                F[127:96] <= E[31:0];
                F[95:64]  <= F[127:96];
                F[63:32]  <= F[95:64];
                F[31:0]   <= F[63:32];

                G[127:96] <= wire_f_shift_19;
                G[95:64]  <= G[127:96];
                G[63:32]  <= G[95:64];
                G[31:0]   <= G[63:32];

                H[127:96] <= G[31:0];
                H[95:64]  <= H[127:96];
                H[63:32]  <= H[95:64];
                H[31:0]   <= H[63:32];
                if((j==7'h40)&&(group==3)) begin
                    /*
                    save_A <= A;
                    save_B <= B;
                    save_C <= C;
                    save_D <= D;
                    save_E <= E;
                    save_F <= F;
                    save_G <= G;
                    save_H <= H;
                    */
                    dfinal1 <= { A[127:96], B[127:96], C[127:96], D[127:96], E[127:96], F[127:96], G[127:96], H[127:96] };
                    dfinal2 <= { A[95:64], B[95:64], C[95:64], D[95:64], E[95:64], F[95:64], G[95:64], H[95:64] };
                    dfinal3 <= { A[63:32], B[63:32], C[63:32], D[63:32], E[63:32], F[63:32], G[63:32], H[63:32] };
                    dfinal4 <= { A[31:0], B[31:0], C[31:0], D[31:0], E[31:0], F[31:0], G[31:0], H[31:0] }; 
                end
            end
            else if(currentstate==DATAOUT) begin
                save_A <= { dout1[255:224], dout2[255:224], dout3[255:224], dout4[255:224] };
                save_B <= { dout1[223:192], dout2[223:192], dout3[223:192], dout4[223:192] };
                save_C <= { dout1[191:160], dout2[191:160], dout3[191:160], dout4[191:160] };
                save_D <= { dout1[159:128], dout2[159:128], dout3[159:128], dout4[159:128] };
                save_E <= { dout1[127:96], dout2[127:96], dout3[127:96], dout4[127:96] };
                save_F <= { dout1[95:64], dout2[95:64], dout3[95:64], dout4[95:64] };
                save_G <= { dout1[63:32], dout2[63:32], dout3[63:32], dout4[63:32] };
                save_H <= { dout1[31:0], dout2[31:0], dout3[31:0], dout4[31:0] };
                /*
                save_A <= A ^ save_A_1;
                save_B <= B ^ save_B_1;
                save_C <= C ^ save_C_1;
                save_D <= D ^ save_D_1;
                save_E <= E ^ save_E_1;
                save_F <= F ^ save_F_1;
                save_G <= G ^ save_G_1;
                save_H <= H ^ save_H_1;
                */
            end
            else begin
                
            end
        end
    end

    /* Wj initial logic */
    // W(j-3)<<<15 for group 0,1,2
    wire wire_w_013_shift15;
    wire wire_w_113_shift15;
    wire wire_w_213_shift15;
    assign wire_w_013_shift15 = { mem[0][13][16:0] , mem[0][13][31:17] };
    assign wire_w_113_shift15 = { mem[1][13][16:0] , mem[1][13][31:17] };
    assign wire_w_213_shift15 = { mem[2][13][16:0] , mem[2][13][31:17] };
    // W(j-13)<<<7
    wire wire_w_03_shift7;
    wire wire_w_13_shift7;
    wire wire_w_23_shift7;
    assign wire_w_03_shift7 = { mem[0][3][24:0] , mem[0][3][31:25] };
    assign wire_w_13_shift7 = { mem[1][3][24:0] , mem[1][3][31:25] };
    assign wire_w_23_shift7 = { mem[2][3][24:0] , mem[2][3][31:25] };
    wire[31:0] mem_0_0;
    wire[31:0] mem_1_0;
    assign mem_0_0 = mem[0][0];
    assign mem_1_0 = mem[1][0];
    //W0 <<<15 and <<<23 , ready for P1
    wire[31:0] mem_0_0_15;
    wire[31:0] mem_0_0_23;
    wire[31:0] mem_1_0_15;
    wire[31:0] mem_1_0_23;
    assign mem_0_0_15 = { mem_0_0[16:0] , mem_0_0[31:17] } ;
    assign mem_0_0_23 = { mem_0_0[8:0] , mem_0_0[31:9] } ;
    assign mem_1_0_15 = { mem_1_0[16:0] , mem_1_0[31:17] } ;
    assign mem_1_0_23 = { mem_1_0[8:0] , mem_1_0[31:9] } ;
    // calculate P1 in initial mode
    wire[31:0] p1init1;
    wire[31:0] p1init2;
    assign p1init1 = mem_0_0 ^ mem_0_0_15 ^ mem_0_0_23;
    assign p1init2 = mem_1_0 ^ mem_1_0_15 ^ mem_1_0_23;
    

    // temp wires for shift
    wire[31:0] A0_shift_12;
    wire[31:0] A1_shift_12;
    wire[31:0] A2_shift_12;
    wire[31:0] A3_shift_12;
    assign A0_shift_12 = { A[19:0], A[31:20] };
    assign A1_shift_12 = { A[51:32], A[63:52] };
    assign A2_shift_12 = { A[83:64], A[95:84] };
    assign A3_shift_12 = { A[115:96], A[127:116] };

    // pipeline register
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            ff <= 0;
            a_shift__e <= 0;
            tj_shift_j <= 0;
            gg <= 0;
            h__wj <= 0;
            a_shift_12_t1 <= 0;
            ss1 <= 0;
            ff__d <= 0;
            gg__h__wj <= 0;
            a_shift_12_t2 <= 0;
            ff__d__wjc <= 0;
            ss2 <= 0;
            tt2 <= 0;
        end
        else begin
            case(currentstate)
                IDLE:begin
                    ff <= 0;
                    a_shift__e <= 0;
                    tj_shift_j <= 0;
                    gg <= 0;
                    h__wj <= 0;
                    a_shift_12_t1 <= 0;
                    ss1 <= 0;
                    ff__d <= 0;
                    gg__h__wj <= 0;
                    a_shift_12_t2 <= 0;
                    ff__d__wjc <= 0;
                    ss2 <= 0;
                    tt2 <= 0;                    
                end
                DATAIN:begin
                    ff <= 0;
                    a_shift__e <= 0;
                    tj_shift_j <= 0;
                    gg <= 0;
                    h__wj <= 0;
                    a_shift_12_t1 <= 0;
                    ss1 <= 0;
                    ff__d <= 0;
                    gg__h__wj <= 0;
                    a_shift_12_t2 <= 0;
                    ff__d__wjc <= 0;
                    ss2 <= 0;
                    tt2 <= 0;                   
                end
                INIT0:begin
                    // INIT is fixed, only wj and wjc need to be changed
                    // T1 -> time0
                    // ff <= 32'h2db0e601; // A[127:96] ^ B[127:96] ^ C[127:96];
                    // a_shift__e <= 32'haad627f4; // (7380166f<<<12)+a96f30bc
                    // tj_shift_j <= 32'h79cc4519; // 79cc4519<<<0
                    // gg <= 32'h5cd3e65b; // E[127:96] ^ F[127:96] ^ G[127:96];
                    // h__wj <= H[127:96] + mem[0][0];
                    // a_shift_12_t1 <= 32'h0166f738; // 7380166f<<<12
                    ff <= A[31:0] ^ B[31:0] ^ C[31:0];
                    a_shift__e <= A0_shift_12 + E[31:0];
                    tj_shift_j <= 32'h79cc4519;
                    gg <= E[31:0] ^ F[31:0] ^ G[31:0];
                    h__wj <= H[31:0] + mem[0][0];
                    a_shift_12_t1 <= A0_shift_12 ;
                end
                INIT1:begin
                    // T1 -> time1
                    // ff <= 32'h2db0e601; // A[95:64] ^ B[95:64] ^ C[95:64];
                    // a_shift__e <= 32'haad627f4; // (7380166f<<<12)+a96f30bc
                    // tj_shift_j <= 32'h79cc4519;
                    // gg <= 32'h5cd3e65b; // E[95:64] ^ F[95:64] ^ G[95:64];
                    // h__wj <= H[127:96] + mem[1][0];
                    // a_shift_12_t1 <= 32'h0166f738;
                    ff <= A[63:32] ^ B[63:32] ^ C[63:32];
                    a_shift__e <= A1_shift_12 + E[63:32];
                    tj_shift_j <= 32'h79cc4519;
                    gg <= E[63:32] ^ F[63:32] ^ G[63:32];
                    h__wj <= H[63:32] + mem[1][0];
                    a_shift_12_t1 <= A1_shift_12 ;
                    // T2 -> time0
                    // ss1 <= 32'h51368692; // (aad627f4+(79cc4519<<<0))<<<7
                    // ff__d <= 32'h083aec01; // 2db06e01+da8a0600
                    // gg__h__wj <= 32'h0dcef4a9 + mem[0][0];
                    // a_shift_12_t2 <= 32'h0166f738; // copy T1
                    ss1 <= wire_before_ss1;
                    ff__d <= ff + D[31:0];
                    gg__h__wj <= gg + h__wj;
                    a_shift_12_t2 <= a_shift_12_t1;
                end
                INIT2:begin
                    // T1 -> time2
                    // ff <= 32'h2db0e601; // A[63:32] ^ B[63:32] ^ C[63:32];
                    // a_shift__e <= 32'haad627f4; // (7380166f<<<12)+a96f30bc
                    // tj_shift_j <= 32'h79cc4519;
                    // gg <= 32'h5cd3e65b; // E[63:32] ^ F[63:32] ^ G[63:32];
                    // h__wj <= H[127:96] + mem[2][0];
                    // a_shift_12_t1 <= 32'h0166f738;
                    ff <= A[95:64] ^ B[95:64] ^ C[95:64];
                    a_shift__e <= A2_shift_12 + E[95:64];
                    tj_shift_j <= 32'h79cc4519;
                    gg <= E[95:64] ^ F[95:64] ^ G[95:64];
                    h__wj <= H[95:64] + mem[2][0];
                    a_shift_12_t1 <= A2_shift_12 ;
                    // T2 -> time1
                    // ss1 <= 32'h51368692;
                    // ff__d <= 32'h083aec01; // 2db06e01+da8a0600
                    // gg__h__wj <= 32'h0dcef4a9 + mem[1][0];
                    // a_shift_12_t2 <= 32'h0166f738; // copy T1
                    ss1 <= wire_before_ss1;
                    ff__d <= ff + D[63:32];
                    gg__h__wj <= gg + h__wj;
                    a_shift_12_t2 <= a_shift_12_t1;
                    // T3 -> time0
                    // ff__d__wjc <= 32'h083aec01 + ( mem[0][0] ^ mem[0][4] );
                    // ss2 <= 32'h505071aa; // 51368692^0166f738
                    // tt2 <= 32'h5f057b3b + mem[0][0];
                    ff__d__wjc <= ff__d + ( mem[0][0] ^ mem[0][4] );
                    ss2 <= wire_before_ss2;
                    tt2 <= gg__h__wj + ss1;
                end
                CYCLE:begin
                    // use module result directly
                    ff <= wire_before_ff;
                    a_shift__e <= wire_before_a_shift__e;
                    tj_shift_j <= wire_before_tj_shift_j;
                    gg <= wire_before_gg;
                    h__wj <= wire_before_h__wj;
                    a_shift_12_t1 <= wire_before_a_shift;
                    ss1 <= wire_before_ss1;
                    ff__d <= wire_before_ff__d;
                    gg__h__wj <= wire_before_gg__h__wj;
                    a_shift_12_t2 <= w_a_shift_12_t1;
                    ff__d__wjc <= wire_before_ff__d__wjc;
                    ss2 <= wire_before_ss2;
                    tt2 <= wire_before_tt2;
                end
                DATAOUT:begin
                end
                default:begin
                end
            endcase
        end
    end

    /* Wj memory logic */
    // don't use "for", because "for" only used in blocked sentence
    always @(posedge clk) begin
        if(!rstn) begin
            mem[0][0] <= 0;mem[0][1] <= 0;mem[0][2] <= 0;mem[0][3] <= 0;mem[0][4] <= 0;
			mem[0][5] <= 0;mem[0][6] <= 0;mem[0][7] <= 0;mem[0][8] <= 0;mem[0][9] <= 0;
			mem[0][10] <= 0;mem[0][11] <= 0;mem[0][12] <= 0;mem[0][13] <= 0;mem[0][14] <= 0;
			mem[0][15] <= 0;mem[0][16] <= 0;mem[0][17] <= 0;mem[0][18] <= 0;mem[0][19] <= 0;
			mem[0][20] <= 0;mem[0][21] <= 0;mem[0][22] <= 0;mem[0][23] <= 0;mem[0][24] <= 0;
			mem[0][25] <= 0;mem[0][26] <= 0;mem[0][27] <= 0;mem[0][28] <= 0;mem[0][29] <= 0;
			mem[0][30] <= 0;mem[0][31] <= 0;mem[0][32] <= 0;mem[0][33] <= 0;mem[0][34] <= 0;
			mem[0][35] <= 0;mem[0][36] <= 0;mem[0][37] <= 0;mem[0][38] <= 0;mem[0][39] <= 0;
			mem[0][40] <= 0;mem[0][41] <= 0;mem[0][42] <= 0;mem[0][43] <= 0;mem[0][44] <= 0;
			mem[0][45] <= 0;mem[0][46] <= 0;mem[0][47] <= 0;mem[0][48] <= 0;mem[0][49] <= 0;
			mem[0][50] <= 0;mem[0][51] <= 0;mem[0][52] <= 0;mem[0][53] <= 0;mem[0][54] <= 0;
			mem[0][55] <= 0;mem[0][56] <= 0;mem[0][57] <= 0;mem[0][58] <= 0;mem[0][59] <= 0;
			mem[0][60] <= 0;mem[0][61] <= 0;mem[0][62] <= 0;mem[0][63] <= 0;mem[0][64] <= 0;
			mem[0][65] <= 0;mem[0][66] <= 0;mem[0][67] <= 0;mem[0][68] <= 0;mem[0][69] <= 0;
			mem[0][70] <= 0;mem[0][71] <= 0;mem[0][72] <= 0;mem[0][73] <= 0;mem[0][74] <= 0;
			mem[0][75] <= 0;mem[0][76] <= 0;mem[0][77] <= 0;mem[0][78] <= 0;
            mem[1][0] <= 0;mem[1][1] <= 0;mem[1][2] <= 0;mem[1][3] <= 0;mem[1][4] <= 0;
			mem[1][5] <= 0;mem[1][6] <= 0;mem[1][7] <= 0;mem[1][8] <= 0;mem[1][9] <= 0;
			mem[1][10] <= 0;mem[1][11] <= 0;mem[1][12] <= 0;mem[1][13] <= 0;mem[1][14] <= 0;
			mem[1][15] <= 0;mem[1][16] <= 0;mem[1][17] <= 0;mem[1][18] <= 0;mem[1][19] <= 0;
			mem[1][20] <= 0;mem[1][21] <= 0;mem[1][22] <= 0;mem[1][23] <= 0;mem[1][24] <= 0;
			mem[1][25] <= 0;mem[1][26] <= 0;mem[1][27] <= 0;mem[1][28] <= 0;mem[1][29] <= 0;
			mem[1][30] <= 0;mem[1][31] <= 0;mem[1][32] <= 0;mem[1][33] <= 0;mem[1][34] <= 0;
			mem[1][35] <= 0;mem[1][36] <= 0;mem[1][37] <= 0;mem[1][38] <= 0;mem[1][39] <= 0;
			mem[1][40] <= 0;mem[1][41] <= 0;mem[1][42] <= 0;mem[1][43] <= 0;mem[1][44] <= 0;
			mem[1][45] <= 0;mem[1][46] <= 0;mem[1][47] <= 0;mem[1][48] <= 0;mem[1][49] <= 0;
			mem[1][50] <= 0;mem[1][51] <= 0;mem[1][52] <= 0;mem[1][53] <= 0;mem[1][54] <= 0;
			mem[1][55] <= 0;mem[1][56] <= 0;mem[1][57] <= 0;mem[1][58] <= 0;mem[1][59] <= 0;
			mem[1][60] <= 0;mem[1][61] <= 0;mem[1][62] <= 0;mem[1][63] <= 0;mem[1][64] <= 0;
			mem[1][65] <= 0;mem[1][66] <= 0;mem[1][67] <= 0;mem[1][68] <= 0;mem[1][69] <= 0;
			mem[1][70] <= 0;mem[1][71] <= 0;mem[1][72] <= 0;mem[1][73] <= 0;mem[1][74] <= 0;
			mem[1][75] <= 0;mem[1][76] <= 0;mem[1][77] <= 0;mem[1][78] <= 0;
            mem[2][0] <= 0;mem[2][1] <= 0;mem[2][2] <= 0;mem[2][3] <= 0;mem[2][4] <= 0;
			mem[2][5] <= 0;mem[2][6] <= 0;mem[2][7] <= 0;mem[2][8] <= 0;mem[2][9] <= 0;
			mem[2][10] <= 0;mem[2][11] <= 0;mem[2][12] <= 0;mem[2][13] <= 0;mem[2][14] <= 0;
			mem[2][15] <= 0;mem[2][16] <= 0;mem[2][17] <= 0;mem[2][18] <= 0;mem[2][19] <= 0;
			mem[2][20] <= 0;mem[2][21] <= 0;mem[2][22] <= 0;mem[2][23] <= 0;mem[2][24] <= 0;
			mem[2][25] <= 0;mem[2][26] <= 0;mem[2][27] <= 0;mem[2][28] <= 0;mem[2][29] <= 0;
			mem[2][30] <= 0;mem[2][31] <= 0;mem[2][32] <= 0;mem[2][33] <= 0;mem[2][34] <= 0;
			mem[2][35] <= 0;mem[2][36] <= 0;mem[2][37] <= 0;mem[2][38] <= 0;mem[2][39] <= 0;
			mem[2][40] <= 0;mem[2][41] <= 0;mem[2][42] <= 0;mem[2][43] <= 0;mem[2][44] <= 0;
			mem[2][45] <= 0;mem[2][46] <= 0;mem[2][47] <= 0;mem[2][48] <= 0;mem[2][49] <= 0;
			mem[2][50] <= 0;mem[2][51] <= 0;mem[2][52] <= 0;mem[2][53] <= 0;mem[2][54] <= 0;
			mem[2][55] <= 0;mem[2][56] <= 0;mem[2][57] <= 0;mem[2][58] <= 0;mem[2][59] <= 0;
			mem[2][60] <= 0;mem[2][61] <= 0;mem[2][62] <= 0;mem[2][63] <= 0;mem[2][64] <= 0;
			mem[2][65] <= 0;mem[2][66] <= 0;mem[2][67] <= 0;mem[2][68] <= 0;mem[2][69] <= 0;
			mem[2][70] <= 0;mem[2][71] <= 0;mem[2][72] <= 0;mem[2][73] <= 0;mem[2][74] <= 0;
			mem[2][75] <= 0;mem[2][76] <= 0;mem[2][77] <= 0;mem[2][78] <= 0;
            mem[3][0] <= 0;mem[3][1] <= 0;mem[3][2] <= 0;mem[3][3] <= 0;mem[3][4] <= 0;
			mem[3][5] <= 0;mem[3][6] <= 0;mem[3][7] <= 0;mem[3][8] <= 0;mem[3][9] <= 0;
			mem[3][10] <= 0;mem[3][11] <= 0;mem[3][12] <= 0;mem[3][13] <= 0;mem[3][14] <= 0;
			mem[3][15] <= 0;mem[3][16] <= 0;mem[3][17] <= 0;mem[3][18] <= 0;mem[3][19] <= 0;
			mem[3][20] <= 0;mem[3][21] <= 0;mem[3][22] <= 0;mem[3][23] <= 0;mem[3][24] <= 0;
			mem[3][25] <= 0;mem[3][26] <= 0;mem[3][27] <= 0;mem[3][28] <= 0;mem[3][29] <= 0;
			mem[3][30] <= 0;mem[3][31] <= 0;mem[3][32] <= 0;mem[3][33] <= 0;mem[3][34] <= 0;
			mem[3][35] <= 0;mem[3][36] <= 0;mem[3][37] <= 0;mem[3][38] <= 0;mem[3][39] <= 0;
			mem[3][40] <= 0;mem[3][41] <= 0;mem[3][42] <= 0;mem[3][43] <= 0;mem[3][44] <= 0;
			mem[3][45] <= 0;mem[3][46] <= 0;mem[3][47] <= 0;mem[3][48] <= 0;mem[3][49] <= 0;
			mem[3][50] <= 0;mem[3][51] <= 0;mem[3][52] <= 0;mem[3][53] <= 0;mem[3][54] <= 0;
			mem[3][55] <= 0;mem[3][56] <= 0;mem[3][57] <= 0;mem[3][58] <= 0;mem[3][59] <= 0;
			mem[3][60] <= 0;mem[3][61] <= 0;mem[3][62] <= 0;mem[3][63] <= 0;mem[3][64] <= 0;
			mem[3][65] <= 0;mem[3][66] <= 0;mem[3][67] <= 0;mem[3][68] <= 0;mem[3][69] <= 0;
			mem[3][70] <= 0;mem[3][71] <= 0;mem[3][72] <= 0;mem[3][73] <= 0;mem[3][74] <= 0;
			mem[3][75] <= 0;mem[3][76] <= 0;mem[3][77] <= 0;mem[3][78] <= 0;
            wj_temp1 <= 0;
            wj_temp2 <= 0;
            wj_temp2t2 <= 0;
            wj_temp3 <= 0;
            wj_temp4 <= 0;
        end
        else if(currentstate==IDLE) begin
            wj_temp1 <= 0;
            wj_temp2 <= 0;
            wj_temp2t2 <= 0;
            wj_temp3 <= 0;
            wj_temp4 <= 0;
        end
        else if(currentstate==DATAIN) begin
            // datain, initial message
            mem[0][0] <= din[2047:2016];
            mem[0][1] <= din[2015:1984];
            mem[0][2] <= din[1983:1952];
            mem[0][3] <= din[1951:1920];
            mem[0][4] <= din[1919:1888];
            mem[0][5] <= din[1887:1856];
            mem[0][6] <= din[1855:1824];
            mem[0][7] <= din[1823:1792];
            mem[0][8] <= din[1791:1760];
            mem[0][9] <= din[1759:1728];
            mem[0][10] <= din[1727:1696];
            mem[0][11] <= din[1695:1664];
            mem[0][12] <= din[1663:1632];
            mem[0][13] <= din[1631:1600];
            mem[0][14] <= din[1599:1568];
            mem[0][15] <= din[1567:1536];
            mem[1][0] <= din[1535:1504];
            mem[1][1] <= din[1503:1472];
            mem[1][2] <= din[1471:1440];
            mem[1][3] <= din[1439:1408];
            mem[1][4] <= din[1407:1376];
            mem[1][5] <= din[1375:1344];
            mem[1][6] <= din[1343:1312];
            mem[1][7] <= din[1311:1280];
            mem[1][8] <= din[1279:1248];
            mem[1][9] <= din[1247:1216];
            mem[1][10] <= din[1215:1184];
            mem[1][11] <= din[1183:1152];
            mem[1][12] <= din[1151:1120];
            mem[1][13] <= din[1119:1088];
            mem[1][14] <= din[1087:1056];
            mem[1][15] <= din[1055:1024];
            mem[2][0] <= din[1023:992];
            mem[2][1] <= din[991:960];
            mem[2][2] <= din[959:928];
            mem[2][3] <= din[927:896];
            mem[2][4] <= din[895:864];
            mem[2][5] <= din[863:832];
            mem[2][6] <= din[831:800];
            mem[2][7] <= din[799:768];
            mem[2][8] <= din[767:736];
            mem[2][9] <= din[735:704];
            mem[2][10] <= din[703:672];
            mem[2][11] <= din[671:640];
            mem[2][12] <= din[639:608];
            mem[2][13] <= din[607:576];
            mem[2][14] <= din[575:544];
            mem[2][15] <= din[543:512];
            mem[3][0] <= din[511:480];
            mem[3][1] <= din[479:448];
            mem[3][2] <= din[447:416];
            mem[3][3] <= din[415:384];
            mem[3][4] <= din[383:352];
            mem[3][5] <= din[351:320];
            mem[3][6] <= din[319:288];
            mem[3][7] <= din[287:256];
            mem[3][8] <= din[255:224];
            mem[3][9] <= din[223:192];
            mem[3][10] <= din[191:160];
            mem[3][11] <= din[159:128];
            mem[3][12] <= din[127:96];
            mem[3][13] <= din[95:64];
            mem[3][14] <= din[63:32];
            mem[3][15] <= din[31:0];
            wj_temp1 <= 0;
            wj_temp2 <= 0;
            wj_temp2t2 <= 0;
            wj_temp3 <= 0;
            wj_temp4 <= 0;
        end
        else if(counter > 0) begin
            // k is j + 15. when in cycle j is already 1, so k is from 16 to 79
            wj_temp1 <= mem[group_plus3][(j-1)] ^ mem[group_plus3][(j+6)] ^ wire_wj_3_15 ;// g+3
            wj_temp2 <= wire_wj_13_7 ^ mem[group_plus3][(j+9)] ;// g+3
            // time2
            wj_temp2t2 <= wj_temp2;// g+2
            wj_temp3 <= wire_p1;// g+2
            // time1
            wj_temp4 <= wj_temp2t2 ^ wj_temp3;// g+1
            // time0
            if(counter>3) begin
                mem[group][k_minus_1] <= wj_temp4;
            end
        end
        else begin
        end
    end

    /* output logic */
    wire[255:0] dorigin1;
    wire[255:0] dorigin2;
    wire[255:0] dorigin3;
    wire[255:0] dorigin4;

    assign dorigin1 = { save_A_1[127:96], save_B_1[127:96], save_C_1[127:96], save_D_1[127:96], save_E_1[127:96], save_F_1[127:96], save_G_1[127:96], save_H_1[127:96] };
    assign dorigin2 = { save_A_1[95:64], save_B_1[95:64], save_C_1[95:64], save_D_1[95:64], save_E_1[95:64], save_F_1[95:64], save_G_1[95:64], save_H_1[95:64] };
    assign dorigin3 = { save_A_1[63:32], save_B_1[63:32], save_C_1[63:32], save_D_1[63:32], save_E_1[63:32], save_F_1[63:32], save_G_1[63:32], save_H_1[63:32] };
    assign dorigin4 = { save_A_1[31:0], save_B_1[31:0], save_C_1[31:0], save_D_1[31:0], save_E_1[31:0], save_F_1[31:0], save_G_1[31:0], save_H_1[31:0] };

    // finally, xor and output
    assign dout1 = dorigin1 ^ dfinal1;
    assign dout2 = dorigin2 ^ dfinal2;
    assign dout3 = dorigin3 ^ dfinal3;
    assign dout4 = dorigin4 ^ dfinal4;
    assign dout = { dout1, dout2, dout3, dout4 };

endmodule
