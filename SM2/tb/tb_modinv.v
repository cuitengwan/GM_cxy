`timescale 1ns/1ps
module tb_modinv();
    reg clk,rstn;
    reg[255:0] in_a;
    reg datain;
    wire[255:0] out_c;
    wire done;
    mod_inv_p modinvpinst(clk,rstn,in_a,datain,out_c,done);
    parameter p = 256'hFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF;

    always @* begin
        #5 clk <= ~clk;
    end

    wire[255:0] testa;
    assign testa = { $random, $random, $random, $random, $random, $random, $random, $random };
    wire[511:0] temp;
    assign temp = testa * out_c;
    wire[511:0] testone;
    assign testone = temp % p;
    wire istrue;
    assign istrue = ( out_c == testone[255:0] ) ? 1 : 0;

    initial begin
        clk <= 0;
        rstn <= 0;
        in_a <= 0;
        datain <= 0;
        #40;
        rstn <= 1;
        #30;
        in_a <= testa;
        datain <= 1;
        #10;
        in_a <= 0;
        datain <= 0;
    end
endmodule
