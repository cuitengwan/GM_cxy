`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 13/2/2023 
// Design Name: 
// Module Name:    ffj
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
//     calculate ffj
//////////////////////////////////////////////////////////////////////////////////
module ffj (
    x,
    y,
    z,
    j,
    dout
);
    input wire[31:0] x;
    input wire[31:0] y;
    input wire[31:0] z;
    input wire[6:0] j;
    output wire[31:0] dout;

    wire[31:0] temp1;
    wire[31:0] temp2;
    assign temp1 = x ^ y ^ z;
    assign temp2 = ( x & y ) | ( x & z ) | ( y & z ) ;
    
    assign dout = ( j > 15 ) ? temp2 : temp1 ;
endmodule
