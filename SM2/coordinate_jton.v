`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 14/11/2022 
// Design Name: 
// Module Name:    coordinate_jton
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
//     坐标转换，平面坐标变成jacobi加重射影坐标。
//     (x,y,z) -> (x/zz,y/zzz)
//     需要调用模乘和模逆
//////////////////////////////////////////////////////////////////////////////////
module coordinate_jton(
    clk,
    rstn,
    xin,
    yin,
    zin,
    start,
    xout,
    yout,
    done,
    correct
);
    input wire clk;
    input wire rstn;
    input wire[255:0] xin;
    input wire[255:0] yin;
    input wire[255:0] zin;
    input wire start;
    output wire[255:0] xout;
    output wire[255:0] yout;
    output wire done;
    output wire correct;

    // datain reg
    reg[255:0] r_xin;
    reg[255:0] r_yin;
    reg[255:0] r_zin;

    // module wire
    wire[255:0] mul_a;
    wire[255:0] mul_b;
    wire mul_start;
    wire[255:0] mul_c;
    wire mul_done;
    wire[255:0] inv_a;
    wire inv_start;
    wire[255:0] inv_c;
    wire inv_done;

    // regs to process data
    reg[255:0] r_mul_a;
    reg[255:0] r_mul_b;
    reg r_mul_start;
    reg[255:0] r_inv_a;
    reg r_inv_start;

    assign mul_a = r_mul_a;
    assign mul_b = r_mul_b;
    assign mul_start = r_mul_start;
    assign inv_a = r_inv_a;
    assign inv_start = r_inv_start;

    // result reg
    reg[255:0] mid_zz;
    reg[255:0] mid_zzz;
    reg[255:0] mid_inv_zz;
    reg[255:0] mid_inv_zzz;
    reg[255:0] x_reg;
    reg[255:0] y_reg;

    // state machine
    // states form a straight line
    // zz 1/zz zzz 1/zzz x/zz y/zzz
    reg[15:0] state;
    localparam IDLE  = 16'b0000000000000001;
    localparam MUL1P = 16'b0000000000000010;
    localparam MUL1  = 16'b0000000000000100;
    localparam INV1P = 16'b0000000000001000;
    localparam INV1  = 16'b0000000000010000;
    localparam MUL2P = 16'b0000000000100000;
    localparam MUL2  = 16'b0000000001000000;
    localparam INV2P = 16'b0000000010000000;
    localparam INV2  = 16'b0000000100000000;
    localparam MUL3P = 16'b0000001000000000;
    localparam MUL3  = 16'b0000010000000000;
    localparam MUL4P = 16'b0000100000000000;
    localparam MUL4  = 16'b0001000000000000;
    localparam FIN   = 16'b0010000000000000;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:begin
                    state <= start ? MUL1P : IDLE;
                end
                MUL1P:begin
                    state <= MUL1;
                end
                MUL1:begin
                    state <= mul_done ? INV1P : MUL1;
                end
                INV1P:begin
                    state <= INV1;
                end
                INV1:begin
                    state <= inv_done ? MUL2P : INV1;
                end
                MUL2P:begin
                    state <= MUL2;
                end
                MUL2:begin
                    state <= mul_done ? INV2P : MUL2;
                end
                INV2P:begin
                    state <= INV2;
                end
                INV2:begin
                    state <= inv_done ? MUL3P : INV2;
                end
                MUL3P:begin
                    state <= MUL3;
                end
                MUL3:begin
                    state <= mul_done ? MUL4P : MUL3;
                end
                MUL4P:begin
                    state <= MUL4;
                end
                MUL4:begin
                    state <= mul_done ? FIN : MUL4;
                end
                FIN:begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // data
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            r_mul_a <= 0;
            r_mul_b <= 0;
            r_mul_start <= 0;
            r_inv_a <= 0;
            r_inv_start <= 0;
            mid_zz <= 0;
            mid_zzz <= 0;
            mid_inv_zz <= 0;
            mid_inv_zzz <= 0;
            x_reg <= 0;
            y_reg <= 0;
            r_xin <= 0;
            r_yin <= 0;
            r_zin <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    r_mul_a <= 0;
                    r_mul_b <= 0;
                    r_mul_start <= 0;
                    r_inv_a <= 0;
                    r_inv_start <= 0;
                    r_xin <= xin;
                    r_yin <= yin;
                    r_zin <= zin;
                end
                MUL1P:begin
                    r_mul_a <= r_zin;
                    r_mul_b <= r_zin;
                    r_mul_start <= 1;
                end
                MUL1:begin
                    r_mul_start <= 0;
                    mid_zz <= mul_c;
                end
                INV1P:begin
                    r_inv_a <= mid_zz;
                    r_inv_start <= 1;
                end
                INV1:begin
                    r_inv_start <= 0;
                    mid_inv_zz <= inv_c;
                end
                MUL2P:begin
                    r_mul_a <= mid_zz;
                    r_mul_b <= r_zin;
                    r_mul_start <= 1;
                end
                MUL2:begin
                    r_mul_start <= 0;
                    mid_zzz <= mul_c;
                end
                INV2P:begin
                    r_inv_a <= mid_zzz;
                    r_inv_start <= 1;
                end
                INV2:begin
                    r_inv_start <= 0;
                    mid_inv_zzz <= inv_c;
                end
                MUL3P:begin
                    r_mul_a <= r_xin;
                    r_mul_b <= mid_inv_zz;
                    r_mul_start <= 1;
                end
                MUL3:begin
                    r_mul_start <= 0;
                    x_reg <= mul_c;
                end
                MUL4P:begin
                    r_mul_a <= r_yin;
                    r_mul_b <= mid_inv_zzz;
                    r_mul_start <= 1;
                end
                MUL4:begin
                    r_mul_start <= 0;
                    y_reg <= mul_c;
                end
                FIN:begin
                end
            endcase
        end
    end

    // module initialize
    mod_mul256_p modmul_in_coordinate(
        .clk(clk),
        .rstn(rstn),
        .a(mul_a),
        .b(mul_b),
        .start(mul_start),
        .c(mul_c),
        .done(mul_done)
    );

    mod_inv_p modinv_in_coordinate(
        .clk(clk),
        .rstn(rstn),
        .in_a(inv_a),
        .start(inv_start),
        .out_c(inv_c),
        .done(inv_done)
        //.correct(inv_correct)
    );

    assign xout = x_reg;
    assign yout = y_reg;
    assign done = ( state == FIN ) ? 1 : 0;
    assign correct = 1;
endmodule
