`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 16/11/2022 
// Design Name: 
// Module Name:    KDF
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
//     KDF模块，输入串Z（512比特）和明文长度klen，输出串K(K的长度正好是klen)
//     算法：初始化32比特计数器ct=1，设j=klen/v上取整
//           对i从1到j，HAi=哈希Z拼ct，ct++。最后所有HAi拼接。
//           tip:如果klen/v不是整数，则最后一组保留前面若干位，使得拼起来后长度等于klen
//           因为资源有限本程序限制明文长度，memory现在定义成256*4，也就是klen最大256*4
//           实际运行与限制长度无关，直接修改参数即可。
//     包含：输入，哈希模块，输出。哈希模块是专用哈希。
//////////////////////////////////////////////////////////////////////////////////
module KDF(
    clk,
    rstn,
    zin,
    start,
    klen,
    kout,
    kout_valid
);
    input wire clk;
    input wire rstn;
    input wire[511:0] zin;
    input wire start;
    input wire[31:0] klen;
    //output wire[255:0] kout;
    output wire[1023:0] kout; // one time output 4 groups of data
    output wire kout_valid; // the valid status of every bit

    // max length
    parameter KDF_MAXLEN = 4; // 256*4

    // memory
    reg[511:0] z_reg;
    reg[31:0] klen_reg;
    reg[255:0] result_reg[0:KDF_MAXLEN-1];


    // state machine
    reg[7:0] state;
    localparam IDLE = 8'b00000001;
    localparam DIN  = 8'b00000010;
    localparam SM3P = 8'b00000100;
    localparam SM3E = 8'b00001000;
    localparam SM3F = 8'b00010000;
    localparam DOUTP= 8'b00100000;
    localparam DOUT = 8'b01000000;
    localparam FIN  = 8'b10000000;

    // state signal
    wire currentsm3_finished;
    wire proc_finished;
    //wire dout_finished;

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
                    state <= SM3P;
                end
                SM3P:begin
                    state <= SM3E;
                end
                SM3E:begin
                    state <= currentsm3_finished ? SM3F : SM3E;
                end
                SM3F:begin
                    state <= proc_finished ? DOUT : SM3P;
                end
                DOUT:begin
                    //state <= dout_finished ? FIN : DOUT;
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

    // data in module
    reg[511:0] sm3_datain;
    reg[31:0] sm3_appendin;
    reg sm3_start;
    wire[255:0] sm3_out;
    wire sm3_valid;

    // data moving
    reg[31:0] ct;
    reg[31:0] maxct;
    reg[31:0] dout_counter;
    reg[255:0] output_reg;

    // state signal change
    assign currentsm3_finished = sm3_valid;
    assign proc_finished = ( ct >= (maxct) ) ? 1 : 0;
    //assign dout_finished = ( dout_counter >= ( maxct - 1) ) ? 1 : 0;

    // data changing
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            sm3_datain <= 0;
            sm3_appendin <= 0;
            sm3_start <= 0;
            ct <= 1;
            z_reg <= 0;
            klen_reg <= 0;
            maxct <= 32'hFFFFFFFF;
            dout_counter <= 0;
            result_reg[0] <= 0;
            result_reg[1] <= 0;
            result_reg[2] <= 0;
            result_reg[3] <= 0;
            output_reg <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    sm3_datain <= 0;
                    sm3_appendin <= 0;
                    sm3_start <= 0;
                    ct <= 1;
                    z_reg <= zin;
                    klen_reg <= klen;
                    maxct <= 32'hFFFFFFFF;
                    dout_counter <= 0;
                    result_reg[0] <= 0;
                    result_reg[1] <= 0;
                    result_reg[2] <= 0;
                    result_reg[3] <= 0;
                    output_reg <= 0;
                end
                DIN:begin
                    maxct <= (klen_reg >> 8) + 1; // now the sm3 time is in maxct
                end
                SM3P:begin
                    sm3_datain <= z_reg;
                    sm3_appendin <= ct;
                    sm3_start <= 1;
                end
                SM3E:begin
                    sm3_start <= 0;
                    result_reg[(ct-1)] <= sm3_out;
                end
                SM3F:begin
                    ct <= ct + 1;
                end
                DOUT:begin
                    output_reg <= result_reg[dout_counter];
                    dout_counter <= dout_counter + 1;
                end
                FIN:begin
                end
                default:begin
                end
            endcase
        end
    end

    // module initialize
    sm3_1024_top sm31024top_in_KDF(
        .clk(clk),
        .rstn(rstn),
        .datain(sm3_datain),
        .appendin(sm3_appendin),
        .start(sm3_start),
        .hashout(sm3_out),
        .valid(sm3_valid)
    );

    //assign kout = output_reg;
    assign kout = { result_reg[0], result_reg[1] , result_reg[2], result_reg[3] };
    assign kout_valid = ( state == DOUT ) ? 1 : 0;
    


endmodule