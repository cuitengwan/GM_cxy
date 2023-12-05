`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Choi sin yuu
// 
// Create Date:    12:00:00 13/2/2023 
// Design Name: 
// Module Name:    ss2
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
//     calculate ss2
//////////////////////////////////////////////////////////////////////////////////
module ss2 (
    a_shift_12,
    ss1,
    dout
);
    input wire[31:0] a_shift_12;
    input wire[31:0] ss1;
    output wire[31:0] dout;
    assign dout = a_shift_12 ^ ss1;
endmodule
