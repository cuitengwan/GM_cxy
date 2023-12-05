`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 13/2/2023 
// Design Name: 
// Module Name:    p1
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
//     calculate p1 in message expanding
//////////////////////////////////////////////////////////////////////////////////
module modulep1(
    x,
    dout
);
    input wire[31:0] x;
    output wire[31:0] dout;
    wire[31:0] temp1;
    wire[31:0] temp2;
    shifter shifter_p1inst1(
        .din(x),
        .num(8'd15),
        .dout(temp1)
    );
    shifter shifter_p1inst2(
        .din(x),
        .num(8'd23),
        .dout(temp2)
    );
    assign dout = x ^ temp1 ^ temp2 ;
endmodule