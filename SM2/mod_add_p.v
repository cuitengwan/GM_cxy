//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 01/11/2022 
// Design Name: 
// Module Name:    mul_mod_module 
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
//     模加模减共用模块，时序逻辑，3个时钟周期输出。
//     要求输入start只有一拍
//////////////////////////////////////////////////////////////////////////////////
module mod_add_p (
    clk,
    rstn,
    a,
    b,
    start,
    minus,
    c,
    done
);
    input wire clk;
    input wire rstn;
    input wire[255:0] a;
    input wire[255:0] b;
    input wire start;
    input wire minus;
    output wire[255:0] c;
    output wire done;
    
    localparam p = 256'hFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF;
    localparam p257 = 257'h0FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF;

    // regs
    reg[255:0] reg_a;
    reg[255:0] reg_b;
    reg is_minus;
    reg[256:0] mid1;
    reg[256:0] mid2;
    reg a_is_smaller;


    // state
    reg[7:0] state;
    localparam IDLE  = 8'b00000001;
    localparam JUDGE = 8'b00000010;
    localparam ADD1  = 8'b00000100;
    localparam ADD2  = 8'b00001000;
    localparam MIN1  = 8'b00010000;
    localparam MIN2  = 8'b00100000;
    localparam FIN   = 8'b01000000;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:begin
                    state <= start ? JUDGE : IDLE;
                end
                JUDGE:begin
                    state <= is_minus ? MIN1 : ADD1;
                end
                MIN1:begin
                    state <= MIN2;
                end
                MIN2:begin
                    state <= FIN;
                end
                ADD1:begin
                    state <= ADD2;
                end
                ADD2:begin
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

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            reg_a <= 0;
            reg_b <= 0;
            is_minus <= 0;
            mid1 <= 0;
            mid2 <= 0;
            a_is_smaller <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    reg_a <= a;
                    reg_b <= b;
                    is_minus <= minus;
                    mid1 <= 0;
                    mid2 <= 0;
                    a_is_smaller <= 0;
                end
                JUDGE:begin
                    reg_a <= ( reg_a > p ) ? ( reg_a - p ) : reg_a;
                    reg_b <= ( reg_b > p ) ? ( reg_b - p ) : reg_b;
                end
                MIN1:begin
                    if( reg_a > reg_b ) begin
                        mid1 <= reg_a - reg_b;
                    end
                    else begin
                        mid1 <= p - reg_b;
                        a_is_smaller <= 1;
                    end
                end
                MIN2:begin
                    mid2 <= mid1 + reg_a;
                end
                ADD1:begin
                    mid1 <= reg_a + reg_b;
                end
                ADD2:begin
                    mid1 <= ( mid1 >= p257 ) ? ( mid1 - p257 ) : mid1;
                end
                FIN:begin
                end
                default:begin
                end
            endcase
        end
    end

    assign done = ( state == FIN ) ? 1 : 0;
    assign c = ( a_is_smaller ) ? mid2[255:0] : mid1[255:0];
endmodule