`timescale 1ns/1ps
module tb_pointmulnaf();
    reg clk,rstn;
    reg[255:0] x1,y1,z1;
    reg[1023:0] h;
    reg[31:0] hlength;
    reg start;
    wire[255:0] x2,y2,z2;
    wire done;

    pointmul_naf pointmulnafinst(clk,rstn,x1,y1,z1,h,hlength,start,x2,y2,z2,done);

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        x1 <= 0;
        y1 <= 0;
        z1 <= 0;
        h <= 0;
        hlength <= 0;
        start <= 0;
        #40;
        rstn <= 1;
        #30;
        //x1 <= 256'h155F86F5155F86F5155F86F5155F86F5155F86F5155F86F5155F86F5155F86F5;
        //y1 <= 256'hA1864DFFA1864DFFA1864DFFA1864DFFA1864DFFA1864DFFA1864DFFA1864DFF;
        //z1 <= 256'h6C32A5A26C32A5A26C32A5A26C32A5A26C32A5A26C32A5A26C32A5A26C32A5A2;
        x1 <= 256'h32C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7;
        y1 <= 256'hBC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0;
        z1 <= 256'h0000000000000000000000000000000000000000000000000000000000000001;
        h[7:0] <= 8'b01001100;
        hlength <= 4;
        start <= 1;
        #10;
        x1 <= 0;
        y1 <= 0;
        z1 <= 0;
        h <= 0;
        hlength <= 0;
        start <= 0;
    end
        

endmodule
