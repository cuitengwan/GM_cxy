`timescale 1ns/1ps
module tb_sm31024();
    reg clk;
    reg rstn;
    reg[511:0] datain;
    reg start;
    reg[31:0] appendin;
    wire[255:0] hashout;
    wire valid;
    sm3_1024_top sm3_top_inst(clk,rstn,datain,appendin,start,hashout,valid);

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        datain <= 0;
        appendin <= 0;
        start <= 0;
        #40;
        rstn <= 1;
        #20;
        datain <= 512'h61626364616263646162636461626364616263646162636461626364616263646162636461626364616263646162636461626364616263646162636461626364;
        appendin <= 32'h61626364;
        start <= 1;
        #10;
        start <= 0;
        datain <= 0;
        appendin <= 0;
    end
    
endmodule

