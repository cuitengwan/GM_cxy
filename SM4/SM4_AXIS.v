`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 15/2/2023 
// Design Name: 
// Module Name:    SM4 AXIS
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//     SM4 algorighm with axi4 stream port
//     AXI4 STREAM 인터페이스가 있는 SM4 알고리즘 엔지니어링
//////////////////////////////////////////////////////////////////////////////////
module SM4_AXIS(
    clk,
    rstn,
    S_AXIS_TREADY,
    S_AXIS_TDATA,
    S_AXIS_TSTRB,
    S_AXIS_TLAST,
    S_AXIS_TVALID,
    M_AXIS_TVALID,
    M_AXIS_TDATA,
    M_AXIS_TSTRB,
    M_AXIS_TLAST,
    M_AXIS_TREADY
);
    input wire clk;
    input wire rstn;
    output wire S_AXIS_TREADY;
    input wire[31:0] S_AXIS_TDATA;
    input wire[3:0] S_AXIS_TSTRB;
    input wire S_AXIS_TLAST;
    input wire S_AXIS_TVALID;
    output wire M_AXIS_TVALID;
    output wire[31:0] M_AXIS_TDATA;
    output wire[3:0] M_AXIS_TSTRB;
    output wire M_AXIS_TLAST;
    input wire M_AXIS_TREADY;

    parameter DATAWIDTH = 32;

    wire[127:0] datain;
    wire[127:0] mkin;
    wire start_input;
    wire end_input;
    wire isdec;
    wire[127:0] dataout;
    wire valid;

    sm4_axis_s slave_in_sm4(
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

    sm4top sm4top_in_sm4(
        .clk(clk),
        .rstn(rstn),
        .isdec(isdec),
        .start_input(start_input),
        .end_input(end_input),
        .datain(datain),
        .mkin(mkin),
        .dataout(dataout),
        .valid(valid)
    );

    sm4_axis_m master_in_sm4(
        .data(dataout),
        .datavalid(valid),
        .M_AXIS_ACLK(clk),
        .M_AXIS_ARESETN(rstn),
        .M_AXIS_TVALID(M_AXIS_TVALID),
        .M_AXIS_TDATA(M_AXIS_TDATA),
        .M_AXIS_TSTRB(M_AXIS_TSTRB),
        .M_AXIS_TLAST(M_AXIS_TLAST),
        .M_AXIS_TREADY(M_AXIS_TREADY)
    );

endmodule