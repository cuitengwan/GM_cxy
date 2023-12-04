`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 08/11/2022 
// Design Name: 
// Module Name:    mod_inv_p
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
//     模p逆算法模块，输入256位A，输出A针对P的逆
//     参考：《基于软硬件协同的SM2椭圆曲线公钥密码算法加速》邓尧慷
//////////////////////////////////////////////////////////////////////////////////
module mod_inv_p (
    clk,
    rstn,
    in_a,
    start,
    out_c,
    done
);
    input wire clk;
    input wire rstn;
    input wire[255:0] in_a;
    input wire start;
    output wire[255:0] out_c;
    output wire done;

    localparam p = 256'hFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF;

    // regs
    reg[255:0] u;
    reg[255:0] v;
    reg[255:0] s1;
    reg[255:0] s2;

    // some calculate wire
    wire[256:0] s1_add_p;
    wire[256:0] s2_add_p;
    assign s1_add_p = s1 + p;
    assign s2_add_p = s2 + p;
    wire[256:0] s1_add_p_div_2;
    wire[256:0] s2_add_p_div_2;
    assign s1_add_p_div_2 = s1_add_p >> 1;
    assign s2_add_p_div_2 = s2_add_p >> 1;
    wire[255:0] p_minus_s1;
    wire[255:0] p_minus_s2;
    assign p_minus_s1 = p - s1;
    assign p_minus_s2 = p - s2;


    // state
    reg[15:0] state;
    localparam IDLE   = 16'b0000000000000001;
    localparam INIT   = 16'b0000000000000010;
    localparam CYCLE  = 16'b0000000000000100; // u>1
    localparam UEVEN  = 16'b0000000000001000; // u[0]==0
    localparam USHIFT = 16'b0000000000010000; // u>>1
    localparam S1CAL  = 16'b0000000000100000; // s1>>1 or (s1+p)>>1
    localparam VEVEN  = 16'b0000000001000000; // v[0]==0
    localparam VSHIFT = 16'b0000000010000000; // v>>1
    localparam S2CAL  = 16'b0000000100000000; // s2>>1 or (s2+p)>>1
    localparam MINUS  = 16'b0000001000000000; // change u,v,s1,s2
    localparam FIN    = 16'b0000010000000000;

    // state signal
    wire cycle_finished;
    wire u_even;
    wire v_even;
    // judge if uv > 1
    wire[254:0] u_high;
    wire[254:0] v_high;
    assign u_high = u[255:1];
    assign v_high = v[255:1];
    // signal change
    assign cycle_finished = ( u_high ) ? 0 : 1;
    assign u_even = u[0] ? 0 : 1;
    assign v_even = v[0] ? 0 : 1;

    // state change
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:begin
                    state <= start ? INIT : IDLE;
                end
                INIT:begin
                    state <= CYCLE;
                end
                CYCLE:begin
                    state <= cycle_finished ? FIN : UEVEN;
                end
                UEVEN:begin
                    state <= u_even ? USHIFT : VEVEN;
                end
                USHIFT:begin
                    state <= S1CAL;
                end
                S1CAL:begin
                    state <= UEVEN;
                end
                VEVEN:begin
                    state <= v_even ? VSHIFT : MINUS;
                end
                VSHIFT:begin
                    state <= S2CAL;
                end
                S2CAL:begin
                    state <= VEVEN;
                end
                MINUS:begin
                    state <= CYCLE;
                end
                FIN:begin
                    state <= IDLE;
                end
                default:begin
                end
            endcase
        end
    end

    // data change
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            u <= 0;
            v <= 0;
            s1 <= 0;
            s2 <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    u <= in_a;
                    v <= p;
                    s1 <= 1;
                    s2 <= 0;
                end
                INIT:begin
                    v <= p;
                    s1 <= 1;
                    s2 <= 0;
                end
                CYCLE:begin
                end
                UEVEN:begin
                end
                USHIFT:begin
                    u <= u >> 1;
                end
                S1CAL:begin
                    s1 <= ( s1[0] ) ? s1_add_p_div_2[255:0] : ( s1 >> 1 );
                end
                VEVEN:begin
                end
                VSHIFT:begin
                    v <= v >> 1;
                end
                S2CAL:begin
                    s2 <= ( s2[0] ) ? s2_add_p_div_2[255:0] : ( s2 >> 1 );
                end
                MINUS:begin
                    if( u == 1 ) begin
                        // do nothing
                    end
                    else if( u < v ) begin
                        v <= v - u;
                        s2 <= ( s2 > s1 ) ? ( s2 - s1 ) : ( p_minus_s1 + s2 );
                    end
                    else begin
                        u <= u - v;
                        s1 <= ( s1 > s2 ) ? ( s1 - s2 ) : ( p_minus_s2 + s1 );
                    end
                end
                FIN:begin
                end
                default:begin
                end
            endcase
        end
    end

    assign out_c = ( state == FIN ) ? s1 : 0;
    assign done = ( state == FIN ) ? 1 : 0;

endmodule
