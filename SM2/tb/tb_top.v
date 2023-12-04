`timescale 1ns/1ps
module tbtop();
    reg clk,rstn;
    reg[2047:0] din;
    reg decrypt,start;
    wire[2047:0] dout;
    wire valid;
    SM2 topinst(
        .clk(clk),
        .rstn(rstn),
        .din(din),
        .decrypt(decrypt),
        .start(start),
        .dout(dout),
        .valid(valid)
    );

    always @* begin
        #5 clk <= ~clk;
    end

    wire[255:0] k;
    wire[255:0] pbx;
    wire[255:0] pby;
    wire[31:0] l;
    wire[1023:0] d;
    wire[223:0] zero;
    assign k = 256'd6;
    assign pbx = 0;
    assign pby = 0;
    assign l = 32'd37;
    assign d = 1024'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000123456789A;
    assign zero = 0;

    initial begin
        clk <= 0;
        rstn <= 0;
        decrypt <= 0;
        start <= 0;
        din <= 0;
        #100;
        rstn <= 1;
        #60;
        start <= 1;
        din <= { k, pbx, pby, l, d, zero };
        #10;
        start <= 0;
    end
    
endmodule