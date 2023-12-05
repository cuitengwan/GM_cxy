`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 13/2/2023 
// Design Name: 
// Module Name:    t1module1
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
//     (A<<<12)+E
//////////////////////////////////////////////////////////////////////////////////
module t1module1 (
    a,
    e,
    dout
);
    input wire[31:0] a;
    input wire[31:0] e;
    output wire[31:0] dout;
    wire[31:0] temp;
    shifter shifterint1module1(
        .din(a),
        .num(8'd12),
        .dout(temp)
    );
    assign dout = temp + e;
endmodule
