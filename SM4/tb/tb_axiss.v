`timescale 1ns/1ps
module tb_axiss();
    reg clk,rstn;
    wire S_AXIS_TREADY;
    reg[31:0] S_AXIS_TDATA;
    reg[3:0] S_AXIS_TSTRB;
    reg S_AXIS_TLAST;
    reg S_AXIS_TVALID;
    wire isdec;
    wire start_input;
    wire end_input;
    wire[127:0] datain;
    wire[127:0] mkin;
    sm4_axis_s sm4axissinst(
        .S_AXIS_ACLK(clk),
        .S_AXIS_ARESETN(rstn),
        .S_AXIS_TREADY(S_AXIS_TREADY),
        .S_AXIS_TDATA(S_AXIS_TDATA),
        .S_AXIS_TSTRB(S_AXIS_TSTRB),
        .S_AXIS_TLAST(S_AXIS_TLAST),
        .S_AXIS_TVALID(S_AXIS_TVALID),
        .isdec(isdec),
        .start_input(start_input),
        .end_input(end_input),
        .datain(datain),
        .mkin(mkin)
    );

    always @* begin
        #5 clk <= ~clk;
    end

    initial begin
        clk <= 0;
        rstn <= 0;
        S_AXIS_TDATA <= 0;
        S_AXIS_TSTRB <= 0;
        S_AXIS_TLAST <= 0;
        S_AXIS_TVALID <= 0;
        #50;
        rstn <= 1;
        #50;
        S_AXIS_TDATA <= 32'h10101010;
        S_AXIS_TSTRB <= 4'b1111;
        S_AXIS_TVALID <= 1;
        #10;
        S_AXIS_TDATA <= 32'h01234567;
        #10;
        S_AXIS_TDATA <= 32'h89ABCDEF;
        #10;
        S_AXIS_TDATA <= 32'hFEDCBA98;
        #10;
        S_AXIS_TDATA <= 32'h76543210;
        #10;
        S_AXIS_TDATA <= 32'h01234567;
        #10;
        S_AXIS_TDATA <= 32'h89ABCDEF;
        #10;
        S_AXIS_TDATA <= 32'hFEDCBA98;
        #10;
        S_AXIS_TDATA <= 32'h76543210;
        #10;
        S_AXIS_TDATA <= 32'h12344321;
        #560;
        S_AXIS_TDATA <= 0;        
    end
endmodule

