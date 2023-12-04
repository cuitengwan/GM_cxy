`timescale 1ns/1ps
module tb_kdf();
    reg clk;
    reg rstn;
    reg[511:0] zin;
    reg start;
    reg[31:0] klen;
    wire[1023:0] kout;
    wire kout_valid;
    KDF KDFtestinst(clk,rstn,zin,start,klen,kout,kout_valid);

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        zin <= 0;
        start <= 0;
        klen <= 0;
        #40;
        rstn <= 1;
        #30;
        start <= 1;
        //zin <= 512'h10010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101;
        //klen <= 32'h00000205;
        zin <= 512'H64D20D27D0632957F8028C1E024F6B02EDF23102A566C932AE8BD613A8E865FE58D225ECA784AE300A81A2D48281A828E1CEDF11C4219099840265375077BF78;
        klen <= 1000;
        #10;
        start <= 0;
        zin <= 0;
        klen <= 0;
    end

    
endmodule