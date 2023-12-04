`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 17/11/2022 
// Design Name: 
// Module Name:    SM3 padding
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
//     Padding
//     input 512bit last group, 64bit length of the whole group
//     if input<448, small padding, output 512 bit(x)
//     else, large padding, output 1024 bit
//     the output is always 1024 bit, if is small padding, [511:0] is 0
//////////////////////////////////////////////////////////////////////////////////
module sm3_padding(
    clk,
    rstn,
    din,
    length,
    start,
    dout,
    valid,
    double
);
    input wire clk;
    input wire rstn;
    input wire[511:0] din;
    input wire[63:0] length;
    input wire start;
    output wire[1023:0] dout;
    output wire valid;
    output wire double;

    // regs
    reg[511:0] din_reg;
    reg[63:0] length_reg;
    reg is_large;
    reg[511:0] result_reg1;
    reg[511:0] result_reg2;
    reg[1023:0] output_reg;

    // length in 32bit
    wire[31:0] w_length;
    assign w_length = length_reg[31:0];
    // length of last group
    wire[31:0] w_length_last;
    assign w_length_last = { 23'b0, length_reg[8:0] };
    wire[31:0] setone_locate;
    assign setone_locate = 511 - w_length_last;


    // state machine
    reg[7:0] state;
    localparam IDLE = 8'b00000001;
    localparam DIN  = 8'b00000010;
    localparam SMALL = 8'b00000100;
    localparam LARGE = 8'b00001000;
    localparam DOUT = 8'b00010000;
    localparam FIN  = 8'b00100000;

    // state wire


    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE: begin
                    state <= start ? DIN : IDLE;
                end
                DIN:begin
                    state <= ( (w_length_last < 448)&&(w_length_last!=0) ) ? SMALL : LARGE;
                end
                SMALL:begin
                    state <= DOUT;
                end
                LARGE:begin
                    state <= DOUT;
                end
                DOUT:begin
                    state <= FIN;
                end
                FIN: begin
                    state <= IDLE;
                end
                default:begin
                end
            endcase
        end
    end

    // padding
    integer i;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            din_reg <= 0;
            length_reg <= 0;
            is_large <= 0;
            output_reg <= 0;
        end
        else begin
            case(state)
                IDLE:begin
                    din_reg <= din;
                    length_reg <= length;
                    is_large <= 0;
                end
                DIN:begin
                    is_large <= ( (w_length_last < 448)&&(w_length_last!=0) ) ? 0 : 1;
                    result_reg1 <= din_reg;
                end
                SMALL:begin //[511-i]=1,[511-i-1]=0
                    //result_reg1[(511-w_length_last)] <= 1;
                    result_reg1[setone_locate] <= 1;
                    //for(i=(510-w_length);i>63;i=i-1) begin
                    //    result_reg1[i] <= 0;
                    //end
                    //result_reg1[(510-w_length):64] <= 0;
                    result_reg1[63:0] <= length_reg;
                    //result_reg1 <= result_reg1 + ( 1 << ( 511-w_length ) ) + length_reg;
                    result_reg2 <= 0;
                end
                LARGE:begin //[511-i]=1,[511-i-1]=0
                    if(w_length_last==0) begin // exactly 512 bit, only change R2
                        // caution: when exactly 512 bit, the last_length is 0!
                        result_reg2[511] <= 1;
                        result_reg2[510:64] <= 0;
                        result_reg2[63:0] <= length_reg;
                    end
                    else if(w_length_last==511) begin // exactly 511 bit, R1[0]=1
                        result_reg1[0] <= 1;
                        result_reg2[511:64] <= 0;
                        result_reg2[63:0] <= length_reg;
                    end
                    else begin
                        //result_reg1[(511-w_length_last)] <= 1;
                        result_reg1[setone_locate] <= 1;
                        //for(i=(510-w_length);i>=0;i=i-1) begin
                        //    result_reg1[i] <= 0;
                        //end
                        //result_reg1[(510-w_length):0] <= 0;
                        result_reg2[511:64] <= 0;
                        result_reg2[63:0] <= length_reg;
                    end
                end
                DOUT:begin
                    output_reg <= { result_reg1, result_reg2 };
                end
                FIN:begin
                end
                default:begin
                end
            endcase
        end
    end

    assign dout = output_reg;
    assign valid = ( state==FIN ) ? 1 : 0;
    assign double = ( is_large ) ? 1 : 0;


endmodule
