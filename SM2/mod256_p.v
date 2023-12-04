`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 03/11/2022 
// Design Name: 
// Module Name:    mod256_p
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
//     快速取模，用乘法结果，分块，模加。
//     参考：《Fp域SM2算法的实现与优化》 黄世中
//////////////////////////////////////////////////////////////////////////////////
module mod256_p (
    clk,
    rstn,
    a,
    start,
    c,
    done
);
    input wire clk;
    input wire rstn;
    input wire[511:0] a;
    input wire start;
    output wire[255:0] c;
    output wire done;

    localparam p = 256'hFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF;

    // s1 to s14 are 256 bit
    reg[255:0] s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14;
    // s1 to s10
    reg[255:0] t1,t2,t3,t4,t5,t6,t7,l1,l2,l3,l4,l5;
    reg[255:0] addall;

    // state machine
    // IDLE,PROC,FIN
    reg[1:0] state;
    localparam IDLE = 2'b00;
    //localparam DIN = 2'b00;
    localparam PROC = 2'b01;
    localparam FIN = 2'b11;
    reg[4:0] counter;
    wire finished;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE: state <= start ? PROC : IDLE;
                //DIN: state <= PROC;
                PROC: state <= finished ? FIN : PROC;
                FIN: state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            counter <= 0;
        end
        else begin
            if(state==IDLE) begin
                counter <= 0;
            end
            else if(state==PROC) begin
                counter <= counter + 1;
            end
            else begin
                counter <= counter;
            end
        end
    end
    assign finished = ( counter >= 5'b10100 ) ? 1 : 0; // need to debug

    // C
    wire[31:0] c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,zero;
    assign c0 = a[31:0];
    assign c1 = a[63:32];
    assign c2 = a[95:64];
    assign c3 = a[127:96];
    assign c4 = a[159:128];
    assign c5 = a[191:160];
    assign c6 = a[223:192];
    assign c7 = a[255:224];
    assign c8 = a[287:256];
    assign c9 = a[319:288];
    assign c10 = a[351:320];
    assign c11 = a[383:352];
    assign c12 = a[415:384];
    assign c13 = a[447:416];
    assign c14 = a[479:448];
    assign c15 = a[511:480];
    assign zero = 32'b0;

    // use in adder
    reg[255:0] adder_in_a;
    reg[255:0] adder_in_b;
    wire[255:0] adder_out_c;

    // s11 to s14
    reg[255:0] suball;
    reg[255:0] tmp1;
    reg[255:0] tmp2;
    reg final_sub_signal;

    // final
    reg[255:0] resultreg;

    // S
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            s1 <= 0;
            s2 <= 0;
            s3 <= 0;
            s4 <= 0;
            s5 <= 0;
            s6 <= 0;
            s7 <= 0;
            s8 <= 0;
            s9 <= 0;
            s10 <= 0;
            s11 <= 0;
            s12 <= 0;
            s13 <= 0;
            s14 <= 0;
            t1 <= 0; t2 <= 0; t3 <= 0; t4 <= 0; t5 <= 0; t6 <= 0; t7 <= 0;
            l1 <= 0; l2 <= 0; l3 <= 0; l4 <= 0; l5 <= 0; 
            addall <= 0; 
            suball <= 0;
            adder_in_a <= 0;
            adder_in_b <= 0;
            tmp1 <= 0;
            tmp2 <= 0;
            final_sub_signal <= 0;
            resultreg <= 0;
        end
        else begin
            if(state==IDLE) begin
                s1  <= {  c7,  c6,  c5,  c4,  c3,  c2,  c1,  c0};
                s2  <= {  c8, c11, c10,  c9,  c8,zero, c13, c12};
                s3  <= {  c9,zero,zero,zero, c15,zero,  c9,  c8};
                s4  <= { c10,zero,zero, c15, c14,zero, c10,  c9};
                s5  <= { c15, c14, c13, c12, c11,zero, c12, c11};
                s6  <= { c11, c15, c14, c13, c12,zero, c11, c10};
                s7  <= { c12,zero,zero,zero,zero,zero,zero,zero};
                s8  <= { c13,zero,zero,zero,zero,zero,zero, c13};
                s9  <= { c14,zero,zero,zero,zero,zero, c14, c14};
                s10 <= { c15,zero, c15, c14, c13,zero, c15, c15};
                s11 <= {zero,zero,zero,zero,zero,  c8,zero,zero};
                s12 <= {zero,zero,zero,zero,zero,  c9,zero,zero};
                s13 <= {zero,zero,zero,zero,zero, c13,zero,zero};
                s14 <= {zero,zero,zero,zero,zero, c14,zero,zero};
            end
            else if(state==PROC) begin
                case(counter)
                    5'b00001:begin // 专门一个周期判断所有s是不是在p范围内，s11-s14必定不用判
                        s1 <= (s1>p) ? (s1-p) : s1;
                        s2 <= (s2>p) ? (s2-p) : s2;
                        s3 <= (s3>p) ? (s3-p) : s3;
                        s4 <= (s4>p) ? (s4-p) : s4;
                        s5 <= (s5>p) ? (s5-p) : s5;
                        s6 <= (s6>p) ? (s6-p) : s6;
                        s7 <= (s7>p) ? (s7-p) : s7;
                        s8 <= (s8>p) ? (s8-p) : s8;
                        s9 <= (s9>p) ? (s9-p) : s9;
                        s10 <= (s10>p) ? (s10-p) : s10;
                        tmp1 <= s11 + s12;
                        tmp2 <= s13 + s14;
                    end
                    5'b00010:begin
                        adder_in_a <= s1;
                        adder_in_b <= s2;
                        suball <= tmp1 + tmp2;
                    end
                    5'b00011:begin
                        adder_in_a <= s3;
                        adder_in_b <= s4;
                        t1 <= adder_out_c;
                    end
                    5'b00100:begin
                        adder_in_a <= s5;
                        adder_in_b <= s6;
                        t2 <= adder_out_c;
                    end
                    5'b00101:begin
                        adder_in_a <= s7;
                        adder_in_b <= s7;
                        t3 <= adder_out_c;
                    end
                    5'b00110:begin
                        adder_in_a <= s8;
                        adder_in_b <= s8;
                        t4 <= adder_out_c;
                    end
                    5'b00111:begin
                        adder_in_a <= s9;
                        adder_in_b <= s9;
                        t5 <= adder_out_c;
                    end
                    5'b01000:begin
                        adder_in_a <= s10;
                        adder_in_b <= s10;
                        t6 <= adder_out_c;
                    end
                    5'b01001:begin
                        adder_in_a <= t1;
                        adder_in_b <= t2;
                        t7 <= adder_out_c;
                    end
                    5'b01010:begin
                        adder_in_a <= t3;
                        adder_in_b <= t4;
                        l1 <= adder_out_c;
                    end
                    5'b01011:begin
                        adder_in_a <= t5;
                        adder_in_b <= t6;
                        l2 <= adder_out_c;
                    end
                    5'b01100:begin
                        adder_in_a <= l1;
                        adder_in_b <= t7;
                        l3 <= adder_out_c;
                    end
                    5'b01101:begin
                        adder_in_a <= l2;
                        adder_in_b <= l3;
                        l4 <= adder_out_c;
                    end
                    5'b01110:begin
                        adder_in_a <= 0;
                        adder_in_b <= 0;
                        l5 <= adder_out_c;
                    end
                    5'b01111:begin
                        adder_in_a <= l4;
                        adder_in_b <= l5;
                    end
                    5'b10000:begin
                        addall <= adder_out_c;
                    end
                    5'b10001:begin
                        final_sub_signal <= ( addall > suball ) ? 0 : 1;
                    end
                    5'b10010:begin
                        // a>b : a-b  ;  a<b : b-a
                        addall <= final_sub_signal ? ( suball - addall ) : ( addall - suball );
                    end
                    5'b10011:begin
                        // a>b : do nothing  ;  a<b : p+a-b=p-(b-a)
                        addall <= final_sub_signal ? ( p - addall ) : addall ;
                    end
                    5'b10100:begin
                        resultreg <= addall;
                    end
                    default:begin                         
                    end 
                endcase
            end
        end
    end

    // use quick comb logic adder
    mod_add_p_comb_quick modaddinst_mod256p(
        .a(adder_in_a),
        .b(adder_in_b),
        .c(adder_out_c)
    );
    
    assign done = ( state == FIN ) ? 1 : 0;
    assign c = resultreg;


    
endmodule
