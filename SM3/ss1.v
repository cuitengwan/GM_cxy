`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 13/2/2023 
// Design Name: 
// Module Name:    ss1
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
//     calculate ss1
//////////////////////////////////////////////////////////////////////////////////
module ss1 (
    a_shift__e,
    tj_shift_j,
    dout
);
    input wire[31:0] a_shift__e;
    input wire[31:0] tj_shift_j;
    output wire[31:0] dout;
    wire[31:0] temp;
    assign temp = a_shift__e + tj_shift_j;
    assign dout = ( temp << 8'd7 | ( temp >> ( 8'd25 )));
endmodule
