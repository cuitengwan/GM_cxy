`timescale 1ns/1ps
module tb_axism();
    reg clk,rstn;
    reg[127:0] data;
    reg datavalid;
    reg M_AXIS_TREADY;
    wire M_AXIS_TVALID;
    wire[31:0] M_AXIS_TDATA;
    wire[3:0] M_AXIS_TSTRB;
    wire M_AXIS_TLAST;

    sm4_axis_m sm4axismtb(
        .M_AXIS_ACLK(clk),
        .M_AXIS_ARESETN(rstn),
        .data(data),
        .datavalid(datavalid),
        .M_AXIS_TREADY(M_AXIS_TREADY),
        .M_AXIS_TVALID(M_AXIS_TVALID),
        .M_AXIS_TDATA(M_AXIS_TDATA),
        .M_AXIS_TSTRB(M_AXIS_TSTRB),
        .M_AXIS_TLAST(M_AXIS_TLAST)
    );

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        M_AXIS_TREADY <= 0;
        data <= 0;
        datavalid <= 0;
        #50;
        rstn <= 1;
        M_AXIS_TREADY <= 1;
        #50;
        data <= 127'h00000001000000020000000300000004;
        datavalid <= 1;
        #10;
        data <= 127'h00000005000000060000000700000008;
        #10;
        data <= 127'h00000009000000100000001100000012;
        #10;
        data <= 127'h00000013000000140000001500000016;
        #10;
        data <= 127'h00000017000000180000001900000020;
        #10;
        data <= 127'h00000021000000220000002300000024;
        #10;
        data <= 127'h00000025000000260000002700000028;
        #10;
        data <= 127'h00000029000000300000003100000032;
        #10;
        data <= 0;
        datavalid <= 0;
    end
endmodule


