`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 13/2/2023 
// Design Name: 
// Module Name:    shifter
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
//     rotate left
//////////////////////////////////////////////////////////////////////////////////
module shifter
(
    din,
    num,
    dout
);
    input wire[31:0] din;
    input wire[7:0] num;
    output wire[31:0] dout;
    wire[7:0] temp;
    assign temp = ( num > 32 ) ? ( num - 32 ) : num ;

    assign dout = ( din << temp | ( din >> ( 8'd32 - temp )));
endmodule