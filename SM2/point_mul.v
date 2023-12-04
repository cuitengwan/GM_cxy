`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 16/11/2022 
// Design Name: 
// Module Name:    point_mul
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
//     点乘模块，加重射影坐标
//     调用NAF运算模块和pointmul_naf模块
//////////////////////////////////////////////////////////////////////////////////
module point_mul (
    clk,
    rstn,
    x1,
    y1,
    z1,
    k,
    start,
    x2,
    y2,
    z2,
    done
);
    input wire clk;
    input wire rstn;
    input wire[255:0] x1;
    input wire[255:0] y1;
    input wire[255:0] z1;
    input wire[255:0] k;
    input wire start;
    output wire[255:0] x2;
    output wire[255:0] y2;
    output wire[255:0] z2;
    output wire done;

    // state
    // din, naf, 1cycle wait, mul, end
    reg[5:0] state;
    localparam IDLE = 6'b000001;
    localparam DIN  = 6'b000010;
    localparam NAF  = 6'b000100;
    localparam WAIT = 6'b001000;
    localparam MUL  = 6'b010000;
    localparam FIN  = 6'b100000;

    // state signal
    wire naf_finished;
    wire mul_finished;

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
                    state <= NAF;
                end
                NAF:begin
                    state <= naf_finished ? WAIT : NAF;
                end
                WAIT:begin
                    state <= MUL;
                end
                MUL:begin
                    state <= mul_finished ? FIN : MUL;
                end
                FIN:begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // data reg
    reg        mulstart_reg;
    reg        nafstart_reg;
    reg[255:0] k_reg;
    reg[511:0] h_reg;
    reg[31:0]  hlength_reg;
    reg[255:0] x1_reg;
    reg[255:0] y1_reg;
    reg[255:0] z1_reg;
    reg[255:0] x2_reg;
    reg[255:0] y2_reg;
    reg[255:0] z2_reg;

    wire[511:0] naf_result_h;
    wire[31:0] naf_result_hlength;
    wire[255:0] x2w;
    wire[255:0] y2w;
    wire[255:0] z2w;

    // data process
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            nafstart_reg <= 0;
            mulstart_reg <= 0;
            k_reg <= 0;
            h_reg <= 0;
            hlength_reg <= 0;
            x1_reg <= 0;
            y1_reg <= 0;
            z1_reg <= 0;
            x2_reg <= 0;
            y2_reg <= 0;
            z2_reg <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    nafstart_reg <= 0;
                    mulstart_reg <= 0;
                    k_reg <= k;
                    h_reg <= 0;
                    hlength_reg <= 0;
                    x1_reg <= x1;
                    y1_reg <= y1;
                    z1_reg <= z1;
                    x2_reg <= 0;
                    y2_reg <= 0;
                    z2_reg <= 0;
                end
                DIN:begin
                    nafstart_reg <= 1;
                    mulstart_reg <= 0;
                    //x1_reg <= 0;
                    //y1_reg <= 0;
                    //z1_reg <= 0;
                end
                NAF:begin
                    nafstart_reg <= 0;
                    mulstart_reg <= 0;
                    h_reg <= naf_result_h;
                    hlength_reg <= naf_result_hlength;
                end
                WAIT:begin
                    nafstart_reg <= 0;
                    mulstart_reg <= 1;
                    x1_reg <= x1_reg;
                    y1_reg <= y1_reg;
                    z1_reg <= z1_reg;
                    h_reg <= h_reg;
                    hlength_reg <= hlength_reg;
                end
                MUL:begin
                    nafstart_reg <= 0;
                    mulstart_reg <= 0;
                    x2_reg <= x2w;
                    y2_reg <= y2w;
                    z2_reg <= z2w;
                end
                FIN:begin
                    x2_reg <= x2_reg;
                    y2_reg <= y2_reg;
                    z2_reg <= z2_reg;
                end
                default:begin
                end
            endcase
        end
    end


    // module
    naf naf_in_pointmul(
        .clk(clk),
        .rstn(rstn),
        .k(k_reg),
        .start(nafstart_reg),
        .h(naf_result_h),
        .hlength(naf_result_hlength),
        .done(naf_finished)
    );

    pointmul_naf pointmulnaf_in_pointmul(
        .clk(clk),
        .rstn(rstn),
        .x1(x1_reg),
        .y1(y1_reg),
        .z1(z1_reg),
        .h(h_reg),
        .hlength(hlength_reg),
        .start(mulstart_reg),
        .x2(x2w),
        .y2(y2w),
        .z2(z2w),
        .done(mul_finished)
    );

    assign x2 = x2_reg;
    assign y2 = y2_reg;
    assign z2 = z2_reg;
    assign done = ( state == FIN ) ? 1 : 0;


endmodule