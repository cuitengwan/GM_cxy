`timescale 1ns/1ps
module tb_sm3anylength();
    reg clk,rstn;
    reg[511:0] datain1,datain2,datain3,datain4,datain5;
    reg[31:0] l;
    reg start;
    wire[255:0] hashout;
    wire valid;
    sm3_top sm3_top_test_inst(clk,rstn,datain1,datain2,datain3,datain4,datain5,l,start,hashout,valid);

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        datain1 <= 0;
        datain2 <= 0;
        datain3 <= 0;
        datain4 <= 0;
        datain5 <= 0;
        l <= 0;
        start <= 0;
        #40;
        rstn <= 1;
        #40;
        start <= 1;
        datain1 <= 512'h61626364616263646162636461626364616263646162636461626364616263646162636461626364616263646162636461626364616263646162636461626364;
        l <= 32'd512;
        #10;
        start <= 0;
        datain1 <= 0;
        l <= 0;
    end

endmodule