`timescale 1ns/1ps
module tb_dectop();
    reg clk;
    reg rstn;
    reg[127:0] data;
    reg[127:0] mk;
    reg startdec;
    wire[127:0] dataout;
    wire valid;

    dec_top dectopinst(
        .clk(clk),
        .rstn(rstn),
        .data(data),
        .mk(mk),
        .startdec(startdec),
        .dataout(dataout),
        .valid(valid)
    );

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        data <=0 ;
        mk <= 0;
        startdec <= 0;
        #40;
        rstn <= 1;
        #30;
        startdec <= 1;
        data <= 128'h681edf34d206965e86b3e94f536e4246;
        mk <= 128'h0123456789abcdeffedcba9876543210;
        #10;
        startdec <= 0;
        data <= 0;
        mk <= 0;
    end
endmodule
