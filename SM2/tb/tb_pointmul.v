`timescale 1ns/1ps
module tb_pointmul();
    reg clk,rstn;
    reg[255:0] x1,y1,z1;
    reg[255:0] k;
    reg start;
    wire[255:0] x2,y2,z2;
    wire done;

    point_mul pminst(
        .clk(clk),
        .rstn(rstn),
        .x1(x1),
        .y1(y1),
        .z1(z1),
        .k(k),
        .start(start),
        .x2(x2),
        .y2(y2),
        .z2(z2),
        .done(done)
    );

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        x1 <= 0;
        y1 <= 0;
        z1 <= 0;
        k <= 0;
        start <= 0;
        #40;
        rstn <= 1;
        #30;
        //x1 <= 256'h32C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7;
        //y1 <= 256'hBC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0;
        //z1 <= 256'h0000000000000000000000000000000000000000000000000000000000000001;
        x1 <= 256'h155F86F5155F86F5155F86F5155F86F5155F86F5155F86F5155F86F5155F86F5;
        y1 <= 256'hA1864DFFA1864DFFA1864DFFA1864DFFA1864DFFA1864DFFA1864DFFA1864DFF;
        z1 <= 256'h6C32A5A26C32A5A26C32A5A26C32A5A26C32A5A26C32A5A26C32A5A26C32A5A2;
        k <= 6;
        //k <= { $random, $random, $random, $random, $random, $random, $random, $random };
        start <= 1;
        #10;
        x1 <= 0;
        y1 <= 0;
        z1 <= 0;
        k <= 0;
        start <= 0;
    end

endmodule
