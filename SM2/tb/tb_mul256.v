`timescale 1ns/1ps
module tb_mul256();
    reg clk, rstn;
    reg start;
    reg[255:0] a;
    reg[255:0] b;
    wire done;
    wire[511:0] c;

    wire[255:0] aaa,bbb;
    wire[511:0] ccc;
    assign aaa = {$random,$random,$random,$random,$random,$random,$random,$random};
    assign bbb = {$random,$random,$random,$random,$random,$random,$random,$random};
    assign ccc = aaa * bbb;
    wire issame;
    assign issame = ( c == ccc ) ? 1 : 0;

    mul256 mul256inst(clk,rstn,a,b,start,c,done);

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        start <= 0; 
        a <= 0;
        b <= 0;
        #60;
        rstn <= 1;
        #50;
        //start <= 1;
        #10;
        a <= aaa;
        b <= bbb;
        //start <= 1;
        start <= 1;
        #10;
        a <= 0;
        b <= 0;
        start <= 0;
    end

endmodule