`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 14/2/2023 
// Design Name: 
// Module Name:    SM3_AXIS
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
//     top module of SM3 with AXI STREAM
//////////////////////////////////////////////////////////////////////////////////
module SM3_AXIS(
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

    wire[2047:0] wire_slave_to_sm3;
    wire datain;
    wire[1023:0] wire_sm3_to_master;
    wire calculate_valid;

    sm3_axis_s slave_in_sm3(
        .S_AXIS_ACLK(clk),
        .S_AXIS_ARESETN(rstn),
        .S_AXIS_TREADY(S_AXIS_TREADY),
        .S_AXIS_TDATA(S_AXIS_TDATA),
        .S_AXIS_TSTRB(S_AXIS_TSTRB),
        .S_AXIS_TLAST(S_AXIS_TLAST),
        .S_AXIS_TVALID(S_AXIS_TVALID),
        .wire_slave_to_sm3(wire_slave_to_sm3),
        .datain(datain)
    );

    sm3top sm3top_in_sm3(
        .clk(clk),
        .rstn(rstn),
        .din(wire_slave_to_sm3),
        .start(datain),
        .dout(wire_sm3_to_master),
        .valid(calculate_valid)
    );

    sm3_axis_m master_in_sm3(
        .wire_sm3_to_master(wire_sm3_to_master),
        .calculate_valid(calculate_valid),
        .M_AXIS_ACLK(clk),
        .M_AXIS_ARESETN(rstn),
        .M_AXIS_TVALID(M_AXIS_TVALID),
        .M_AXIS_TDATA(M_AXIS_TDATA),
        .M_AXIS_TSTRB(M_AXIS_TSTRB),
        .M_AXIS_TLAST(M_AXIS_TLAST),
        .M_AXIS_TREADY(M_AXIS_TREADY)
    );

endmodule